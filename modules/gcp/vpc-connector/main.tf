resource "google_vpc_access_connector" "connector" {
  for_each = var.connectors

  name            = each.value.name
  region          = each.value.region
  project         = each.value.project_id
  network         = each.value.network
  ip_cidr_range   = each.value.ip_cidr_range
  machine_type    = each.value.machine_type
  min_instances   = each.value.min_instances
  max_instances   = each.value.max_instances
  min_throughput  = each.value.min_throughput
  max_throughput  = each.value.max_throughput
  deletion_policy = each.value.deletion_policy

  dynamic "subnet" {
    for_each = each.value.subnet != null ? [each.value.subnet] : []

    content {
      name       = subnet.value.name
      project_id = subnet.value.project_id
    }
  }
}
