output "endpoint_ids" {
  description = "Map of endpoint key => endpoint ID (rslvr-in-.../rslvr-out-...)."
  value       = { for k, e in aws_route53_resolver_endpoint.endpoint : k => e.id }
}

output "endpoint_arns" {
  description = "Map of endpoint key => endpoint ARN."
  value       = { for k, e in aws_route53_resolver_endpoint.endpoint : k => e.arn }
}

output "endpoint_host_vpc_ids" {
  description = "Map of endpoint key => ID of the VPC the endpoint was created in."
  value       = { for k, e in aws_route53_resolver_endpoint.endpoint : k => e.host_vpc_id }
}

output "endpoint_ips" {
  description = "Map of endpoint key => list of {subnet_id, ip, ipv6} entries. For inbound endpoints these are the addresses on-premises resolvers forward to; for outbound endpoints they appear in the on-premises firewall allowlists."
  value       = { for k, e in aws_route53_resolver_endpoint.endpoint : k => [for ip in e.ip_address : { subnet_id = ip.subnet_id, ip = ip.ip, ipv6 = ip.ipv6 }] }
}

output "rule_ids" {
  description = "Map of rule key => rule ID (rslvr-rr-...)."
  value       = { for k, r in aws_route53_resolver_rule.rule : k => r.id }
}

output "rule_arns" {
  description = "Map of rule key => rule ARN."
  value       = { for k, r in aws_route53_resolver_rule.rule : k => r.arn }
}

output "rule_owner_ids" {
  description = "Map of rule key => account ID of the rule owner (needed when sharing rules to other accounts via RAM)."
  value       = { for k, r in aws_route53_resolver_rule.rule : k => r.owner_id }
}

output "rule_share_statuses" {
  description = "Map of rule key => share status (NOT_SHARED, SHARED_BY_ME, SHARED_WITH_ME)."
  value       = { for k, r in aws_route53_resolver_rule.rule : k => r.share_status }
}

output "association_ids" {
  description = "Map of association key => association ID (rslvr-rrassoc-...), keyed by the associations entry's own map key."
  value       = { for k, a in aws_route53_resolver_rule_association.association : k => a.id }
}

output "dnssec_config_ids" {
  description = "Map of DNSSEC config key => config ID (rdsc-...)."
  value       = { for k, c in aws_route53_resolver_dnssec_config.dnssec_config : k => c.id }
}

output "dnssec_validation_statuses" {
  description = "Map of DNSSEC config key => validation status (ENABLING, ENABLED, DISABLING, DISABLED, UPDATING)."
  value       = { for k, c in aws_route53_resolver_dnssec_config.dnssec_config : k => c.validation_status }
}
