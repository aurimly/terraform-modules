output "address_names" {
  description = "Map of address key => address name."
  value       = merge({ for k, a in google_compute_address.regional : k => a.name }, { for k, a in google_compute_global_address.global : k => a.name })
}

output "address_ips" {
  description = "Map of address key => reserved IP (or the first IP of a reserved range) as a string."
  value       = merge({ for k, a in google_compute_address.regional : k => a.address }, { for k, a in google_compute_global_address.global : k => a.address })
}

output "address_self_links" {
  description = "Map of address key => address self link; the link form reveals whether an entry produced a regional or global address."
  value       = merge({ for k, a in google_compute_address.regional : k => a.self_link }, { for k, a in google_compute_global_address.global : k => a.self_link })
}
