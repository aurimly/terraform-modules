locals {
  rule_endpoint_ids = {
    for k, r in var.rules : k => r.resolver_endpoint_id != null ? r.resolver_endpoint_id : try(aws_route53_resolver_endpoint.endpoint[r.endpoint_key].id, null)
  }
}

resource "aws_route53_resolver_endpoint" "endpoint" {
  for_each = var.endpoints

  name                               = each.value.name
  direction                          = each.value.direction
  security_group_ids                 = each.value.security_group_ids
  protocols                          = each.value.protocols
  resolver_endpoint_type             = each.value.resolver_endpoint_type
  rni_enhanced_metrics_enabled       = each.value.rni_enhanced_metrics_enabled
  target_name_server_metrics_enabled = each.value.target_name_server_metrics_enabled

  dynamic "ip_address" {
    for_each = each.value.ip_addresses

    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
      ipv6      = ip_address.value.ipv6
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_route53_resolver_rule" "rule" {
  for_each = var.rules

  domain_name          = each.value.domain_name
  rule_type            = each.value.rule_type
  resolver_endpoint_id = local.rule_endpoint_ids[each.key]
  name                 = each.value.name

  dynamic "target_ip" {
    for_each = each.value.target_ips != null ? each.value.target_ips : []

    content {
      ip       = target_ip.value.ip
      ipv6     = target_ip.value.ipv6
      port     = target_ip.value.port
      protocol = target_ip.value.protocol
    }
  }

  tags = merge(each.value.tags, { Name = coalesce(each.value.name, each.value.domain_name) })

  lifecycle {
    precondition {
      condition     = each.value.endpoint_key == null || contains(keys(var.endpoints), each.value.endpoint_key)
      error_message = "rule \"${each.key}\": endpoint_key is not a key of the endpoints map."
    }
  }
}

resource "aws_route53_resolver_rule_association" "association" {
  for_each = var.associations

  resolver_rule_id = each.value.rule_key != null ? aws_route53_resolver_rule.rule[each.value.rule_key].id : each.value.rule_id
  vpc_id           = each.value.vpc_id
  name             = each.value.name

  lifecycle {
    precondition {
      condition     = each.value.rule_key == null || contains(keys(var.rules), each.value.rule_key)
      error_message = "association \"${each.key}\": rule_key is not a key of the rules map."
    }
  }
}

resource "aws_route53_resolver_dnssec_config" "dnssec_config" {
  for_each = var.dnssec_configs

  resource_id = each.value.vpc_id
}
