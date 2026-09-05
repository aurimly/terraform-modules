locals {
  global_keys = { for k, a in var.addresses : k => a if a.global_ip || (a.purpose != null && contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose)) }

  regional_keys = { for k, a in var.addresses : k => a if !a.global_ip && !(a.purpose != null && contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose)) }
}

resource "google_compute_address" "regional" {
  for_each = local.regional_keys

  name          = each.value.name
  project       = each.value.project_id
  description   = each.value.description
  region        = each.value.region
  address       = each.value.address
  address_type  = each.value.address_type
  purpose       = each.value.purpose
  network_tier  = each.value.network_tier
  subnetwork    = each.value.subnetwork
  network       = each.value.network
  prefix_length = each.value.prefix_length
  ip_version    = each.value.ip_version
}

resource "google_compute_global_address" "global" {
  for_each = local.global_keys

  name          = each.value.name
  project       = each.value.project_id
  description   = each.value.description
  address       = each.value.address
  address_type  = each.value.address_type
  purpose       = each.value.purpose
  network       = each.value.network
  prefix_length = each.value.prefix_length
  ip_version    = each.value.ip_version
}
