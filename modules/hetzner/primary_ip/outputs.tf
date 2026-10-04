output "primary_ips" {
  description = "Map of primary IP key => object with `id` (string of the numeric primary IP ID, also the import ID), `name`, `type`, `ip_address`, `ip_network` (only set for ipv6), `location`, `assignee_id` (server ID once assigned — reads 0 in state until a refresh after a server-side attach), `assignee_type` (`server` when assigned; unassigned IPs read back `\"unassigned\"` since 2026-08-01), `auto_delete`, `delete_protection` and `labels`."
  value = { for k, ip in hcloud_primary_ip.primary_ip : k => {
    id                = tostring(ip.id)
    name              = ip.name
    type              = ip.type
    ip_address        = ip.ip_address
    ip_network        = ip.ip_network
    location          = ip.location
    assignee_id       = ip.assignee_id
    assignee_type     = ip.assignee_type
    auto_delete       = ip.auto_delete
    delete_protection = ip.delete_protection
    labels            = ip.labels
  } }
}
