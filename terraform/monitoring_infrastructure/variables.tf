# Variables

variable "setup_name" {
  description = "setup name"
  default = "perf-cto-monitoring-servers-ubuntu16.04"
}

variable "region" {
  default = "us-east-2"
}

variable "server_instance_count" {
  default = "1"
}

variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default     = "ami-0f93b5fd8f220e428"
}

variable "instance_device_name" {
    description = "EC2 instance device name"
  default = "/dev/sda1"
}

variable "instance_type" {
  description = "type for aws EC2 instance"
  #general purpose dont need a big thing
  default     = "c5.xlarge"
}

variable "redis_module" {
 description = "redis_module"
  default     = "perf-cto-common"
}

variable "instance_volume_size" {
    description = "EC2 instance volume_size"
  default = "1024"
}

variable "instance_volume_iops" {
    description = "EC2 instance volume_iops"
  default = "1000"
}

variable "instance_type_5m" {
  description = "type for aws EC2 instance"
  default     = "c5.9xlarge"
}

variable "instance_cpu_core_count" {
  description = "CPU core count for aws EC2 instance"
  default     = 2
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


