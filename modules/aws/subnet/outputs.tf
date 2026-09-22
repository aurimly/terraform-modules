output "subnet_ids" {
  description = "Map of subnet key => subnet ID (subnet-...)."
  value       = { for k, s in aws_subnet.subnet : k => s.id }
}

output "subnet_arns" {
  description = "Map of subnet key => subnet ARN."
  value       = { for k, s in aws_subnet.subnet : k => s.arn }
}

output "subnet_cidr_blocks" {
  description = "Map of subnet key => IPv4 CIDR block."
  value       = { for k, s in aws_subnet.subnet : k => s.cidr_block }
}

output "subnet_availability_zones" {
  description = "Map of subnet key => availability zone the subnet was placed in (useful when availability_zone was omitted and AWS picked one)."
  value       = { for k, s in aws_subnet.subnet : k => s.availability_zone }
}
