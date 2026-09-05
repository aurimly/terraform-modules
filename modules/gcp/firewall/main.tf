resource "google_compute_firewall" "rules" {
  for_each = var.firewalls

  name                    = each.value.name
  project                 = each.value.project_id
  description             = each.value.description
  network                 = each.value.network
  direction               = each.value.direction
  priority                = each.value.priority
  disabled                = each.value.disabled
  source_ranges           = each.value.source_ranges
  destination_ranges      = each.value.destination_ranges
  source_tags             = each.value.source_tags
  source_service_accounts = each.value.source_service_accounts
  target_tags             = each.value.target_tags
  target_service_accounts = each.value.target_service_accounts

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      metadata = log_config.value.metadata
    }
  }

  dynamic "allow" {
    for_each = each.value.allow

    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny

    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}
