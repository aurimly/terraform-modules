resource "google_compute_subnetwork" "subnet" {
  for_each = var.subnets

  name                     = each.value.name
  project                  = each.value.project_id
  description              = each.value.description
  network                  = each.value.network
  region                   = each.value.region
  ip_cidr_range            = each.value.ip_cidr_range
  purpose                  = each.value.purpose
  role                     = each.value.role
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges

    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = each.value.flow_log != null ? [each.value.flow_log] : []

    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
      metadata_fields      = log_config.value.metadata_fields
      filter_expr          = log_config.value.filter_expr
    }
  }
}
