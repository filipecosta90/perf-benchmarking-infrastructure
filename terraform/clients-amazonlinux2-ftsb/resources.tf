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
    key    = "benchmarks/infrastructure/perf-cto-clients-amazonlinux2-ftsb.tfstate"
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

  root_block_device {
    volume_size           = "${var.instance_volume_size}"
    volume_type           = "${var.instance_volume_type}"
    iops                  = "${var.instance_volume_iops}"
    encrypted             = "${var.instance_volume_encrypted}"
    delete_on_termination = true
  }

  volume_tags = {
    Name        = "ebs_block_device-${var.setup_name}-${count.index + 1}"
    RedisModule = "${var.redis_module}"
  }

  tags = {
    Name        = "${var.setup_name}-${count.index + 1}"
    RedisModule = "${var.redis_module}"
  }

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
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/ec2-configure.yml -i ${self.public_ip},"
  }

  # #########################
  # # Install node exporter #
  # #########################
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/common/node-exporter.yml -i ${self.public_ip},"
  # }

  # ###################
  # # Install netdata #
  # ###################
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/common/netdata.yml -i ${self.public_ip},"
  # }

   ################################################################################
  # RediSearch Benchmark related
  ################################################################################

  # ##########################
  # # golang #
  # ##########################
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/common/golang.yml -i ${self.public_ip},"
  # }

  ##########################
  # Redisearch Client related #
  ##########################
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/common/ftsb.yml -i ${self.public_ip},"
  }

}
