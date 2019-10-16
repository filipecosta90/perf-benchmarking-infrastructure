#providers
provider "aws" {
  region = "${var.region}"
}

data "terraform_remote_state" "shared_resources" {
  backend = "s3"
  config = {
    bucket = "performance-cto-group"
    key    = "benchmarks/infrastructure/shared_resources.tfstate"
    region = "us-east-1"
  }
}

terraform {
  backend "s3" {
    bucket = "performance-cto-group"
    key    = "benchmarks/infrastructure/perf-cto-RE-servers-amazonlinux2.tfstate"
    region = "us-east-1"
  }
}

resource "aws_network_interface" "perf_cto_server_c5n_9xlarge_network_interface" {
  count           = "${var.instance_network_interface_plus_count}"

  subnet_id              = data.terraform_remote_state.shared_resources.outputs.subnet_public_id
  security_groups = ["${data.terraform_remote_state.shared_resources.outputs.performance_cto_sg_id}"]

  attachment {
    instance     = "${aws_instance.perf_cto_server_c5n_9xlarge[0].id}"
    device_index = "${count.index + 2}"
  }

  tags = {
    Name = "eni-${var.setup_name}-${count.index + 2}"
    RedisModule = "${var.redis_module}"
  } 

}

resource "aws_instance" "perf_cto_server_c5n_9xlarge" {
  count                  = "${var.server_instance_count}"
  ami                    = "${var.instance_ami}"
  instance_type          = "${var.instance_type}"
  subnet_id              = data.terraform_remote_state.shared_resources.outputs.subnet_public_id
  vpc_security_group_ids = ["${data.terraform_remote_state.shared_resources.outputs.performance_cto_sg_id}"]
  key_name               = "${var.key_name}"
  cpu_core_count         = "${var.instance_cpu_core_count}"
  cpu_threads_per_core = "${var.instance_cpu_threads_per_core_hyperthreading}"
  placement_group      = "${data.terraform_remote_state.shared_resources.outputs.perf_cto_pg_name}"
  private_ip = "10.3.0.${count.index + 30}"

ebs_block_device {
    device_name           = "${var.instance_device_name}"
    volume_size           = "${var.instance_volume_size}"
    volume_type           = "${var.instance_volume_type}"
    iops                  = "${var.instance_volume_iops}"
    encrypted             = false
    delete_on_termination = true
  }

  volume_tags = {
    Name = "ebs_block_device-${var.setup_name}-${count.index + 1}"
    RedisModule = "${var.redis_module}"
  }

  tags = {
    Name = "${var.setup_name}-${count.index + 1}"
    RedisModule = "${var.redis_module}"
  }

  # wait for instance to be ready to receive connection
  provisioner "remote-exec" {
    script = "./../../scripts/wait_for_instance.sh"
      connection {
      host        = "${self.public_ip}" # The `self` variable is like `this` in many programming languages
      type        = "ssh"               # in this case, `self` is the resource (the server).
      user        = "${var.ssh_user}"
      private_key = "${file(var.private_key)}"
    }
  }

  ################################################################################
  # performance related
  ################################################################################
  ########
  # PERF #
  ########
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/perf.yml -i ${self.public_ip},"
  }

  #######
  # BCC #
  #######
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/bcc.yml -i ${self.public_ip},"
  }


  #######
  # PCP #
  #######
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/pcp.yml -i ${self.public_ip},"
  }

  #################
  # EC2 CONFIGURE #
  #################
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/ec2-configure.yml -i ${self.public_ip},"
  }

  ###########
  # NETPERF #
  ###########
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/netperf.yml -i ${self.public_ip},"
  }


  ####################################
  # TUNED-ADM THROUGHPUT PERFORMANCE #
  ####################################
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/tuned.yml -i ${self.public_ip},"
  }


  ###################
  # SYSCTL SETTINGS #
  ###################
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/sysctl.yml -i ${self.public_ip},"
  }


  ####################################
  # DISABLING TRANSPARENT HUGE PAGES #
  ####################################
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/thp.yml -i ${self.public_ip},"
  }

  # ###############################################
  # # PCP VECTOR PANDA - System Wide Flame Graphs #
  # ###############################################
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/pcp-vector-pmda.yml -i ${self.public_ip},"
  # }

  #########################
  # Install node exporter #
  #########################
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/node-exporter.yml -i ${self.public_ip},"
  }

  ############################
  # Install process exporter #
  ############################
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/prometheus-process-exporter.yml -i ${self.public_ip},"
  # }

  ################################################################################
  # Redis Enterprise related
  ################################################################################

  ###############################################
  # Create inventory file #
  ###############################################
  provisioner "local-exec" {

    command = "echo $l1 >> ${self.public_ip}.inv && echo $l2 >> ${self.public_ip}.inv"

    environment = {
      l1 = "[re_master]"
      l2 = "${self.public_ip}"
    }
  }

  ##############
  # Install RE #
  ##############
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/1VM-redis-enterprise.yml -i ${self.public_ip}.inv"
  }

  ###############################################
  # Remove inventory file #
  ###############################################
  provisioner "local-exec" {

    command = "rm ${self.public_ip}.inv"
  }
}
