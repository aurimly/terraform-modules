resource "azurerm_storage_account" "storage_account" {
  for_each = var.storage_accounts

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  account_kind             = each.value.account_kind
  access_tier              = each.value.access_tier

  https_traffic_only_enabled        = each.value.https_traffic_only_enabled
  min_tls_version                   = each.value.min_tls_version
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  public_network_access             = each.value.public_network_access
  allow_nested_items_to_be_public   = each.value.allow_nested_items_to_be_public
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled

  dynamic "network_rules" {
    for_each = each.value.network_rules != null ? [each.value.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  tags = each.value.tags
}
