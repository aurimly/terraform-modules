resource "azurerm_user_assigned_identity" "managed_identity" {
  for_each = var.managed_identities

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}
