output "distribution_ids" {
  description = "Map of distribution key => distribution ID (E2...; also the aws_cloudfront_distribution import ID)."
  value       = { for k, d in aws_cloudfront_distribution.distribution : k => d.id }
}

output "distribution_arns" {
  description = "Map of distribution key => distribution ARN."
  value       = { for k, d in aws_cloudfront_distribution.distribution : k => d.arn }
}

output "distribution_domain_names" {
  description = "Map of distribution key => dxxxx.cloudfront.net domain name."
  value       = { for k, d in aws_cloudfront_distribution.distribution : k => d.domain_name }
}

output "distribution_hosted_zone_ids" {
  description = "Map of distribution key => CloudFront zone ID (Z2FDTNDATAQYW2) for alias records in aws/route53-records."
  value       = { for k, d in aws_cloudfront_distribution.distribution : k => d.hosted_zone_id }
}

output "distribution_status" {
  description = "Map of distribution key => current deployment status."
  value       = { for k, d in aws_cloudfront_distribution.distribution : k => d.status }
}

output "distribution_etags" {
  description = "Map of distribution key => current version ETag."
  value       = { for k, d in aws_cloudfront_distribution.distribution : k => d.etag }
}

output "oac_ids" {
  description = "Map of \"dist-key.origin-key\" => origin access control ID (for S3 bucket policies and imports; only origins that set oac appear)."
  value       = { for k, o in aws_cloudfront_origin_access_control.oac : k => o.id }
}

output "oac_arns" {
  description = "Map of \"dist-key.origin-key\" => origin access control ARN (S3 bucket policy SourceArn-style grants)."
  value       = { for k, o in aws_cloudfront_origin_access_control.oac : k => o.arn }
}
