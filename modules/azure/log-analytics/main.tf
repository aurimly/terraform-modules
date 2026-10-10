locals {
  linked_services = merge([
    for workspace_key, workspace in var.workspaces : {
      for link_key, link in workspace.linked_services : "${workspace_key}.${link_key}" => merge(link, {
        workspace_id = azurerm_log_analytics_workspace.workspace[workspace_key].id
      })
    }
  ]...)

  linked_storage_accounts = merge([
    for workspace_key, workspace in var.workspaces : {
      for link_key, link in workspace.linked_storage_accounts : "${workspace_key}.${link_key}" => merge(link, {
        workspace_id = azurerm_log_analytics_workspace.workspace[workspace_key].id
      })
    }
  ]...)
}

resource "azurerm_log_analytics_workspace" "workspace" {
  for_each = var.workspaces

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku

  retention_in_days    = each.value.retention_in_days
  daily_quota_gb       = each.value.daily_quota_gb
  cmk_for_query_forced = each.value.cmk_for_query_forced

  immediate_data_purge_on_30_days_enabled = each.value.immediate_data_purge_on_30_days_enabled

  reservation_capacity_in_gb_per_day = each.value.reservation_capacity_in_gb_per_day
  data_collection_rule_id            = each.value.data_collection_rule_id

  internet_ingestion_access_type = each.value.internet_ingestion_access_type
  internet_query_access_type     = each.value.internet_query_access_type

  local_authentication_enabled    = each.value.local_authentication_enabled
  allow_resource_only_permissions = each.value.allow_resource_only_permissions

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = each.value.tags
}

resource "azurerm_log_analytics_linked_service" "linked_service" {
  for_each = local.linked_services

  resource_group_name = var.workspaces[split(".", each.key)[0]].resource_group_name
  workspace_id        = each.value.workspace_id

  read_access_id  = each.value.read_access_id
  write_access_id = each.value.write_access_id
}

resource "azurerm_log_analytics_linked_storage_account" "linked_storage" {
  for_each = local.linked_storage_accounts

  data_source_type    = each.value.data_source_type
  resource_group_name = var.workspaces[split(".", each.key)[0]].resource_group_name
  storage_account_ids = each.value.storage_account_ids
  workspace_id        = each.value.workspace_id
}
