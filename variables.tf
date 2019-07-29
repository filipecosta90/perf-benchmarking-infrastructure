# Variables

variable "region" {
  default = "us-east-2"
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
variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "c5n.18xlarge"
}

variable "instance_cpu_core_count" {
  description = "CPU core count for aws EC2 instance"
  default     = 36
}

variable "instance_cpu_threads_per_core" {
  description = "CPU threads per core for aws EC2 instance"
  default     = 1
}


variable "instance_network_interface_plus_count" {
  description = "number of additional network interfaces to add to aws EC2 instance"
  default     = 9
}


variable "placement_group_name" {
  description = "placement group name"
  default     = "perf-cto-pg"
}

variable "environment_tag" {
  description = "Environment tag"
  default     = "performance-cto"
}
