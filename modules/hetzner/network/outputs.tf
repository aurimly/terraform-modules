output "networks" {
  description = "Map of network key => object with `id` (string of the numeric network ID, also the import ID), `ip_range`, `labels`, `delete_protection` and `expose_routes_to_vswitch`."
  value = { for k, n in hcloud_network.network : k => {
    id                       = tostring(n.id)
    ip_range                 = n.ip_range
    labels                   = n.labels
    delete_protection        = n.delete_protection
    expose_routes_to_vswitch = n.expose_routes_to_vswitch
  } }
}
