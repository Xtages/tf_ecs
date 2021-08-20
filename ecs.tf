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
  name_prefix           = var.cluster_name
  vpc_zone_identifier   = var.private_subnet_ids
  min_size              = var.asg_min_size
  max_size              = var.asg_max_size
  protect_from_scale_in = true

  mixed_instances_policy {

    instances_distribution {
      on_demand_base_capacity                  = var.asg_instance_distribution["on_demand_base_capacity"]
      on_demand_percentage_above_base_capacity = var.asg_instance_distribution["on_demand_percentage_above_base_capacity"]
      spot_allocation_strategy                 = var.asg_instance_distribution["spot_allocation_strategy"]
      spot_instance_pools                      = var.asg_instance_distribution["spot_instance_pools"]
      spot_max_price                           = var.asg_instance_distribution["spot_max_price"]
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs_xtages_launch_template.id
      }

      dynamic "override" {
        for_each = var.asg_launch_template_override
        content {
          instance_type = override.value["instance_type"]
          weighted_capacity = override.value["weighted_capacity"]
        }
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
