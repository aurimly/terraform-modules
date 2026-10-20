resource "google_firestore_database" "database" {
  for_each = var.databases

  project                             = each.value.project_id
  name                                = each.value.name
  location_id                         = each.value.location_id
  type                                = each.value.type
  database_edition                    = each.value.database_edition
  concurrency_mode                    = each.value.concurrency_mode
  app_engine_integration_mode         = each.value.app_engine_integration_mode
  point_in_time_recovery_enablement   = each.value.point_in_time_recovery_enablement
  delete_protection_state             = each.value.delete_protection_state
  deletion_policy                     = each.value.deletion_policy
  tags                                = each.value.tags
  firestore_data_access_mode          = each.value.firestore_data_access_mode
  mongodb_compatible_data_access_mode = each.value.mongodb_compatible_data_access_mode
  realtime_updates_mode               = each.value.realtime_updates_mode

  dynamic "cmek_config" {
    for_each = each.value.cmek_config != null ? [each.value.cmek_config] : []

    content {
      kms_key_name = cmek_config.value.kms_key_name
    }
  }
}
