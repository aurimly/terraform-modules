output "service_arns" {
  description = "Map of service key => service ARN."
  value       = { for k, s in aws_ecs_service.service : k => s.arn }
}

output "service_names" {
  description = "Map of service key => service name."
  value       = { for k, s in aws_ecs_service.service : k => s.name }
}

output "task_definition_arns" {
  description = "Map of service key => task definition ARN (includes the :revision suffix — the value to log and inspect for rollbacks)."
  value       = { for k, t in aws_ecs_task_definition.task_definition : k => t.arn }
}
