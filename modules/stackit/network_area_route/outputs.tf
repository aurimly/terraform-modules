output "routes" {
  description = "Map of route key => object with `network_area_route_id` (UUID), the resolved effective `region` and `id` (\"{organization_id},{network_area_id},{region},{network_area_route_id}\", the import ID)."
  value = { for k, r in stackit_network_area_route.route : k => {
    network_area_route_id = r.network_area_route_id
    region                = r.region
    id                    = r.id
  } }
}
