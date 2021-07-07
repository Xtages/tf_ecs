variable "vpc_id" {}

variable "aws_region" {}

variable "ecs_instance_type" {
  default = "t2.medium"
}

variable "env" {}

variable "private_subnet_ids" {
  default = ""
}

variable "public_subnet_ids" {
  default = ""
}

variable "cluster_name" {}
