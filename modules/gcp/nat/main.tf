locals {
  router_names = { for k, n in var.nats : k => try(google_compute_router.router[n.router].name, n.router) }
}

resource "google_compute_router" "router" {
  for_each = var.routers

  name        = each.value.name
  project     = each.value.project_id
  description = each.value.description
  network     = each.value.network
  region      = each.value.region

  dynamic "bgp" {
    for_each = each.value.bgp != null ? [each.value.bgp] : []

    content {
      asn                = bgp.value.asn
      advertise_mode     = bgp.value.advertise_mode
      advertised_groups  = bgp.value.advertised_groups
      keepalive_interval = bgp.value.keepalive_interval

      dynamic "advertised_ip_ranges" {
        for_each = coalesce(bgp.value.advertised_ip_ranges, [])

        content {
          range       = advertised_ip_ranges.value.range
          description = advertised_ip_ranges.value.description
        }
      }
    }
  }
}

resource "google_compute_router_nat" "nat" {
  for_each = var.nats

  name                                = each.value.name
  project                             = each.value.project_id
  region                              = each.value.region
  router                              = local.router_names[each.key]
  nat_ip_allocate_option              = each.value.nat_ip_allocate_option
  nat_ips                             = each.value.nat_ips
  source_subnetwork_ip_ranges_to_nat  = each.value.source_subnetwork_ip_ranges_to_nat
  min_ports_per_vm                    = each.value.min_ports_per_vm
  max_ports_per_vm                    = each.value.max_ports_per_vm
  enable_dynamic_port_allocation      = each.value.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = each.value.enable_endpoint_independent_mapping
  udp_idle_timeout_sec                = each.value.udp_idle_timeout_sec
  icmp_idle_timeout_sec               = each.value.icmp_idle_timeout_sec
  tcp_established_idle_timeout_sec    = each.value.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec     = each.value.tcp_transitory_idle_timeout_sec

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      enable = log_config.value.enable
      filter = log_config.value.filter
    }
  }

  dynamic "subnetwork" {
    for_each = each.value.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS" ? each.value.subnetworks : []

    content {
      name                     = subnetwork.value.name
      source_ip_ranges_to_nat  = subnetwork.value.source_ip_ranges_to_nat
      secondary_ip_range_names = contains(subnetwork.value.source_ip_ranges_to_nat, "LIST_OF_SECONDARY_IP_RANGES") ? subnetwork.value.secondary_ip_range_names : null
    }
  }
}
