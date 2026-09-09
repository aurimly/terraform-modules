locals {
  allocate_ranges = {
    for b in flatten([
      for conn_key, conn in var.connections : [
        for range_key, range in conn.allocate_ranges : {
          conn_key  = conn_key
          range_key = range_key
          conn      = conn
          range     = range
        }
      ]
    ]) : "${b.conn_key}/${b.range_key}" => b
  }

  connection_ranges = {
    for conn_key, conn in var.connections : conn_key => distinct(concat(
      conn.reserved_peering_ranges,
      [for range_key, range in conn.allocate_ranges : range.name]
    ))
  }

  routes_configs = {
    for conn_key, conn in var.connections : conn_key => conn
    if conn.routes_config != null
  }
}

resource "google_compute_global_address" "range" {
  for_each = local.allocate_ranges

  name          = each.value.range.name
  project       = each.value.range.project_id
  description   = each.value.range.description
  address       = each.value.range.address
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = each.value.range.prefix_length
  network       = each.value.conn.network
  labels        = each.value.range.labels
}

resource "google_service_networking_connection" "connection" {
  for_each = var.connections

  network                 = each.value.network
  service                 = each.value.service
  reserved_peering_ranges = local.connection_ranges[each.key]
  deletion_policy         = each.value.deletion_policy

  depends_on = [google_compute_global_address.range]
}

resource "google_compute_network_peering_routes_config" "routes" {
  for_each = local.routes_configs

  peering = google_service_networking_connection.connection[each.key].peering
  network = each.value.network

  import_custom_routes                = each.value.routes_config.import_custom_routes
  export_custom_routes                = each.value.routes_config.export_custom_routes
  import_subnet_routes_with_public_ip = each.value.routes_config.import_subnet_routes_with_public_ip
  export_subnet_routes_with_public_ip = each.value.routes_config.export_subnet_routes_with_public_ip

  depends_on = [google_service_networking_connection.connection]
}
