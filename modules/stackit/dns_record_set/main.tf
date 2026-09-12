terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_dns_record_set" "record_set" {
  for_each = var.record_sets

  project_id = each.value.project_id
  zone_id    = each.value.zone_id
  name       = each.value.name
  type       = each.value.type
  records    = each.value.records
  ttl        = each.value.ttl
  active     = each.value.active
  comment    = each.value.comment
}
