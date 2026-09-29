output "storage_account_ids" {
  description = "Map of storage account key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<name>\")."
  value       = { for k, s in azurerm_storage_account.storage_account : k => s.id }
}

output "storage_account_names" {
  description = "Map of storage account key => account name — data-plane tools and other modules take the name, not an ID."
  value       = { for k, s in azurerm_storage_account.storage_account : k => s.name }
}

output "storage_account_primary_blob_endpoints" {
  description = "Map of storage account key => primary blob service endpoint URL, e.g. \"https://<name>.blob.core.windows.net/\"."
  value       = { for k, s in azurerm_storage_account.storage_account : k => s.primary_blob_endpoint }
}

output "storage_account_primary_queue_endpoints" {
  description = "Map of storage account key => primary queue service endpoint URL."
  value       = { for k, s in azurerm_storage_account.storage_account : k => s.primary_queue_endpoint }
}

output "storage_account_primary_table_endpoints" {
  description = "Map of storage account key => primary table service endpoint URL."
  value       = { for k, s in azurerm_storage_account.storage_account : k => s.primary_table_endpoint }
}

output "storage_account_primary_file_endpoints" {
  description = "Map of storage account key => primary file service endpoint URL."
  value       = { for k, s in azurerm_storage_account.storage_account : k => s.primary_file_endpoint }
}

output "storage_account_access_keys" {
  description = "Map of storage account key => { primary_access_key = ..., secondary_access_key = ... }. Sensitive: both members are provider-sensitive access keys. Keys land in state and are visible to anyone with state access — pull them from state or the pipeline, not from logs, and rotate them in the portal or CLI (regeneration is not managed by this module; the keys are read-only attributes of the account)."
  value = {
    for k, s in azurerm_storage_account.storage_account : k => {
      primary_access_key   = s.primary_access_key
      secondary_access_key = s.secondary_access_key
    }
  }
  sensitive = true
}
