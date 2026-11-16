output "custom_hostname_ids" {
  description = "Map of key => custom hostname ID. The import identifier for an entry is <zone_id>/<this ID>."
  value       = { for key, hostname in cloudflare_custom_hostname.custom_hostname : key => hostname.id }
}

output "custom_hostname_statuses" {
  description = "Map of key => activation status (advisory only — the activation lifecycle settles outside Terraform, so plans may show this as drift)."
  value       = { for key, hostname in cloudflare_custom_hostname.custom_hostname : key => hostname.status }
}

output "ownership_verifications" {
  description = "Map of key => ownership verification ({type, name, value}) — the TXT record the consumer must place (e.g. via modules/cloudflare/dns-records) to activate the custom hostname. Entries may be null until the API returns the verification data."
  value       = { for key, hostname in cloudflare_custom_hostname.custom_hostname : key => hostname.ownership_verification }
}

output "fallback_origin_status" {
  description = "Fallback origin activation status, or null when no fallback origin is configured (advisory only — creation settles asynchronously outside Terraform)."
  value       = var.fallback_origin != null ? cloudflare_custom_hostname_fallback_origin.fallback_origin["1"].status : null
}

output "fallback_origin_errors" {
  description = "Fallback origin activation errors, or null when no fallback origin is configured."
  value       = var.fallback_origin != null ? cloudflare_custom_hostname_fallback_origin.fallback_origin["1"].errors : null
}
