output "cluster_ids" {
  description = "Map of cluster key => cluster ID."
  value       = { for k, c in aws_ecs_cluster.cluster : k => c.id }
}

output "cluster_arns" {
  description = "Map of cluster key => cluster ARN (feed aws/ecs-service services.*.cluster)."
  value       = { for k, c in aws_ecs_cluster.cluster : k => c.arn }
}

output "cluster_names" {
  description = "Map of cluster key => cluster name."
  value       = { for k, c in aws_ecs_cluster.cluster : k => c.name }
}
