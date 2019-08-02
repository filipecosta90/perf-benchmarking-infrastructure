#providers
provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "performance_cto_us_east_2" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key)}"
}

#resources
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = "${var.environment_tag}"
    Name        = "perf-cto-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Environment = "${var.environment_tag}"
    Name        = "perf-cto-gw"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidr_subnet}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.availability_zone}"
  tags = {
    Environment = "${var.environment_tag}"
    Name        = "perf-cto-subnet"
  }
}


resource "aws_route_table" "rtb_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Environment = "${var.environment_tag}"
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = "${aws_subnet.subnet_public.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}

resource "aws_security_group" "performance_cto_sg" {
  name   = "perf-cto-sg"
  vpc_id = "${aws_vpc.vpc.id}"

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment_tag}"
    Name        = "perf-cto-sg"
  }
}

resource "aws_network_interface" "perf_cto_client_c5n_18xlarge_network_interface" {
  count           = "${var.instance_network_interface_plus_count}"
  subnet_id       = "${aws_subnet.subnet_public.id}"
  security_groups = ["${aws_security_group.performance_cto_sg.id}"]

  attachment {
    instance     = "${aws_instance.perf_cto_client_c5n_18xlarge[0].id}"
    device_index = "${count.index + 2}"
  }
}


# resource "aws_network_interface" "perf_cto_server_c5n_18xlarge_network_interface" {
#   count           = "${var.instance_network_interface_plus_count}"
#   subnet_id       = "${aws_subnet.subnet_public.id}"
#   security_groups = ["${aws_security_group.performance_cto_sg.id}"]

#   attachment {
#     instance     = "${aws_instance.perf_cto_server_c5n_18xlarge[0].id}"
#     device_index = "${count.index + 2}"
#   }
# }

# resource "aws_network_interface" "perf_cto_server_c5n_18xlarge_hyperthreading_network_interface" {
#   count           = "${var.instance_network_interface_plus_count}"
#   subnet_id       = "${aws_subnet.subnet_public.id}"
#   security_groups = ["${aws_security_group.performance_cto_sg.id}"]

#   attachment {
#     instance     = "${aws_instance.perf_cto_server_c5n_18xlarge_hyperthreading[0].id}"
#     device_index = "${count.index + 2}"
#   }
# }

# resource "aws_network_interface" "perf_cto_server_c5_18xlarge_hyperthreading_network_interface" {
#   count           = "${var.instance_network_interface_plus_count}"
#   subnet_id       = "${aws_subnet.subnet_public.id}"
#   security_groups = ["${aws_security_group.performance_cto_sg.id}"]

#   attachment {
#     instance     = "${aws_instance.perf_cto_server_c5_18xlarge_hyperthreading[0].id}"
#     device_index = "${count.index + 2}"
#   }
# }

resource "aws_placement_group" "perf_cto_pg" {
  name     = "${var.placement_group_name}"
  strategy = "cluster"
}

resource "aws_instance" "perf_cto_client_c5n_18xlarge" {
  count                  = "${var.client_instance_count}"
  ami                    = "${var.instance_ami}"
  instance_type          = "${var.instance_type}"
  subnet_id              = "${aws_subnet.subnet_public.id}"
  vpc_security_group_ids = ["${aws_security_group.performance_cto_sg.id}"]
  key_name               = "${aws_key_pair.performance_cto_us_east_2.key_name}"
  cpu_core_count         = "${var.instance_cpu_core_count}"
  cpu_threads_per_core   = "${var.instance_cpu_threads_per_core}"
  placement_group        = "${aws_placement_group.perf_cto_pg.name}"

  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_size           = 1023
    volume_type           = "io1"
    iops                  = 3000
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    Name = "perf-cto-client-c5n_18xlarge-${count.index + 1}"
  }

  # Ansible requires Python to be installed on the remote machine as well as the local machine.
  provisioner "remote-exec" {
    inline = ["sudo yum install python -y"]
    connection {
      host        = "${self.public_ip}" # The `self` variable is like `this` in many programming languages
      type        = "ssh"               # in this case, `self` is the resource (the server).
      user        = "ec2-user"
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
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/amazon-linux-2-perf.yml -i ${self.public_ip},"
  }

  #######
  # BCC #
  #######
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/amazon-linux-2-bcc.yml -i ${self.public_ip},"
  }

  
  #######
  # PCP #
  #######
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/amazon-linux-2-pcp.yml -i ${self.public_ip},"
  }

  ###############################################
  # PCP VECTOR PANDA - System Wide Flame Graphs #
  ###############################################
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/amazon-linux-2-pcp-vector-pmda.yml -i ${self.public_ip},"
  }

  #################
  # EC2 CONFIGURE #
  #################
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/ec2-configure.yml -i ${self.public_ip},"
  }

  ###########
  # NETPERF #
  ###########
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/ec2-netperf.yml -i ${self.public_ip},"
  }

}

resource "aws_instance" "perf_cto_server_c5n_18xlarge" {
  count                  = "${var.server_instance_count}"
  ami                    = "${var.instance_ami}"
  instance_type          = "${var.instance_type}"
  subnet_id              = "${aws_subnet.subnet_public.id}"
  vpc_security_group_ids = ["${aws_security_group.performance_cto_sg.id}"]
  key_name               = "${aws_key_pair.performance_cto_us_east_2.key_name}"
  cpu_core_count         = "${var.instance_cpu_core_count}"
  cpu_threads_per_core   = "${var.instance_cpu_threads_per_core}"
  placement_group        = "${aws_placement_group.perf_cto_pg.name}"

  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_size           = 1023
    volume_type           = "io1"
    iops                  = 3000
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    Name = "perf-cto-server-c5n_18xlarge-${count.index + 1}"
  }

# Ansible requires Python to be installed on the remote machine as well as the local machine.
  provisioner "remote-exec" {
    inline = ["sudo yum install python -y"]
    connection {
      host        = "${self.public_ip}" # The `self` variable is like `this` in many programming languages
      type        = "ssh"               # in this case, `self` is the resource (the server).
      user        = "ec2-user"
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
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/amazon-linux-2-perf.yml -i ${self.public_ip},"
  }

  #######
  # BCC #
  #######
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/amazon-linux-2-bcc.yml -i ${self.public_ip},"
  }

  
  #######
  # PCP #
  #######
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/amazon-linux-2-pcp.yml -i ${self.public_ip},"
  }

  ###############################################
  # PCP VECTOR PANDA - System Wide Flame Graphs #
  ###############################################
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/amazon-linux-2-pcp-vector-pmda.yml -i ${self.public_ip},"
  }

  #################
  # EC2 CONFIGURE #
  #################
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/ec2-configure.yml -i ${self.public_ip},"
  }

  ###########
  # NETPERF #
  ###########
  provisioner "local-exec" {
    environment = {
      PUBLIC_IP  = "${self.public_ip}"
      PRIVATE_IP = "${self.private_ip}"
    }

    # working_dir = "../playbooks/rhel"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ../playbooks/rhel/ec2-netperf.yml -i ${self.public_ip},"
  }

}


# resource "aws_instance" "perf_cto_server_c5n_18xlarge_hyperthreading" {
#   count                  = "${var.server_instance_count}"
#   ami                    = "${var.instance_ami}"
#   instance_type          = "${var.instance_type}"
#   subnet_id              = "${aws_subnet.subnet_public.id}"
#   vpc_security_group_ids = ["${aws_security_group.performance_cto_sg.id}"]
#   key_name               = "${aws_key_pair.performance_cto_us_east_2.key_name}"
#   cpu_core_count         = "${var.instance_cpu_core_count}"
#   cpu_threads_per_core   = "${var.instance_cpu_threads_per_core_hyperthreading}"
#   placement_group        = "${aws_placement_group.perf_cto_pg.name}"

#   ebs_block_device {
#     device_name           = "/dev/sdg"
#     volume_size           = 1023
#     volume_type           = "io1"
#     iops                  = 3000
#     encrypted             = false
#     delete_on_termination = true
#   }

#   # Ansible requires Python to be installed on the remote machine as well as the local machine.
#   provisioner "remote-exec" {
#     inline = ["sudo yum install python -y"]

#     connection {
#       host        = "${self.public_ip}" # The `self` variable is like `this` in many programming languages
#       type        = "ssh"               # in this case, `self` is the resource (the server).
#       user        = "ec2-user"
#       private_key = "${file(var.private_key)}"
#     }

#   }
#   provisioner "local-exec" {
#     environment = {
#       PUBLIC_IP  = "${self.public_ip}"
#       PRIVATE_IP = "${self.private_ip}"
#     }

#     working_dir = "../playbooks/rhel"
#     command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ec2-configure.yml -i ${self.public_ip},"
#   }

#   provisioner "local-exec" {
#     environment = {
#       PUBLIC_IP  = "${self.public_ip}"
#       PRIVATE_IP = "${self.private_ip}"
#     }

#     working_dir = "../playbooks/rhel"
#     command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ec2-netperf.yml -i ${self.public_ip},"
#   }


#   tags = {
#     Name = "perf-cto-server-c5n_18xlarge-hyperthreading-${count.index + 1}"
#   }

# }



# resource "aws_instance" "perf_cto_server_c5_18xlarge_hyperthreading" {
#   count                  = "${var.server_instance_count}"
#   ami                    = "${var.instance_ami}"
#   instance_type          = "${var.instance_type_5m}"
#   subnet_id              = "${aws_subnet.subnet_public.id}"
#   vpc_security_group_ids = ["${aws_security_group.performance_cto_sg.id}"]
#   key_name               = "${aws_key_pair.performance_cto_us_east_2.key_name}"
#   cpu_core_count         = "${var.instance_cpu_core_count}"
#   cpu_threads_per_core   = "${var.instance_cpu_threads_per_core_hyperthreading}"
#   placement_group        = "${aws_placement_group.perf_cto_pg.name}"

#   ebs_block_device {
#     device_name           = "/dev/sdg"
#     volume_size           = 1023
#     volume_type           = "io1"
#     iops                  = 3000
#     encrypted             = false
#     delete_on_termination = true
#   }

#   # Ansible requires Python to be installed on the remote machine as well as the local machine.
#   provisioner "remote-exec" {
#     inline = ["sudo yum install python -y"]

#     connection {
#       host        = "${self.public_ip}" # The `self` variable is like `this` in many programming languages
#       type        = "ssh"               # in this case, `self` is the resource (the server).
#       user        = "ec2-user"
#       private_key = "${file(var.private_key)}"
#     }

#   }
#   provisioner "local-exec" {
#     environment = {
#       PUBLIC_IP  = "${self.public_ip}"
#       PRIVATE_IP = "${self.private_ip}"
#     }

#     working_dir = "../playbooks/rhel"
#     command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ec2-configure.yml -i ${self.public_ip},"
#   }

#   provisioner "local-exec" {
#     environment = {
#       PUBLIC_IP  = "${self.public_ip}"
#       PRIVATE_IP = "${self.private_ip}"
#     }

#     working_dir = "../playbooks/rhel"
#     command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.private_key} ec2-netperf.yml -i ${self.public_ip},"
#   }

#   tags = {
#     Name = "perf-cto-server-c5_18xlarge-hyperthreading-${count.index + 1}"
#   }
# }
