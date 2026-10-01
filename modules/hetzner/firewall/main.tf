terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_firewall" "firewall" {
  for_each = var.firewalls

  name   = each.value.name
  labels = each.value.labels

  dynamic "rule" {
    for_each = each.value.rules

    content {
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = rule.value.port
      source_ips      = rule.value.source_ips
      destination_ips = rule.value.destination_ips
      description     = rule.value.description
    }
  }

  dynamic "apply_to" {
    for_each = each.value.apply_to

    content {
      server         = apply_to.value.server
      label_selector = apply_to.value.label_selector
    }
  }
}
