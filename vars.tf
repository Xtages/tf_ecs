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

variable "ecs_sg_id" {
  description = "Security Group for ECS"
}

variable "asg_min_size" {
  default     = 1
  description = "Minimum number of host that will be allocated for the cluster"
}

variable "asg_max_size" {
  default     = 10
  description = "Maximum number of host that will be allocated for the cluster"
}

variable "asg_launch_template_override" {
  description = "Override block from autoscaling_group resource. More information here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#override"
}

variable "asg_instance_distribution" {
  description = "ASG instance distribution block. All params should be there. More information here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#instances_distribution"
}
