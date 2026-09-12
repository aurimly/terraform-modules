output "zones" {
  description = "Map of zone key => object with `zone_id` (UUID), `primary_name_server`, `record_count`, `serial_number` (volatile — changes on every zone mutation), `state`, `visibility` and `id` (\"{project_id},{zone_id}\", the import ID)."
  value = { for k, z in stackit_dns_zone.zone : k => {
    zone_id             = z.zone_id
    primary_name_server = z.primary_name_server
    record_count        = z.record_count
    serial_number       = z.serial_number
    state               = z.state
    visibility          = z.visibility
    id                  = z.id
  } }
}
