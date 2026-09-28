locals {
  route_table_gateway_ids = {
    for k, v in var.route_tables : k => v.gateway_key != null ? try(aws_ec2_transit_gateway.gw[v.gateway_key].id, v.gateway_id) : v.gateway_id
  }

  attachment_gateway_ids = {
    for k, v in var.vpc_attachments : k => v.gateway_key != null ? try(aws_ec2_transit_gateway.gw[v.gateway_key].id, v.transit_gateway_id) : v.transit_gateway_id
  }

  peering_gateway_ids = {
    for k, v in var.peerings : k => v.gateway_key != null ? try(aws_ec2_transit_gateway.gw[v.gateway_key].id, v.transit_gateway_id) : v.transit_gateway_id
  }

  route_route_table_ids = {
    for k, v in var.routes : k => v.route_table_key != null ? try(aws_ec2_transit_gateway_route_table.rt[v.route_table_key].id, v.route_table_id) : v.route_table_id
  }

  association_route_table_ids = {
    for k, v in var.associations : k => v.route_table_key != null ? try(aws_ec2_transit_gateway_route_table.rt[v.route_table_key].id, v.route_table_id) : v.route_table_id
  }

  propagation_route_table_ids = {
    for k, v in var.propagations : k => v.route_table_key != null ? try(aws_ec2_transit_gateway_route_table.rt[v.route_table_key].id, v.route_table_id) : v.route_table_id
  }

  route_attachment_ids = {
    for k, v in var.routes : k => v.attachment_key != null ? try(aws_ec2_transit_gateway_vpc_attachment.vpc[v.attachment_key].id, v.transit_gateway_attachment_id) : v.transit_gateway_attachment_id
  }

  association_attachment_ids = {
    for k, v in var.associations : k => v.attachment_key != null ? try(aws_ec2_transit_gateway_vpc_attachment.vpc[v.attachment_key].id, v.transit_gateway_attachment_id) : v.transit_gateway_attachment_id
  }

  propagation_attachment_ids = {
    for k, v in var.propagations : k => v.attachment_key != null ? try(aws_ec2_transit_gateway_vpc_attachment.vpc[v.attachment_key].id, v.transit_gateway_attachment_id) : v.transit_gateway_attachment_id
  }

  attachment_accepters = { for k, v in var.vpc_attachments : k => v if v.accept }
}

resource "aws_ec2_transit_gateway" "gw" {
  for_each = var.gateways

  description                        = each.value.description
  amazon_side_asn                    = each.value.amazon_side_asn
  auto_accept_shared_attachments     = each.value.auto_accept_shared_attachments
  default_route_table_association    = each.value.default_route_table_association
  default_route_table_propagation    = each.value.default_route_table_propagation
  dns_support                        = each.value.dns_support
  vpn_ecmp_support                   = each.value.vpn_ecmp_support
  multicast_support                  = each.value.multicast_support
  security_group_referencing_support = each.value.security_group_referencing_support
  encryption_support                 = each.value.encryption_support
  transit_gateway_cidr_blocks        = each.value.transit_gateway_cidr_blocks

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_ec2_transit_gateway_route_table" "rt" {
  for_each = var.route_tables

  transit_gateway_id = local.route_table_gateway_ids[each.key]

  tags = merge(each.value.tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition     = each.value.gateway_key == null || contains(keys(var.gateways), each.value.gateway_key)
      error_message = "route table \"${each.key}\": gateway_key is not a key of the gateways map."
    }
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc" {
  for_each = var.vpc_attachments

  transit_gateway_id     = local.attachment_gateway_ids[each.key]
  vpc_id                 = each.value.vpc_id
  subnet_ids             = each.value.subnet_ids
  dns_support            = each.value.dns_support
  ipv6_support           = each.value.ipv6_support
  appliance_mode_support = each.value.appliance_mode_support

  security_group_referencing_support              = each.value.security_group_referencing_support
  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = each.value.transit_gateway_default_route_table_propagation

  tags = merge(each.value.tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition     = each.value.gateway_key == null || contains(keys(var.gateways), each.value.gateway_key)
      error_message = "VPC attachment \"${each.key}\": gateway_key is not a key of the gateways map."
    }
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "accepter" {
  for_each = local.attachment_accepters

  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.vpc[each.key].id

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_ec2_transit_gateway_peering_attachment" "peering" {
  for_each = var.peerings

  transit_gateway_id      = local.peering_gateway_ids[each.key]
  peer_transit_gateway_id = each.value.peer_transit_gateway_id
  peer_region             = each.value.peer_region
  peer_account_id         = each.value.peer_account_id

  dynamic "options" {
    for_each = each.value.options != null ? [each.value.options] : []

    content {
      dynamic_routing = options.value.dynamic_routing
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition     = each.value.gateway_key == null || contains(keys(var.gateways), each.value.gateway_key)
      error_message = "peering attachment \"${each.key}\": gateway_key is not a key of the gateways map."
    }
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "peering_accepter" {
  for_each = var.peering_accepters

  transit_gateway_attachment_id = each.value.transit_gateway_attachment_id

  tags = merge(each.value.tags, each.value.name != null ? { Name = each.value.name } : {})
}

resource "aws_ec2_transit_gateway_route" "route" {
  for_each = var.routes

  transit_gateway_route_table_id = local.route_route_table_ids[each.key]
  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_attachment_id  = local.route_attachment_ids[each.key]
  blackhole                      = each.value.blackhole

  lifecycle {
    precondition {
      condition     = each.value.route_table_key == null || contains(keys(var.route_tables), each.value.route_table_key)
      error_message = "route \"${each.key}\": route_table_key is not a key of the route_tables map."
    }

    precondition {
      condition     = each.value.attachment_key == null || contains(keys(var.vpc_attachments), each.value.attachment_key)
      error_message = "route \"${each.key}\": attachment_key is not a key of the vpc_attachments map."
    }
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "association" {
  for_each = var.associations

  transit_gateway_route_table_id = local.association_route_table_ids[each.key]
  transit_gateway_attachment_id  = local.association_attachment_ids[each.key]
  replace_existing_association   = each.value.replace_existing_association

  lifecycle {
    precondition {
      condition     = each.value.route_table_key == null || contains(keys(var.route_tables), each.value.route_table_key)
      error_message = "association \"${each.key}\": route_table_key is not a key of the route_tables map."
    }

    precondition {
      condition     = each.value.attachment_key == null || contains(keys(var.vpc_attachments), each.value.attachment_key)
      error_message = "association \"${each.key}\": attachment_key is not a key of the vpc_attachments map."
    }
  }
}

resource "aws_ec2_transit_gateway_route_table_propagation" "propagation" {
  for_each = var.propagations

  transit_gateway_route_table_id = local.propagation_route_table_ids[each.key]
  transit_gateway_attachment_id  = local.propagation_attachment_ids[each.key]

  lifecycle {
    precondition {
      condition     = each.value.route_table_key == null || contains(keys(var.route_tables), each.value.route_table_key)
      error_message = "propagation \"${each.key}\": route_table_key is not a key of the route_tables map."
    }

    precondition {
      condition     = each.value.attachment_key == null || contains(keys(var.vpc_attachments), each.value.attachment_key)
      error_message = "propagation \"${each.key}\": attachment_key is not a key of the vpc_attachments map."
    }
  }
}
