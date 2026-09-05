output "firewall_names" {
  description = "Map of rule key => firewall rule name."
  value       = { for k, f in google_compute_firewall.rules : k => f.name }
}

output "firewall_ids" {
  description = "Map of rule key => firewall rule ID (projects/{project}/global/firewalls/{name})."
  value       = { for k, f in google_compute_firewall.rules : k => f.id }
}

output "firewall_self_links" {
  description = "Map of rule key => firewall rule self link."
  value       = { for k, f in google_compute_firewall.rules : k => f.self_link }
}
