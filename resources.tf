#providers
provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "performance_cto_us_east_2" {
  key_name   = "performance-cto-us-east-2"
  public_key = "${file("../pems/performance-cto-us-east-2.pub")}"

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

resource "aws_network_interface" "perf_cto_client_network_interface" {
  count           = "${var.instance_network_interface_plus_count}"
  subnet_id       = "${aws_subnet.subnet_public.id}"
  security_groups = ["${aws_security_group.performance_cto_sg.id}"]

  attachment {
    instance     = "${aws_instance.perf_cto_client[0].id}"
    device_index = "${count.index + 2}"
  }
}


resource "aws_network_interface" "perf_cto_server_network_interface" {
  count           = "${var.instance_network_interface_plus_count}"
  subnet_id       = "${aws_subnet.subnet_public.id}"
  security_groups = ["${aws_security_group.performance_cto_sg.id}"]

  attachment {
    instance     = "${aws_instance.perf_cto_server[0].id}"
    device_index = "${count.index + 2}"
  }
}

resource "aws_placement_group" "perf_cto_pg" {
  name     = "${var.placement_group_name}"
  strategy = "cluster"
}

resource "aws_instance" "perf_cto_client" {
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

  # Ansible requires Python to be installed on the remote machine as well as the local machine.
  provisioner "remote-exec" {
    inline = ["sudo yum install python -y"]
  }

  tags = {
    Name = "perf-cto-client-${count.index + 1}"
  }
}

resource "aws_instance" "perf_cto_server" {
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

  # Ansible requires Python to be installed on the remote machine as well as the local machine.
  provisioner "remote-exec" {
    inline = ["sudo yum install python -y"]
  }

  tags = {
    Name = "perf-cto-server-${count.index + 1}"
  }

}
