output "record_fqdns" {
  description = "Map of \"zone-key.record-key\" => fully qualified domain name of the record."
  value = merge(
    { for k, r in aws_route53_record.simple : k => r.fqdn },
    { for k, r in aws_route53_record.alias : k => r.fqdn },
  )
}
