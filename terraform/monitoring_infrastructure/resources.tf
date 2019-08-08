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
    key    = "benchmarks/infrastructure/monitoring-infrastructure.tfstate"
    region = "us-east-1"
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

  ebs_block_device {
    device_name = "${var.instance_device_name}"
    volume_size = 1024
    volume_type = "io1"
    iops        = 5000
    encrypted   = false
    #dont delete on termination the prometheus disk
    delete_on_termination = false
  }

  tags = {
    Name = "${var.setup_name}-${count.index + 1}"
  }

  # Ansible requires Python to be installed on the remote machine as well as the local machine.
  provisioner "remote-exec" {
    inline = ["sudo apt install python -y"]
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

  ##############
  # Prometheus #
  ##############
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/prometheus.yml -i ${self.public_ip},"
  }

}
