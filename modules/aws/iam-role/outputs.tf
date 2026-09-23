output "role_names" {
  description = "Map of role key => role name."
  value       = { for k, r in aws_iam_role.role : k => r.name }
}

output "role_arns" {
  description = "Map of role key => role ARN."
  value       = { for k, r in aws_iam_role.role : k => r.arn }
}

output "role_unique_ids" {
  description = "Map of role key => role unique ID (AROA...); usable as an sts:AssumeRole principal in other policies."
  value       = { for k, r in aws_iam_role.role : k => r.unique_id }
}

output "instance_profile_names" {
  description = "Map of role key => instance profile name, null for roles without a profile. Covers all role keys."
  value       = { for k, v in var.roles : k => v.create_instance_profile ? aws_iam_instance_profile.profile[k].name : null }
}

output "instance_profile_arns" {
  description = "Map of role key => instance profile ARN, null for roles without a profile. Covers all role keys."
  value       = { for k, v in var.roles : k => v.create_instance_profile ? aws_iam_instance_profile.profile[k].arn : null }
}
