locals {
  tags = {
    Organization = "Xtages"
    Terraform    = true
    Environment  = var.env
  }
  ecs_tags = [
    {
      key                 = "Terraform"
      value               = true
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "ECS cluster - ${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "Organization"
      value               = "Xtages"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = var.env
      propagate_at_launch = true
    }
  ]
}

data "aws_ami" "latest_ecs" {
  most_recent = true
  owners      = ["591542846629"] # AWS

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "ecs_user_data" {
  template = <<-EOF
              #!/bin/bash
              echo 'ECS_CLUSTER=${var.cluster_name}' > /etc/ecs/ecs.config
              echo 'ECS_ENABLE_SPOT_INSTANCE_DRAINING=true' >> /etc/ecs/ecs.config
              echo 'ECS_ENABLE_TASK_IAM_ROLE=true' >> /etc/ecs/ecs.config
              echo 'ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]' >> /etc/ecs/ecs.config
              iptables-save | tee /etc/sysconfig/iptables && systemctl enable --now iptables
              start ecs
              EOF
}
