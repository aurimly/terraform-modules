output "records" {
  description = "Map of record key => object with `zone`, `name`, `type`, `value` and `comment`. The first four are exactly the identity attributes required for import (import is identity-only — the resource has no ID)."
  value = { for k, r in hcloud_zone_record.record : k => {
    zone    = r.zone
    name    = r.name
    type    = r.type
    value   = r.value
    comment = r.comment
  } }
}
