
resource "aws_instance" "az2_memtier_instance" {
  ami                    = "${var.instance_ami}"
  instance_type          = "${var.instance_type}"
  subnet_id              = data.terraform_remote_state.shared_resources.outputs.subnet_us_east_2b_public_id
  vpc_security_group_ids = ["${data.terraform_remote_state.shared_resources.outputs.performance_cto_sg_id}"]
  key_name               = "${var.key_name}"
  cpu_core_count         = "${var.instance_cpu_core_count}"

  cpu_threads_per_core = "${var.instance_cpu_threads_per_core_hyperthreading}"
  placement_group      = "${data.terraform_remote_state.shared_resources.outputs.placement_group_name_us_east_2b}"
  availability_zone    = "${data.aws_availability_zones.available.names[1]}"

  root_block_device {
    volume_size           = "${var.root_volume_size}"
    volume_type           = "${var.root_volume_type}"
    iops                  = "${var.root_volume_iops}"
    encrypted             = "${var.root_volume_encrypted}"
    delete_on_termination = true
  }

  volume_tags = {
    Name        = "ebs_block_device-${var.setup_name}-${data.aws_availability_zones.available.names[1]}-memtier"
    RedisModule = "${var.redis_module}"
  }

  tags = {
    Name        = "${var.setup_name}-${data.aws_availability_zones.available.names[1]}-memtier"
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
      #need to increase timeout to larger then 5m for metal instances
      timeout = "15m"
    }
  }

  ############################
  # Install memtier_bnchmark #
  ############################
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/${var.os}/memtier.yml -i ${self.public_ip},"
  }
}
