output "vpc_ids" {
  description = "Map of VPC key => VPC ID (vpc-...)."
  value       = { for k, v in aws_vpc.vpc : k => v.id }
}

output "vpc_arns" {
  description = "Map of VPC key => VPC ARN."
  value       = { for k, v in aws_vpc.vpc : k => v.arn }
}

output "vpc_cidr_blocks" {
  description = "Map of VPC key => resolved IPv4 CIDR block (useful when IPAM-assigned)."
  value       = { for k, v in aws_vpc.vpc : k => v.cidr_block }
}

output "vpc_main_route_table_ids" {
  description = "Map of VPC key => ID of the VPC's main route table."
  value       = { for k, v in aws_vpc.vpc : k => v.main_route_table_id }
}
