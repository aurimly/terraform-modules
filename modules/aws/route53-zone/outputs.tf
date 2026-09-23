output "zone_ids" {
  description = "Map of zone key => hosted zone ID."
  value       = { for k, z in aws_route53_zone.zone : k => z.id }
}

output "zone_arns" {
  description = "Map of zone key => zone ARN."
  value       = { for k, z in aws_route53_zone.zone : k => z.arn }
}

output "zone_name_servers" {
  description = "Map of zone key => list of authoritative name servers (NS records)."
  value       = { for k, z in aws_route53_zone.zone : k => z.name_servers }
}

output "delegation_set_ids" {
  description = "Map of zone key => delegation set ID (only for zones that created one)."
  value       = { for k, z in aws_route53_delegation_set.delegation_set : k => z.id }
}
