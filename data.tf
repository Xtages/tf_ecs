data "aws_ami" "latest_ecs" {
  most_recent = true
  owners = ["591542846629"] # AWS

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
              echo 'ECS_CLUSTER=xtages-cluster' > /etc/ecs/ecs.config
              echo 'ECS_ENABLE_SPOT_INSTANCE_DRAINING=true' >> /etc/ecs/ecs.config
              echo 'ECS_ENABLE_TASK_IAM_ROLE=true' >> /etc/ecs/ecs.config
              echo 'ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]' >> /etc/ecs/ecs.config
              iptables-save | tee /etc/sysconfig/iptables && systemctl enable --now iptables
              start ecs
              EOF
}
