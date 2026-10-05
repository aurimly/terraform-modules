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
