output "network_area_regions" {
  description = "Map of network area region key => object with `region` (resolved effective region), `network_range_ids` (map of range key => network range UUID), the resolved `default_prefix_length`/`min_prefix_length`/`max_prefix_length`, and `id` (\"{organization_id},{network_area_id},{region}\", the import ID)."
  value = { for k, r in stackit_network_area_region.network_area_region : k => {
    region                = r.region
    id                    = r.id
    network_range_ids     = { for rk, prefix in var.network_area_regions[k].ipv4.network_ranges : rk => lookup({ for nr in r.ipv4.network_ranges : nr.prefix => nr.network_range_id }, prefix, null) }
    default_prefix_length = r.ipv4.default_prefix_length
    min_prefix_length     = r.ipv4.min_prefix_length
    max_prefix_length     = r.ipv4.max_prefix_length
  } }
}
