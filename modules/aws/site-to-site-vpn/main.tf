locals {
  connection_customer_gateway_ids = {
    for k, c in var.connections : k => try(aws_customer_gateway.gateway[c.customer_gateway].id, c.customer_gateway)
  }

  connection_vpn_gateway_ids = {
    for k, c in var.connections : k => c.transit_gateway_id != null ? null : try(aws_vpn_gateway.vpn_gateway[c.vpn_gateway].id, c.vpn_gateway)
  }
}

resource "aws_vpn_gateway" "vpn_gateway" {
  for_each = var.vpn_gateways

  vpc_id            = each.value.vpc_id
  availability_zone = each.value.availability_zone
  amazon_side_asn   = each.value.amazon_side_asn

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_customer_gateway" "gateway" {
  for_each = var.customer_gateways

  bgp_asn          = each.value.bgp_asn < 2147483648 ? each.value.bgp_asn : null
  bgp_asn_extended = each.value.bgp_asn >= 2147483648 ? each.value.bgp_asn : null
  certificate_arn  = each.value.certificate_arn
  device_name      = each.value.device_name
  ip_address       = each.value.ip_address
  type             = "ipsec.1"

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_vpn_connection" "connection" {
  for_each = var.connections

  customer_gateway_id = local.connection_customer_gateway_ids[each.key]
  type                = "ipsec.1"

  vpn_gateway_id     = local.connection_vpn_gateway_ids[each.key]
  transit_gateway_id = each.value.transit_gateway_id

  static_routes_only       = each.value.static_routes_only
  enable_acceleration      = each.value.enable_acceleration
  tunnel_inside_ip_version = each.value.tunnel_inside_ip_version

  local_ipv4_network_cidr  = each.value.local_ipv4_network_cidr
  remote_ipv4_network_cidr = each.value.remote_ipv4_network_cidr

  tunnel1_inside_cidr   = each.value.tunnel1.inside_cidr
  tunnel2_inside_cidr   = each.value.tunnel2.inside_cidr
  tunnel1_preshared_key = each.value.tunnel1.pre_shared_key
  tunnel2_preshared_key = each.value.tunnel2.pre_shared_key

  tunnel1_ike_versions = each.value.tunnel1.ike_versions
  tunnel2_ike_versions = each.value.tunnel2.ike_versions

  tunnel1_dpd_timeout_action  = each.value.tunnel1.dpd_timeout_action
  tunnel2_dpd_timeout_action  = each.value.tunnel2.dpd_timeout_action
  tunnel1_dpd_timeout_seconds = each.value.tunnel1.dpd_timeout_seconds
  tunnel2_dpd_timeout_seconds = each.value.tunnel2.dpd_timeout_seconds

  tunnel1_phase1_dh_group_numbers      = each.value.tunnel1.phase1_dh_group_numbers
  tunnel2_phase1_dh_group_numbers      = each.value.tunnel2.phase1_dh_group_numbers
  tunnel1_phase1_encryption_algorithms = each.value.tunnel1.phase1_encryption_algorithms
  tunnel2_phase1_encryption_algorithms = each.value.tunnel2.phase1_encryption_algorithms
  tunnel1_phase1_integrity_algorithms  = each.value.tunnel1.phase1_integrity_algorithms
  tunnel2_phase1_integrity_algorithms  = each.value.tunnel2.phase1_integrity_algorithms
  tunnel1_phase1_lifetime_seconds      = each.value.tunnel1.phase1_lifetime_seconds
  tunnel2_phase1_lifetime_seconds      = each.value.tunnel2.phase1_lifetime_seconds
  tunnel1_phase2_dh_group_numbers      = each.value.tunnel1.phase2_dh_group_numbers
  tunnel2_phase2_dh_group_numbers      = each.value.tunnel2.phase2_dh_group_numbers
  tunnel1_phase2_encryption_algorithms = each.value.tunnel1.phase2_encryption_algorithms
  tunnel2_phase2_encryption_algorithms = each.value.tunnel2.phase2_encryption_algorithms
  tunnel1_phase2_integrity_algorithms  = each.value.tunnel1.phase2_integrity_algorithms
  tunnel2_phase2_integrity_algorithms  = each.value.tunnel2.phase2_integrity_algorithms
  tunnel1_phase2_lifetime_seconds      = each.value.tunnel1.phase2_lifetime_seconds
  tunnel2_phase2_lifetime_seconds      = each.value.tunnel2.phase2_lifetime_seconds

  tunnel1_rekey_fuzz_percentage     = each.value.tunnel1.rekey_fuzz_percentage
  tunnel2_rekey_fuzz_percentage     = each.value.tunnel2.rekey_fuzz_percentage
  tunnel1_rekey_margin_time_seconds = each.value.tunnel1.rekey_margin_time_seconds
  tunnel2_rekey_margin_time_seconds = each.value.tunnel2.rekey_margin_time_seconds
  tunnel1_replay_window_size        = each.value.tunnel1.replay_window_size
  tunnel2_replay_window_size        = each.value.tunnel2.replay_window_size

  tunnel1_startup_action = each.value.tunnel1.startup_action
  tunnel2_startup_action = each.value.tunnel2.startup_action

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_vpn_connection_route" "route" {
  for_each = { for r in flatten([
    for ck, c in var.connections : [
      for dest in c.static_routes : {
        connection_key         = ck
        destination_cidr_block = dest
      }
    ]
  ]) : "${r.connection_key}-${r.destination_cidr_block}" => r }

  vpn_connection_id      = aws_vpn_connection.connection[each.value.connection_key].id
  destination_cidr_block = each.value.destination_cidr_block
}
