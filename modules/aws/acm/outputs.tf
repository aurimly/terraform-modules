output "certificate_arns" {
  description = "Map of certificate key => certificate ARN (feed aws/alb listener certificate_arn, CloudFront, and other TLS consumers)."
  value       = { for k, c in aws_acm_certificate.certificate : k => c.arn }
}

output "certificate_domain_names" {
  description = "Map of certificate key => primary domain name."
  value       = { for k, c in aws_acm_certificate.certificate : k => c.domain_name }
}

output "certificate_statuses" {
  description = "Map of certificate key => certificate status (PENDING_VALIDATION, ISSUED, INACTIVE, EXPIRED, VALIDATION_TIMED_OUT, REVOKED, FAILED)."
  value       = { for k, c in aws_acm_certificate.certificate : k => c.status }
}

output "certificate_domain_validation_options" {
  description = "Map of certificate key => list of domain validation objects ({domain_name, resource_record_name, resource_record_type, resource_record_value}); populated for DNS-validated certificates. This is the hand-rolled-records path: create the records in aws/route53-records from these values when create_validation_records = false."
  value       = { for k, c in aws_acm_certificate.certificate : k => [for dvo in c.domain_validation_options : dvo] }
}

output "validation_record_fqdns" {
  description = "Map of certificate key => set of validation record FQDNs created by this module (only for certificates in the validation_records output set)."
  value       = { for k, v in aws_acm_certificate_validation.validation : k => v.validation_record_fqdns }
}

output "certificate_not_afters" {
  description = "Map of certificate key => expiration date and time of the certificate (expiry monitoring)."
  value       = { for k, c in aws_acm_certificate.certificate : k => c.not_after }
}
