terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_security_group_rule" "security_group_rule" {
  for_each = var.security_group_rules

  project_id               = each.value.project_id
  region                   = each.value.region
  security_group_id        = each.value.security_group_id
  direction                = each.value.direction
  description              = each.value.description
  ether_type               = each.value.ether_type
  ip_range                 = each.value.ip_range
  remote_security_group_id = each.value.remote_security_group_id

  protocol = (each.value.protocol_name != null || each.value.protocol_number != null) ? {
    name   = each.value.protocol_name
    number = each.value.protocol_number
  } : null

  port_range      = each.value.port_range
  icmp_parameters = each.value.icmp_parameters
}
