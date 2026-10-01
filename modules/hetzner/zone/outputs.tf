output "zones" {
  description = "Map of zone key => object with `id` (string of the numeric zone ID — also the import ID, which alternatively accepts the zone name), `authoritative_nameservers` (assigned Hetzner nameservers), `registrar` and `delete_protection`."
  value = { for k, z in hcloud_zone.zone : k => {
    id                        = tostring(z.id)
    authoritative_nameservers = z.authoritative_nameservers.assigned
    registrar                 = z.registrar
    delete_protection         = z.delete_protection
  } }
}
