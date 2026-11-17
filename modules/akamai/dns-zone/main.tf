terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">= 12.0.0"
    }
  }
}

resource "akamai_dns_zone" "zone" {
  for_each = var.zones

  contract                 = each.value.contract
  zone                     = each.value.zone
  type                     = each.value.type
  masters                  = each.value.masters
  target                   = each.value.target
  group                    = each.value.group
  comment                  = each.value.comment
  end_customer_id          = each.value.end_customer_id
  sign_and_serve           = each.value.type == "alias" ? null : each.value.sign_and_serve
  sign_and_serve_algorithm = each.value.type == "alias" ? null : each.value.sign_and_serve_algorithm

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = each.value.type != "secondary" || length(each.value.masters) >= 1
      error_message = "zone \"${each.key}\" is secondary and must set masters."
    }

    precondition {
      condition     = each.value.type != "alias" || (each.value.target != null && length(each.value.target) >= 1)
      error_message = "zone \"${each.key}\" is an alias and must set target."
    }

    precondition {
      condition     = each.value.type == "secondary" || each.value.tsig_key == null
      error_message = "zone \"${each.key}\" is not secondary and cannot set tsig_key."
    }
  }

  dynamic "tsig_key" {
    for_each = each.value.tsig_key != null ? [each.value.tsig_key] : []

    content {
      name      = tsig_key.value.name
      algorithm = tsig_key.value.algorithm
      secret    = tsig_key.value.secret
    }
  }

  dynamic "outbound_zone_transfer" {
    for_each = each.value.outbound_zone_transfer != null ? [each.value.outbound_zone_transfer] : []

    content {
      acl            = outbound_zone_transfer.value.acl
      enabled        = outbound_zone_transfer.value.enabled
      notify_targets = outbound_zone_transfer.value.notify_targets

      dynamic "tsig_key" {
        for_each = outbound_zone_transfer.value.tsig_key != null ? [outbound_zone_transfer.value.tsig_key] : []

        content {
          name      = tsig_key.value.name
          algorithm = tsig_key.value.algorithm
          secret    = tsig_key.value.secret
        }
      }
    }
  }

  dynamic "multi_provider_dnssec" {
    for_each = each.value.multi_provider_dnssec != null ? [each.value.multi_provider_dnssec] : []

    content {
      enabled = multi_provider_dnssec.value.enabled
      webhook = multi_provider_dnssec.value.webhook
    }
  }
}
