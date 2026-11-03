output "group_names" {
  description = "Map of group key => group name."
  value       = { for k, g in aws_iam_group.group : k => g.name }
}

output "group_arns" {
  description = "Map of group key => group ARN."
  value       = { for k, g in aws_iam_group.group : k => g.arn }
}

output "group_unique_ids" {
  description = "Map of group key => group unique ID (AGPA...)."
  value       = { for k, g in aws_iam_group.group : k => g.unique_id }
}
