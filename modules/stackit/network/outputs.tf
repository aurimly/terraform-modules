output "networks" {
  description = "Map of network key => object with `network_id` (UUID), `ipv4_prefixes`, `ipv6_prefixes`, `public_ip` (the network's public IP, if any) and `id` (\"{project_id},{region},{network_id}\", the import ID)."
  value = { for k, n in stackit_network.network : k => {
    network_id    = n.network_id
    ipv4_prefixes = n.ipv4_prefixes
    ipv6_prefixes = n.ipv6_prefixes
    public_ip     = n.public_ip
    id            = n.id
  } }
}
