
resource "aws_instance" "az1_master_instance" {
  ami                    = "${var.instance_ami}"
  instance_type          = "${var.instance_type}"
  subnet_id              = data.terraform_remote_state.shared_resources.outputs.subnet_public_id
  vpc_security_group_ids = ["${data.terraform_remote_state.shared_resources.outputs.performance_cto_sg_id}"]
  key_name               = "${var.key_name}"
  cpu_core_count         = "${var.instance_cpu_core_count}"

  cpu_threads_per_core = "${var.instance_cpu_threads_per_core_hyperthreading}"
  placement_group      = "${data.terraform_remote_state.shared_resources.outputs.perf_cto_pg_name}"
  availability_zone    = "${data.aws_availability_zones.available.names[0]}"

  root_block_device {
    volume_size           = "${var.root_volume_size}"
    volume_type           = "${var.root_volume_type}"
    iops                  = "${var.root_volume_iops}"
    encrypted             = "${var.root_volume_encrypted}"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_size           = "${var.ebs_volume_size}"
    volume_type           = "${var.ebs_volume_type}"
    delete_on_termination = true
    encrypted             = "${var.ebs_volume_encrypted}"
  }

  volume_tags = {
    Name        = "ebs_block_device-${var.setup_name}-${data.aws_availability_zones.available.names[0]}-master"
    RedisModule = "${var.redis_module}"
  }

  tags = {
    Name        = "${var.setup_name}-${data.aws_availability_zones.available.names[0]}-master"
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

    command = "echo $l1 >> ${self.public_ip}.inv && echo $l2 >> ${self.public_ip}.inv && echo $l3 >> ${self.public_ip}.inv && echo $l4 >> ${self.public_ip}.inv"

    environment = {
      l1 = "[re_master]"
      l2 = "${self.public_ip}"
      l3 = "[re_slave]"
      l4 = "${aws_instance.az1_replica_instance.public_ip}"
    }
  }

  ##############
  # Install RE #
  ##############
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} --private-key ${var.private_key} ../../playbooks/common/2VM-1-master-1-replica-multi-az-az1-master.yml --extra-vars \"re_cluster_name=${var.re_cluster_name}-${data.aws_availability_zones.available.names[0]} re_proxy_max_threads=10 re_db_shards_count='true' re_db_type='big_redis' re_db_shards_count=16 re_proxy_threads=10\" -i ${self.public_ip}.inv"
  }

  ###############################################
  # Remove any inventory file #
  ###############################################
  provisioner "local-exec" {
    command = "rm *.inv"
  }
}
