# cluster
resource "aws_ecs_cluster" "xtages_cluster" {
  name = var.cluster_name

  setting {
    name = "containerInsights"
    value = "enabled"
  }

  capacity_providers = [
    aws_ecs_capacity_provider.xtages_capacity_provider.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.xtages_capacity_provider.name
    weight = 1
    base = 0
  }
}

resource "aws_launch_template" "ecs_xtages_launch_template" {
  name_prefix            = "ecs-launchtemplate"
  image_id               = data.aws_ami.latest_ecs.image_id
  instance_type          = var.ecs_instance_type
  key_name               = "xtages-${var.env}"
  update_default_version = true
  tags = {
    Terraform = true
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_ec2_role.arn
  }
  user_data = base64encode(data.template_file.ecs_user_data.rendered)
  network_interfaces {
    security_groups = [aws_security_group.ecs_sg.id]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_xtages_asg" {
  name_prefix                = "ecs-xtages-autoscaling"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 1
  max_size            = 10
  protect_from_scale_in = true

  mixed_instances_policy {

    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
      spot_max_price                           = "0.0464"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs_xtages_launch_template.id
      }

      override {
        instance_type     = "m5.large"
        weighted_capacity = "1"
      }

      override {
        instance_type     = "t2.large"
        weighted_capacity = "1"
      }

      override {
        instance_type     = "t3.large"
        weighted_capacity = "1"
      }

      override {
        instance_type     = "t2.medium"
        weighted_capacity = "1"
      }

      override {
        instance_type     = "t3.medium"
        weighted_capacity = "1"
      }
    }
  }

  tags = [
    {
      key                 = "Terraform"
      value               = true
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "ECS cluster"
      propagate_at_launch = true
    },
    {
      key                 = "Organization"
      value               = "Xtages"
      propagate_at_launch = true
    }
  ]
}

resource "aws_ecs_capacity_provider" "xtages_capacity_provider" {
  name = "xtages_capacity"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_xtages_asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 2
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
  tags = {
    Name = "ECS Cluster"
    Organization = "Xtages"
    Terraform = true
  }
}

# Scale up alarm

resource "aws_autoscaling_policy" "cpu_asg_policy" {
  name                   = "CPU-ASG-Policy-Add"
  autoscaling_group_name = aws_autoscaling_group.ecs_xtages_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu_above_80p_alarm" {
  alarm_name          = "CPU-above-80p"
  alarm_description   = "CPU above 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.ecs_xtages_asg.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu_asg_policy.arn]
}

# Scale down alarm

resource "aws_autoscaling_policy" "cpu_asg_policy_scaledown" {
  name                   = "CPU-ASG-Policy-scaledown"
  autoscaling_group_name = aws_autoscaling_group.ecs_xtages_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu_below_5p_alarm" {
  alarm_name          = "CPU-below-5p"
  alarm_description   = "CPU below 5%"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.ecs_xtages_asg.arn
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu_asg_policy_scaledown.arn]
}
