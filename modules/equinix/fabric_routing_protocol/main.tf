terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = ">= 5.0.0"
    }
  }
}

# A DIRECT routing protocol must exist on a connection before the BGP
# protocol (provider docs pattern). Per-instance dynamic ordering is not
# expressible in HCL, so every BGP entry orders after every direct entry.
resource "equinix_fabric_routing_protocol" "direct" {
  for_each = var.direct_protocols

  type            = "DIRECT"
  connection_uuid = each.value.connection_uuid
  name            = each.value.name
  description     = each.value.description

  dynamic "direct_ipv4" {
    for_each = each.value.direct_ipv4 != null ? [each.value.direct_ipv4] : []

    content {
      equinix_iface_ip = direct_ipv4.value.equinix_iface_ip
    }
  }

  dynamic "direct_ipv6" {
    for_each = each.value.direct_ipv6 != null ? [each.value.direct_ipv6] : []

    content {
      equinix_iface_ip = direct_ipv6.value.equinix_iface_ip
    }
  }
}

resource "equinix_fabric_routing_protocol" "bgp" {
  for_each = var.bgp_protocols

  type                = "BGP"
  connection_uuid     = each.value.connection_uuid
  name                = each.value.name
  description         = each.value.description
  customer_asn        = each.value.customer_asn
  bgp_auth_key        = each.value.bgp_auth_key
  as_override_enabled = each.value.as_override_enabled

  dynamic "bgp_ipv4" {
    for_each = each.value.bgp_ipv4 != null ? [each.value.bgp_ipv4] : []

    content {
      customer_peer_ip          = bgp_ipv4.value.customer_peer_ip
      enabled                   = bgp_ipv4.value.enabled
      inbound_med               = bgp_ipv4.value.inbound_med
      outbound_med              = bgp_ipv4.value.outbound_med
      outbound_as_prepend_count = bgp_ipv4.value.outbound_as_prepend_count
    }
  }

  dynamic "bgp_ipv6" {
    for_each = each.value.bgp_ipv6 != null ? [each.value.bgp_ipv6] : []

    content {
      customer_peer_ip          = bgp_ipv6.value.customer_peer_ip
      enabled                   = bgp_ipv6.value.enabled
      inbound_med               = bgp_ipv6.value.inbound_med
      outbound_med              = bgp_ipv6.value.outbound_med
      outbound_as_prepend_count = bgp_ipv6.value.outbound_as_prepend_count
    }
  }

  dynamic "bfd" {
    for_each = each.value.bfd != null ? [each.value.bfd] : []

    content {
      enabled  = bfd.value.enabled
      interval = bfd.value.interval
    }
  }

  depends_on = [equinix_fabric_routing_protocol.direct]
}
