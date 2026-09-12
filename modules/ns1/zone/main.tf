terraform {
  required_providers {
    ns1 = {
      source  = "ns1-terraform/ns1"
      version = ">= 2.0.0"
    }
  }
}

locals {
  custom_primaries = flatten([
    for zone_name, zone in var.zones : [
      for domain in zone.custom_primaries : {
        zone   = zone_name
        domain = domain
      }
    ]
  ])
}

resource "ns1_zone" "zone" {
  for_each = var.zones

  zone = each.key

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = (each.value.primary != null ? 1 : 0) + (each.value.additional_primaries != null ? 1 : 0) + (length(each.value.secondaries) > 0 ? 1 : 0) <= 1
      error_message = "zone \"${each.key}\" must set at most one of primary, additional_primaries, secondaries."
    }
  }

  ttl                    = each.value.ttl
  tags                   = each.value.tags
  link                   = each.value.link
  primary                = each.value.primary
  primary_port           = each.value.primary_port
  primary_network        = each.value.primary_network
  additional_primaries   = each.value.additional_primaries
  additional_ports       = each.value.additional_ports
  additional_networks    = each.value.additional_networks
  additional_notify_only = each.value.additional_notify_only
  hostmaster             = each.value.hostmaster
  refresh                = each.value.refresh
  retry                  = each.value.retry
  expiry                 = each.value.expiry
  nx_ttl                 = each.value.nx_ttl
  dnssec                 = each.value.dnssec
  autogenerate_ns_record = each.value.autogenerate_ns_record
  networks               = each.value.networks
  tsig                   = each.value.tsig

  dynamic "secondaries" {
    for_each = each.value.secondaries

    content {
      ip     = secondaries.value.ip
      port   = secondaries.value.port
      notify = secondaries.value.notify
    }
  }
}

resource "ns1_record" "primary_ns" {
  for_each = {
    for cp in local.custom_primaries : "${cp.zone}/${cp.domain}" => cp
  }

  zone   = each.value.zone
  domain = each.value.domain
  type   = "NS"
  ttl    = var.zones[each.value.zone].ttl
}
