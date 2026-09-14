resource "google_workflows_workflow" "workflow" {
  for_each = var.workflows

  name                    = each.value.name
  region                  = each.value.region
  project                 = each.value.project_id
  description             = each.value.description
  service_account         = each.value.service_account
  crypto_key_name         = each.value.crypto_key_name
  call_log_level          = each.value.call_log_level
  execution_history_level = each.value.execution_history_level
  labels                  = each.value.labels
  user_env_vars           = each.value.user_env_vars
  tags                    = each.value.tags
  source_contents         = each.value.source_contents
  deletion_protection     = each.value.deletion_protection
}
