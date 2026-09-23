output "instance_ids" {
  description = "Map of instance key => instance ID (i-...)."
  value       = { for k, i in aws_instance.instance : k => i.id }
}

output "instance_arns" {
  description = "Map of instance key => instance ARN."
  value       = { for k, i in aws_instance.instance : k => i.arn }
}

output "instance_private_ips" {
  description = "Map of instance key => private IPv4 address."
  value       = { for k, i in aws_instance.instance : k => i.private_ip }
}

output "instance_public_ips" {
  description = "Map of instance key => public IPv4 address, null for instances without a public IP. Covers all instance keys."
  value       = { for k, i in aws_instance.instance : k => i.public_ip != "" ? i.public_ip : null }
}

output "instance_security_group_ids" {
  description = "Map of instance key => security group IDs attached to the instance's network interface."
  value       = { for k, i in aws_instance.instance : k => i.vpc_security_group_ids }
}
