output "network_interfaces" {
  description = "Map of network interface key => object with `network_interface_id` (UUID; feed into `stackit/server` `network_interface_ids` or `stackit/public_ip` `network_interface_id`), `ipv4` (assigned address), `mac`, `device`, `type` and `id` (\"{project_id},{region},{network_id},{network_interface_id}\", the import ID)."
  value = { for k, ni in stackit_network_interface.network_interface : k => {
    network_interface_id = ni.network_interface_id
    ipv4                 = ni.ipv4
    mac                  = ni.mac
    device               = ni.device
    type                 = ni.type
    id                   = ni.id
  } }
}
