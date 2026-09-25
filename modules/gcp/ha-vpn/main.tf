locals {
  tunnel_router_names = { for k, t in var.tunnels : k => try(google_compute_router.router[t.router].name, t.router) }
}

resource "google_compute_router" "router" {
  for_each = var.routers

  name    = each.value.name
  project = each.value.project_id
  network = each.value.network
  region  = each.value.region

  bgp {
    asn                = each.value.bgp.asn
    advertise_mode     = each.value.bgp.advertise_mode
    advertised_groups  = each.value.bgp.advertised_groups
    keepalive_interval = each.value.bgp.keepalive_interval

    dynamic "advertised_ip_ranges" {
      for_each = coalesce(each.value.bgp.advertised_ip_ranges, [])

      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

resource "google_compute_ha_vpn_gateway" "gateway" {
  for_each = var.gateways

  name       = each.value.name
  network    = each.value.network
  region     = each.value.region
  project    = each.value.project_id
  stack_type = each.value.stack_type
  labels     = each.value.labels
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  for_each = var.external_gateways

  name            = each.value.name
  project         = each.value.project_id
  description     = each.value.description
  redundancy_type = each.value.redundancy_type

  dynamic "interface" {
    for_each = each.value.interfaces

    content {
      id         = interface.value.id
      ip_address = interface.value.ip_address
    }
  }
}

resource "google_compute_vpn_tunnel" "tunnel" {
  for_each = var.tunnels

  name        = each.value.name
  description = each.value.description
  project     = each.value.project_id
  region      = each.value.region
  labels      = each.value.labels

  vpn_gateway           = try(google_compute_ha_vpn_gateway.gateway[each.value.gateway].self_link, each.value.gateway)
  vpn_gateway_interface = each.value.vpn_gateway_interface

  peer_external_gateway = each.value.peer_external_gateway == null ? null : try(
    google_compute_external_vpn_gateway.external_gateway[each.value.peer_external_gateway].self_link,
    each.value.peer_external_gateway,
  )
  peer_external_gateway_interface = each.value.peer_external_gateway == null ? null : each.value.peer_external_gateway_interface
  peer_ip                         = each.value.peer_ip

  router                   = local.tunnel_router_names[each.key]
  shared_secret            = each.value.shared_secret
  shared_secret_wo         = each.value.shared_secret_wo
  shared_secret_wo_version = each.value.shared_secret_wo_version

  ike_version             = each.value.ike_version
  local_traffic_selector  = each.value.local_traffic_selector
  remote_traffic_selector = each.value.remote_traffic_selector
}

resource "google_compute_router_interface" "interface" {
  for_each = { for k, s in var.bgp_sessions : k => s }

  name       = each.value.name
  router     = local.tunnel_router_names[each.value.tunnel]
  region     = var.tunnels[each.value.tunnel].region
  project    = try(google_compute_router.router[var.tunnels[each.value.tunnel].router].project, null)
  ip_range   = each.value.ip_range
  vpn_tunnel = var.tunnels[each.value.tunnel].name

  depends_on = [google_compute_vpn_tunnel.tunnel]
}

resource "google_compute_router_peer" "peer" {
  for_each = { for k, s in var.bgp_sessions : k => s }

  name      = each.value.name
  router    = local.tunnel_router_names[each.value.tunnel]
  region    = var.tunnels[each.value.tunnel].region
  project   = try(google_compute_router.router[var.tunnels[each.value.tunnel].router].project, null)
  interface = each.value.name

  peer_asn        = each.value.peer_asn
  peer_ip_address = each.value.peer_ip_address

  advertised_route_priority = each.value.advertised_route_priority

  dynamic "md5_authentication_key" {
    for_each = each.value.md5_authentication_key != null ? [each.value.md5_authentication_key] : []

    content {
      name = md5_authentication_key.value.name
      key  = md5_authentication_key.value.key
    }
  }

  depends_on = [google_compute_router_interface.interface]
}
