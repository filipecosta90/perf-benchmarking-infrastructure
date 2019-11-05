# Variables

variable "setup_name" {
  description = "setup name"
  default = "perf-cto-clients-ubuntu16.04-aibench"
}

variable "region" {
  default = "us-east-2"
}

variable "server_instance_count" {
  default = "1"
}

variable "instance_ami" {
  // us-east-2	xenial	16.04 LTS	amd64	hvm:ebs-io1
  description = "AMI for aws EC2 instance - Ubuntu"
  default     = "ami-07e26819c90e50327"
}

variable "instance_volume_size" {
    description = "EC2 instance volume_size"
  default = "64"
}

variable "instance_volume_iops" {
    description = "EC2 instance volume_iops"
  default = "100"
}

variable "instance_volume_type" {
    description = "EC2 instance volume_type"
  default = "gp2"
}

variable "instance_volume_encrypted" {
  description = "EC2 instance instance_volume_encrypted"
  default     = "false"
}

variable "instance_device_name" {
    description = "EC2 instance device name"
  default = "/dev/sda1"
}

# Model	m5.24xlarge	m5d.24xlarge	m5a.24xlarge	m5ad.24xlarge
# Processor	Xeon Platinum 8000
# (Skylake-SP)	Xeon Platinum 8000
# (Skylake-SP)	AMD EPYC 7000	AMD EPYC 7000
# vCPU	96	96	96	96
# Memory (GiB)	384	384	384	384
# Instance Storage (GiB)	EBS-Only	4 x 900 NVMe SSD	EBS-Only	4 x 900 NVMe SSD
# Network Bandwidth (Gbps)	25	25	20	20
# EBS Bandwidth (Mbps)	14,000	14,000	10,000	10,000
variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "r5.12xlarge"
}

variable "instance_cpu_core_count" {
  description = "CPU core count for aws EC2 instance"
  default     = 24
}

variable "instance_cpu_threads_per_core" {
  description = "CPU threads per core for aws EC2 instance"
  default     = 1
}


variable "instance_cpu_threads_per_core_hyperthreading" {
  description = "CPU threads per core when hyperthreading is enabled for aws EC2 instance"
  default     = 2
}


variable "instance_network_interface_plus_count" {
  description = "number of additional network interfaces to add to aws EC2 instance"
  default     = 0
}

variable "os" {
 description = "os"
  default     = "ubuntu16.04"
}


variable "ssh_user" {
 description = "ssh_user"
  default     = "ubuntu"
}


variable "private_key" {
 description = "private key"
  default     = "./../../../pems/performance-cto-us-east-2.pem"
}


variable "public_key" {
   description = "public key"
  default     = "./../../../pems/performance-cto-us-east-2.pub"
}


variable "key_name" {
   description = "key name"
  default     = "performance-cto-us-east-2"
}

variable "redis_module" {
 description = "redis_module"
  default     = "RedisAI"
}



