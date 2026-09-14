resource "google_monitoring_notification_channel" "channel" {
  for_each = var.channels

  type         = each.value.type
  project      = each.value.project_id
  description  = each.value.description
  display_name = each.value.display_name
  enabled      = each.value.enabled
  force_delete = each.value.force_delete
  user_labels  = each.value.user_labels
  labels       = each.value.labels

  dynamic "sensitive_labels" {
    for_each = each.value.sensitive_labels != null ? [each.value.sensitive_labels] : []

    content {
      auth_token             = sensitive_labels.value.auth_token
      password               = sensitive_labels.value.password
      service_key            = sensitive_labels.value.service_key
      auth_token_wo          = sensitive_labels.value.auth_token_wo
      auth_token_wo_version  = sensitive_labels.value.auth_token_wo_version
      password_wo            = sensitive_labels.value.password_wo
      password_wo_version    = sensitive_labels.value.password_wo_version
      service_key_wo         = sensitive_labels.value.service_key_wo
      service_key_wo_version = sensitive_labels.value.service_key_wo_version
    }
  }
}
