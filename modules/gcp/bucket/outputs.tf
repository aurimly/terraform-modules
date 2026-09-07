output "bucket_names" {
  description = "Map of bucket key => bucket name."
  value       = { for k, b in google_storage_bucket.bucket : k => b.name }
}

output "bucket_self_links" {
  description = "Map of bucket key => bucket self link."
  value       = { for k, b in google_storage_bucket.bucket : k => b.self_link }
}

output "bucket_urls" {
  description = "Map of bucket key => gs:// URL of the bucket."
  value       = { for k, b in google_storage_bucket.bucket : k => b.url }
}

output "iam_binding_roles" {
  description = "Map of IAM binding composite key (bucket key/binding key) => role."
  value       = { for k, b in google_storage_bucket_iam_binding.binding : k => b.role }
}
