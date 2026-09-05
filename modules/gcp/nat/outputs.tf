output "nat_names" {
  description = "Map of NAT key => Cloud NAT gateway name."
  value       = { for k, n in google_compute_router_nat.nat : k => n.name }
}

output "nat_ids" {
  description = "Map of NAT key => Cloud NAT gateway ID ({{project}}/{{region}}/{{router}}/{{name}})."
  value       = { for k, n in google_compute_router_nat.nat : k => n.id }
}

output "router_names" {
  description = "Map of router key => created Cloud Router name."
  value       = { for k, r in google_compute_router.router : k => r.name }
}

output "router_self_links" {
  description = "Map of router key => created Cloud Router self link."
  value       = { for k, r in google_compute_router.router : k => r.self_link }
}
