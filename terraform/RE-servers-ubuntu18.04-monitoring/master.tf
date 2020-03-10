

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.master_instance.id}"
  allocation_id = data.terraform_remote_state.shared_resources.outputs.perf_cto_monitoring_redistimeseries_cluster_id
}


resource "aws_instance" "master_instance" {
  ami                    = "${var.instance_ami}"
  instance_type          = "${var.instance_type}"
  subnet_id              = data.terraform_remote_state.shared_resources.outputs.subnet_public_id
  vpc_security_group_ids = ["${data.terraform_remote_state.shared_resources.outputs.performance_cto_sg_id}"]
  key_name               = "${var.key_name}"
  cpu_core_count         = "${var.instance_cpu_threads_per_core_hyperthreading}"

  cpu_threads_per_core = "${var.instance_cpu_threads_per_core_hyperthreading}"
  placement_group      = "${data.terraform_remote_state.shared_resources.outputs.perf_cto_pg_name}"
  availability_zone    = "${data.aws_availability_zones.available.names[0]}"
  private_ip = "10.3.0.199"


  root_block_device {
    volume_size           = "${var.root_volume_size}"
    volume_type           = "${var.root_volume_type}"
    iops                  = "${var.root_volume_iops}"
    encrypted             = "${var.root_volume_encrypted}"
    delete_on_termination = true
  }

  volume_tags = {
    Name        = "${var.setup_name}"
    RedisModule = "${var.redis_module}"
  }

  tags = {
    Name        = "${var.setup_name}"
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
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/common/1vm-redis-enterprise-monitoring.yml -i ${self.public_ip}.inv"
  }

  ###############################################
  # Remove any inventory file #
  ###############################################
  provisioner "local-exec" {
    command = "rm *.inv"
  }
}
