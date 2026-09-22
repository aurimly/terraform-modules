output "security_group_ids" {
  description = "Map of security group key => security group ID (sg-...)."
  value       = { for k, g in aws_security_group.sg : k => g.id }
}

output "security_group_arns" {
  description = "Map of security group key => security group ARN."
  value       = { for k, g in aws_security_group.sg : k => g.arn }
}

output "security_group_vpc_ids" {
  description = "Map of security group key => VPC ID the group lives in."
  value       = { for k, g in aws_security_group.sg : k => g.vpc_id }
}
