resource "google_logging_project_sink" "sink" {
  for_each = var.sinks

  name                   = each.value.name
  destination            = each.value.destination
  filter                 = each.value.filter
  description            = each.value.description
  disabled               = each.value.disabled
  unique_writer_identity = each.value.unique_writer_identity
  project                = each.value.project_id
  deletion_policy        = each.value.deletion_policy

  dynamic "bigquery_options" {
    for_each = each.value.bigquery_options != null ? [each.value.bigquery_options] : []

    content {
      use_partitioned_tables = bigquery_options.value.use_partitioned_tables
    }
  }

  dynamic "exclusions" {
    for_each = each.value.exclusions

    content {
      name        = exclusions.value.name
      description = exclusions.value.description
      filter      = exclusions.value.filter
      disabled    = exclusions.value.disabled
    }
  }
}
