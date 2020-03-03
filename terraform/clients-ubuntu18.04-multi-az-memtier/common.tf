#providers
provider "aws" {
  region = "${var.region}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "terraform_remote_state" "shared_resources" {
  backend = "s3"
  config = {
    bucket = "performance-cto-group"
    key    = "benchmarks/infrastructure/shared_resources.tfstate"
    region = "us-east-1"
  }
}

terraform {
  backend "s3" {
    bucket = "performance-cto-group"
    key    = "benchmarks/infrastructure/clients-ubuntu18.04-multi-az-memtier.tfstate"
    region = "us-east-1"
  }
}