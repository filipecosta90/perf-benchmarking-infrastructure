
#resources

terraform {
  backend "s3" {
    bucket = "performance-cto-group"
    key    = "benchmarks/infrastructure/shared_resources.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = "${var.environment_tag}"
    Name        = "perf-cto-vpc"
  }
}


#keep monitoring ip always the same
resource "aws_eip" "perf_cto_eip" {
  vpc = true
  tags = {
    Name = "perf-cto-monitoring-eip"
  }
}

#keep monitoring ip always the same
resource "aws_eip" "perf_cto_monitoring_redistimeseries_cluster_ip" {
  vpc = true
  tags = {
    Name = "perf-cto-monitoring-redistimeseries-cluster-ip"
  }
}

resource "aws_placement_group" "perf_cto_pg" {
  name     = "${var.placement_group_name}"
  strategy = "cluster"
}


resource "aws_placement_group" "perf_cto_pg_us_east_2b" {
  name     = "${var.placement_group_name_us_east_2b}"
  strategy = "cluster"
}


resource "aws_placement_group" "perf_cto_pg_us_east_2c" {
  name     = "${var.placement_group_name_us_east_2c}"
  strategy = "cluster"
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

resource "aws_subnet" "subnet_public_us_east_2b" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidr_subnet_2b}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.availability_zone_2b}"
  tags = {
    Environment = "${var.environment_tag}"
    Name        = "perf-cto-subnet-${var.availability_zone_2b}"
  }
}


resource "aws_subnet" "subnet_public_us_east_2c" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidr_subnet_2c}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.availability_zone_2c}"
  tags = {
    Environment = "${var.environment_tag}"
    Name        = "perf-cto-subnet-${var.availability_zone_2c}"
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
provider "aws" {
  region = "${var.region}"
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = "${aws_subnet.subnet_public.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}


resource "aws_route_table_association" "rta_subnet_public_2b" {
  subnet_id      = "${aws_subnet.subnet_public_us_east_2b.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}

resource "aws_route_table_association" "rta_subnet_public_2c" {
  subnet_id      = "${aws_subnet.subnet_public_us_east_2c.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}


resource "aws_security_group" "performance_cto_sg" {
  name   = "perf-cto-sg"
  vpc_id = "${aws_vpc.vpc.id}"

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    description = ""
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 
  ingress {
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    description      = ""
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 19999
    to_port     = 19999
    protocol    = "tcp"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Performance Monitoring Always-On Cluster Port
  ingress {
    from_port   = 24999
    to_port     = 24999
    protocol    = "tcp"
    description = "Performance Monitoring RedisTimeSeries Cluster Port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 49999
    to_port     = 49999
    protocol    = "tcp"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Neo
  ingress {
    from_port        = 7474
    to_port          = 7474
    protocol         = "tcp"
    description      = ""
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Redis Enterprise
  ingress {
    from_port        = 8001
    to_port          = 8001
    protocol         = "tcp"
    description      = ""
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Redis Enterprise
  ingress {
    from_port        = 8443
    to_port          = 8443
    protocol         = "tcp"
    description      = ""
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  # Redis Enterprise
  ingress {
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    description      = ""
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Redis Enterprise
  ingress {
    from_port        = 9443
    to_port          = 9443
    protocol         = "tcp"
    description      = ""
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
    description = ""
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
    description = ""
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = ""
  }

  tags = {
    Environment = "${var.environment_tag}"
    Name        = "perf-cto-sg"
  }
}
