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

variable "cidr_subnet_2b" {
  description = "CIDR block for the subnet"
  default     = "10.3.1.0/24"
}

variable "cidr_subnet_2c" {
  description = "CIDR block for the subnet"
  default     = "10.3.2.0/24"
}

variable "availability_zone" {
  description = "availability zone to create subnet"
  default     = "us-east-2a"
}

variable "availability_zone_2b" {
  description = "availability zone to create subnet"
  default     = "us-east-2b"
}
variable "availability_zone_2c" {
  description = "availability zone to create subnet"
  default     = "us-east-2c"
}

variable "placement_group_name" {
  description = "placement group name"
  default     = "perf-cto-pg"
}

variable "placement_group_name_us_east_2b" {
  description = "placement group name"
  default     = "perf-cto-pg-us-east-2b"
}

variable "placement_group_name_us_east_2c" {
  description = "placement group name"
  default     = "perf-cto-pg-us-east-2c"
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


