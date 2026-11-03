locals {
  # Name tag applied only when requested; Name wins on collision
  # (consumer tags win on any other key).
  tags = { for k, e in var.vpc_endpoints :
    k => e.name == null ? e.tags : merge(e.tags, { Name = e.name })
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = var.vpc_endpoints

  vpc_id              = each.value.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.vpc_endpoint_type
  service_region      = each.value.service_region
  route_table_ids     = each.value.route_table_ids
  subnet_ids          = each.value.subnet_ids
  security_group_ids  = each.value.security_group_ids
  private_dns_enabled = each.value.private_dns_enabled
  ip_address_type     = each.value.ip_address_type

  dynamic "dns_options" {
    for_each = each.value.dns_options != null ? [each.value.dns_options] : []

    content {
      dns_record_ip_type                             = dns_options.value.dns_record_ip_type
      private_dns_only_for_inbound_resolver_endpoint = dns_options.value.private_dns_only_for_inbound_resolver_endpoint
    }
  }

  dynamic "subnet_configuration" {
    for_each = each.value.subnet_configuration != null ? each.value.subnet_configuration : []

    content {
      subnet_id = subnet_configuration.value.subnet_id
      ipv4      = subnet_configuration.value.ipv4
      ipv6      = subnet_configuration.value.ipv6
    }
  }

  auto_accept = each.value.auto_accept
  policy      = each.value.policy
  tags        = local.tags[each.key]
}
