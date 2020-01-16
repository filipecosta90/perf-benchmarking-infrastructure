# Variables

variable "region" {
  default = "us-east-2"
}

variable "setup_name" {
  description = "setup name"
  default     = "perf-cto-RE-servers-amazonlinux2-redisearch-30"
}

variable "re_cluster_name" {
 description = "re_cluster_name"
  default     = "cluster-1vm-rhel7-redisearch-30"
}


variable "redis_module" {
  description = "redis_module"
  default     = "RediSearch"
}

variable "os" {
  description = "os"
  default     = "rhel7"
}

variable "ssh_user" {
  description = "ssh_user"
  default     = "ec2-user"
}

variable "server_instance_count" {
  default = "1"
}
variable "client_instance_count" {
  default = "1"
}

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.3.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.3.0.0/24"
}
variable "availability_zone" {
  description = "availability zone to create subnet"
  default     = "us-east-2a"
}
variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default     = "ami-0d8f6eb4f641ef691"
}

variable "instance_device_name" {
  description = "EC2 instance device name"
  default     = "/dev/xvda"
}

variable "instance_volume_size" {
  description = "EC2 instance volume_size"
  default     = "128"
}

variable "instance_volume_encrypted" {
  description = "EC2 instance instance_volume_encrypted"
  default     = "false"
}

variable "instance_volume_iops" {
  description = "EC2 instance volume_iops"
  default     = "100"
}

variable "instance_volume_type" {
  description = "EC2 instance volume_type"
  default     = "gp2"
}

# Model	r5n.24xlarge
# Processor	Xeon Platinum 8000
# (Skylake-SP)	Xeon Platinum 8000
# vCPU	96
# Memory (GiB) 768
# Instance Storage (GiB)	EBS-Only	
# Network Bandwidth (Gbps) 100
variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "r5n.24xlarge"
}

variable "instance_cpu_core_count" {
  description = "CPU core count for aws EC2 instance"
  default     = 48
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


variable "placement_group_name" {
  description = "placement group name"
  default     = "perf-cto-pg"
}

variable "environment_tag" {
  description = "Environment tag"
  default     = "performance-cto"
}

variable "private_key" {
  description = "private key"
  default     = "./../../../pems/perf-cto-us-east-2.pem"
}


variable "public_key" {
  description = "public key"
  default     = "./../../../pems/perf-cto-us-east-2.pub"
}

variable "key_name" {
  description = "key name"
  default     = "perf-cto-us-east-2"
}


