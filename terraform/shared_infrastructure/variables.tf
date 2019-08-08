# Variables

variable "region" {
  default = "us-east-2"
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


