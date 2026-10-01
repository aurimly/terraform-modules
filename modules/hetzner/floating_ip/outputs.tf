output "floating_ips" {
  description = "Map of floating IP key => object with `id` (string of the numeric floating IP ID, also the import ID), `type`, `ip_address`, `ip_network` (only set for ipv6), `home_location`, `server_id`, `name`, `delete_protection` and `labels`."
  value = { for k, ip in hcloud_floating_ip.floating_ip : k => {
    id                = tostring(ip.id)
    type              = ip.type
    ip_address        = ip.ip_address
    ip_network        = ip.ip_network
    home_location     = ip.home_location
    server_id         = ip.server_id
    name              = ip.name
    delete_protection = ip.delete_protection
    labels            = ip.labels
  } }
}
