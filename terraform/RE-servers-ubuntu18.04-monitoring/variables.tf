# Variables

variable "setup_name" {
  description = "setup name"
  default     = "perf-cto-monitoring-servers-ubuntu18.04-redistimeseries"
}


variable "re_cluster_name" {
 description = "re_cluster_name"
  default     = "perf-cto-monitoring-servers"
}

variable "region" {
  default = "us-east-2"
}

variable "server_instance_count" {
  default = "1"
}


variable "instance_ami" {
  description = "AMI for aws EC2 instance - perf-cto-base-bench-servers-RE-5.4.14-19"
  default     = "ami-0a9aa29381da85ced"
}

variable "instance_device_name" {
  description = "EC2 instance device name"
  default     = "/dev/sda1"
}

variable "root_volume_size" {
  description = "EC2 instance volume_size"
  default     = "256"
}

variable "root_volume_type" {
  description = "EC2 instance volume_type"
  default     = "gp2"
}

variable "root_volume_iops" {
  description = "EC2 instance volume_iops"
  default     = "768"
}

variable "root_volume_encrypted" {
  description = "EC2 instance instance_volume_encrypted"
  default     = "false"
}

variable "ebs_volume_size" {
  description = "EC2 EBS ebs_volume_size"
  default     = "1220"
}


variable "ebs_volume_type" {
  description = "EC2 instance volume_type"
  default     = "gp2"
}

variable "ebs_volume_iops" {
  description = "EC2 instance volume_iops"
  default     = "3660"
}

variable "ebs_volume_encrypted" {
  description = "EC2 instance instance_volume_encrypted"
  default     = "false"
}


variable "instance_type" {
  description = "type for aws EC2 instance"
  #general purpose dont need a big thing
  default     = "r5.xlarge"
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


