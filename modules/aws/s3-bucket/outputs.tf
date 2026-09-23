output "bucket_ids" {
  description = "Map of bucket key => bucket ID (the bucket name)."
  value       = { for k, v in aws_s3_bucket.bucket : k => v.id }
}

output "bucket_arns" {
  description = "Map of bucket key => bucket ARN."
  value       = { for k, v in aws_s3_bucket.bucket : k => v.arn }
}

output "bucket_regions" {
  description = "Map of bucket key => hosting region."
  value       = { for k, v in aws_s3_bucket.bucket : k => v.region }
}

output "bucket_regional_domain_names" {
  description = "Map of bucket key => bucket regional domain name (e.g. for origins and endpoints)."
  value       = { for k, v in aws_s3_bucket.bucket : k => v.bucket_regional_domain_name }
}

output "bucket_regional_zone_domain_names" {
  description = "Map of bucket key => bucket regional zone domain name (dual-stack friendly)."
  value       = { for k, v in aws_s3_bucket.bucket : k => v.bucket_domain_name }
}

output "bucket_hosted_zone_ids" {
  description = "Map of bucket key => Route 53 Hosted Zone ID of the bucket endpoint (for alias records)."
  value       = { for k, v in aws_s3_bucket.bucket : k => v.hosted_zone_id }
}

output "bucket_website_endpoints" {
  description = "Map of bucket key => website endpoint, only when a website configuration is set."
  value       = { for k, v in aws_s3_bucket.bucket : k => v.website_endpoint }
}
