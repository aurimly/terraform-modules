output "record_sets" {
  description = "Map of record set key => object with `record_set_id` (UUID), `fqdn`, `state`, `error` (populated when create/update/delete failed) and `id` (\"{project_id},{zone_id},{record_set_id}\", the import ID)."
  value = { for k, r in stackit_dns_record_set.record_set : k => {
    record_set_id = r.record_set_id
    fqdn          = r.fqdn
    state         = r.state
    error         = r.error
    id            = r.id
  } }
}
