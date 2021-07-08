output "xtages_console_alb_arn" {
  value = aws_lb.xtages_console_lb.arn
}

output "xtages_ecs_cluster_id" {
  value = aws_ecs_cluster.xtages_cluster.id
}

output "ecs_service_role_arn" {
  value = aws_iam_role.ecs_service_role.arn
}

output "xtages_customers_alb_arn" {
  value = aws_lb.xtages_customers_lb.arn
}
