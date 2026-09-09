locals {
  endpoints = {
    for k, ep in var.psc_endpoints : k => merge(ep, {
      address_name = coalesce(ep.address_name, "${ep.name}-ip")
    })
  }
}

resource "google_compute_address" "psc_address" {
  for_each = local.endpoints

  name         = each.value.address_name
  project      = each.value.project_id
  region       = each.value.region
  address_type = "INTERNAL"
  subnetwork   = each.value.subnetwork
  address      = each.value.address
  description  = each.value.description
  labels       = each.value.labels
}

resource "google_compute_forwarding_rule" "psc_forwarding_rule" {
  for_each = local.endpoints

  name                    = each.value.name
  project                 = each.value.project_id
  region                  = each.value.region
  network                 = each.value.network
  ip_address              = google_compute_address.psc_address[each.key].id
  target                  = each.value.target_service_attachment
  load_balancing_scheme   = ""
  allow_psc_global_access = each.value.allow_psc_global_access
  recreate_closed_psc     = each.value.recreate_closed_psc
  no_automate_dns_zone    = each.value.no_automate_dns_zone
  labels                  = each.value.labels
}
