output "bucket_names" {
  description = "Map of bucket key => bucket name."
  value       = { for key, bucket in cloudflare_r2_bucket.bucket : key => bucket.name }
}

output "bucket_locations" {
  description = "Map of bucket key => bucket location hint (best-effort, honored on first creation)."
  value       = { for key, bucket in cloudflare_r2_bucket.bucket : key => bucket.location }
}

output "bucket_jurisdictions" {
  description = "Map of bucket key => bucket jurisdiction."
  value       = { for key, bucket in cloudflare_r2_bucket.bucket : key => bucket.jurisdiction }
}

output "bucket_creation_dates" {
  description = "Map of bucket key => bucket creation date."
  value       = { for key, bucket in cloudflare_r2_bucket.bucket : key => bucket.creation_date }
}

output "bucket_r2_dev_domains" {
  description = "Map of bucket key => r2.dev public access domain (only for buckets with managed_domain set)."
  value       = { for key, domain in cloudflare_r2_managed_domain.managed : key => domain.domain }
}

output "custom_domain_statuses" {
  description = "Map of composite key (bucket key/domain) => { ownership, ssl } status."
  value = {
    for key, domain in cloudflare_r2_custom_domain.domain : key => {
      ownership = domain.status.ownership
      ssl       = domain.status.ssl
    }
  }
}
