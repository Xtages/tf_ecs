output "xtages_ecs_cluster_id" {
  value = aws_ecs_cluster.xtages_cluster.id
}

output "ecs_service_role_arn" {
  value = aws_iam_role.ecs_service_role.arn
}
