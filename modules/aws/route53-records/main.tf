locals {
  simple_records = merge([
    for zone_key, zone in var.zones : {
      for record_key, r in zone.records : "${zone_key}.${record_key}" => {
        zone_id = zone.zone_id
        name    = r.name
        type    = r.type
        ttl     = r.ttl
        records = r.records
      } if r.alias == null
    }
  ]...)

  alias_records = merge([
    for zone_key, zone in var.zones : {
      for record_key, r in zone.records : "${zone_key}.${record_key}" => {
        zone_id                      = zone.zone_id
        name                         = r.name
        type                         = r.type
        alias_zone_id                = r.alias.zone_id
        alias_name                   = r.alias.name
        alias_evaluate_target_health = lookup(r.alias, "evaluate_target_health", false)
      } if r.alias != null
    }
  ]...)
}

resource "aws_route53_record" "simple" {
  for_each = local.simple_records

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records

  lifecycle {
    precondition {
      condition     = each.value.ttl != null
      error_message = "record \"${each.key}\" is a standard record and must set ttl."
    }
  }
}

resource "aws_route53_record" "alias" {
  for_each = local.alias_records

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = each.value.alias_name
    zone_id                = each.value.alias_zone_id
    evaluate_target_health = each.value.alias_evaluate_target_health
  }

  lifecycle {
    precondition {
      condition     = contains(["A", "AAAA", "CAA"], each.value.type)
      error_message = "record \"${each.key}\": alias records support only A, AAAA and CAA types."
    }
  }
}
