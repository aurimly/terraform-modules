output "network_areas" {
  description = "Map of network area key => object with `network_area_id` (UUID), `project_count` (projects referencing the area) and `id` (\"{organization_id},{network_area_id}\", the import ID)."
  value = { for k, na in stackit_network_area.network_area : k => {
    network_area_id = na.network_area_id
    project_count   = na.project_count
    id              = na.id
  } }
}
