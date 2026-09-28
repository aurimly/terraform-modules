resource "azurerm_role_assignment" "role_assignment" {
  for_each = var.role_assignments

  scope                                  = "/subscriptions/${var.subscription_id}"
  principal_id                           = each.value.principal_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = each.value.role_definition_id
  role_definition_name                   = each.value.role_definition_name
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  description                            = each.value.description
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
