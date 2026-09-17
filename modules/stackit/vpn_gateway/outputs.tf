output "gateways" {
  description = "Map of gateway key => object with `gateway_id` (UUID) and `id` (\"{project_id},{region},{gateway_id}\", the import ID). Pair with stackit/vpn_connection via `gateway_id`."
  value = { for k, g in stackit_vpn_gateway.gateway : k => {
    gateway_id = g.gateway_id
    id         = g.id
  } }
}
