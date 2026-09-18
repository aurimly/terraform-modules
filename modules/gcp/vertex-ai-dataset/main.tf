resource "google_vertex_ai_dataset" "dataset" {
  for_each = var.datasets

  display_name        = each.value.display_name
  metadata_schema_uri = each.value.metadata_schema_uri
  region              = each.value.region
  project             = each.value.project_id
  labels              = each.value.labels
  deletion_policy     = each.value.deletion_policy

  dynamic "encryption_spec" {
    for_each = each.value.encryption_spec != null ? [each.value.encryption_spec] : []

    content {
      kms_key_name = encryption_spec.value.kms_key_name
    }
  }
}
