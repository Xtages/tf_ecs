# cluster
resource "aws_ecs_cluster" "xtages_cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  capacity_providers = [
    aws_ecs_capacity_provider.xtages_capacity_provider.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.xtages_capacity_provider.name
    weight            = 1
    base              = 0
  }

  tags = local.tags
}

resource "aws_launch_template" "ecs_xtages_launch_template" {
  name_prefix            = "ecs-launchtemplate"
  image_id               = data.aws_ami.latest_ecs.image_id
  instance_type          = var.ecs_instance_type
  key_name               = "xtages-${var.env}"
  update_default_version = true
  tags                   = local.tags

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_ec2_role.arn
  }
  user_data = base64encode(data.template_file.ecs_user_data.rendered)
  network_interfaces {
    security_groups = [var.ecs_sg_id]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_xtages_asg" {
  name_prefix           = "ecs-xtages-autoscaling"
  vpc_zone_identifier   = var.private_subnet_ids
  min_size              = 1
  max_size              = 10
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

  tags = local.ecs_tags
}

resource "aws_ecs_capacity_provider" "xtages_capacity_provider" {
  name = "${var.cluster_name}-${random_id.random_id.id}"

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
  tags = local.tags
}
