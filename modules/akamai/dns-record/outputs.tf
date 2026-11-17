output "records" {
  description = "Map of record key => object with `zone`, `name`, `recordtype`, `ttl` and `target`. The first three are exactly the parts of the import ID: zone#name#recordtype."
  value = { for k, r in akamai_dns_record.record : k => {
    zone       = r.zone
    name       = r.name
    recordtype = r.recordtype
    ttl        = r.ttl
    target     = r.target
  } }
}
