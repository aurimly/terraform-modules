terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">= 12.0.0"
    }
  }
}

resource "akamai_property" "property" {
  for_each = var.properties

  name          = each.value.name
  contract_id   = each.value.contract_id
  group_id      = each.value.group_id
  product_id    = each.value.product_id
  rule_format   = each.value.rule_format
  rules         = each.value.rules
  version_notes = each.value.version_notes

  dynamic "hostnames" {
    for_each = each.value.hostnames

    content {
      cname_from             = hostnames.value.cname_from
      cname_to               = hostnames.value.cname_to
      cert_provisioning_type = hostnames.value.cert_provisioning_type
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "akamai_property_activation" "activation" {
  for_each = { for k, v in var.properties : k => v if v.activation != null }

  property_id                    = akamai_property.property[each.key].id
  version                        = akamai_property.property[each.key].latest_version
  contact                        = each.value.activation.contact
  network                        = each.value.activation.network
  note                           = each.value.activation.note
  auto_acknowledge_rule_warnings = each.value.activation.auto_acknowledge_rule_warnings
}
