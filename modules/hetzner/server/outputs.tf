output "servers" {
  description = "Map of server key => object with `id` (string of the numeric server ID, also the import ID), `name`, `server_type`, `image`, `location`, `status`, `labels`, `ipv4_address`, `ipv6_address`, `ipv6_network`, `primary_disk_size`, `delete_protection` and `rebuild_protection`."
  value = { for k, s in hcloud_server.server : k => {
    id                 = tostring(s.id)
    name               = s.name
    server_type        = s.server_type
    image              = s.image
    location           = s.location
    status             = s.status
    labels             = s.labels
    ipv4_address       = s.ipv4_address
    ipv6_address       = s.ipv6_address
    ipv6_network       = s.ipv6_network
    primary_disk_size  = s.primary_disk_size
    delete_protection  = s.delete_protection
    rebuild_protection = s.rebuild_protection
  } }
}
