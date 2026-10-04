output "rdns_entries" {
  description = "Map of rDNS entry key => object with `id` (composite string `$PREFIX-$RESOURCE_ID-$IP_ADDRESS`, also the import ID; prefixes `s` server, `p` primary IP, `f` floating IP, `l` load balancer), `ip_address`, `dns_ptr`, and the four target IDs (exactly one non-null)."
  value = { for k, entry in hcloud_rdns.rdns : k => {
    id               = entry.id
    ip_address       = entry.ip_address
    dns_ptr          = entry.dns_ptr
    server_id        = entry.server_id
    primary_ip_id    = entry.primary_ip_id
    floating_ip_id   = entry.floating_ip_id
    load_balancer_id = entry.load_balancer_id
  } }
}
