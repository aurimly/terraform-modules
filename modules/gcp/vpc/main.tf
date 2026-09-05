resource "google_compute_network" "network" {
  for_each = var.networks

  name                            = each.value.name
  project                         = each.value.project_id
  description                     = each.value.description
  auto_create_subnetworks         = each.value.auto_create_subnetworks
  routing_mode                    = each.value.routing_mode
  delete_default_routes_on_create = each.value.delete_default_routes_on_create
  mtu                             = each.value.mtu
}
