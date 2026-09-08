terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

locals {
  rules = {
    for pair in flatten([
      for group_key, group in var.security_groups : [
        for rule_key, rule in group.rules : {
          group_key = group_key
          rule_key  = rule_key
          group     = group
          rule      = rule
        }
      ]
    ]) : "${pair.group_key}.${pair.rule_key}" => pair
  }
}

resource "stackit_security_group" "security_group" {
  for_each = var.security_groups

  project_id  = each.value.project_id
  name        = each.value.name
  region      = each.value.region
  description = each.value.description
  stateful    = each.value.stateful
  labels      = each.value.labels
}

resource "stackit_security_group_rule" "rule" {
  for_each = local.rules

  project_id               = each.value.group.project_id
  region                   = each.value.group.region
  security_group_id        = stackit_security_group.security_group[each.value.group_key].security_group_id
  direction                = each.value.rule.direction
  description              = each.value.rule.description
  ether_type               = each.value.rule.ether_type
  ip_range                 = each.value.rule.ip_range
  remote_security_group_id = each.value.rule.remote_security_group_id

  protocol = (each.value.rule.protocol_name != null || each.value.rule.protocol_number != null) ? {
    name   = each.value.rule.protocol_name
    number = each.value.rule.protocol_number
  } : null

  port_range      = each.value.rule.port_range
  icmp_parameters = each.value.rule.icmp_parameters

  depends_on = [stackit_security_group.security_group]
}
