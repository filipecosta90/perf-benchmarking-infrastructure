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
    key    = "benchmarks/infrastructure/perf-cto-dl-servers-ubuntu18.04.tfstate"
    region = "us-east-1"
  }
}


resource "aws_network_interface" "perf_cto_server_network_interface" {
  count           = "${var.instance_network_interface_plus_count}"
  subnet_id       = data.terraform_remote_state.shared_resources.outputs.subnet_public_id
  security_groups = ["${data.terraform_remote_state.shared_resources.outputs.performance_cto_sg_id}"]

  attachment {
    instance     = "${aws_instance.perf_cto_server[0].id}"
    device_index = "${count.index + 2}"
  }
}

resource "aws_instance" "perf_cto_server" {
  count                  = "${var.server_instance_count}"
  ami                    = "${var.instance_ami}"
  instance_type          = "${var.instance_type}"
  subnet_id              = data.terraform_remote_state.shared_resources.outputs.subnet_public_id
  vpc_security_group_ids = ["${data.terraform_remote_state.shared_resources.outputs.performance_cto_sg_id}"]
  key_name               = "${var.key_name}"
  cpu_core_count         = "${var.instance_cpu_core_count}"

  cpu_threads_per_core = "${var.instance_cpu_threads_per_core_hyperthreading}"
  placement_group      = "${data.terraform_remote_state.shared_resources.outputs.perf_cto_pg_name}"

  ebs_block_device {
    device_name           = "${var.instance_device_name}"
    volume_size           = "${var.instance_volume_size}"
    volume_type           = "io1"
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

  #################
  # EC2 CONFIGURE #
  #################
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/ec2-configure.yml -i ${self.public_ip},"
  # }

  # ################################################################################
  # # performance related
  # ################################################################################
  ########
  # PERF #
  ########
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/perf.yml -i ${self.public_ip},"
  # }

  # #######
  # # BCC #
  # #######
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/bcc.yml -i ${self.public_ip},"
  # }


  # #######
  # # PCP #
  # #######
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/pcp.yml -i ${self.public_ip},"
  # }
  

  # ###########
  # # NETPERF #
  # ###########
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../../playbooks/${var.os}/netperf.yml -i ${self.public_ip},"
  # }


  # ####################################
  # # TUNED-ADM THROUGHPUT PERFORMANCE #
  # ####################################
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/tuned.yml -i ${self.public_ip},"
  # }


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
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../../playbooks/${var.os}/pcp-vector-pmda.yml -i ${self.public_ip},"
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
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/prometheus-process-exporter.yml -i ${self.public_ip},"
  }

  ################################################################################
  # Redis AI OSS related
  ################################################################################

  ###############
  # Install RedisAI OSS #
  ###############
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/redis-ai-oss.yml -i ${self.public_ip}, --extra-vars \"redis_ai_version=${var.redis_ai_oss_version}\""
  }

  ###############
  # Install Redis OSS #
  ###############
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/redis-server-oss-ai.yml -i ${self.public_ip}, --extra-vars \"redis_version=${var.redis_oss_version} redis_ai_module_path=~/redisai_src/build/redisai.so\""
  }

  ################################################################################
  # TensorFlow Serving related
  ################################################################################

  ##############################
  # Install TensorFlow Serving #
  ##############################
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/tfserving.yml -i ${self.public_ip},"
  }
}
