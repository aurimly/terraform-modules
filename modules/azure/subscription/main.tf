resource "azurerm_subscription" "subscription" {
  for_each = var.subscriptions

  subscription_name = each.value.subscription_name
  billing_scope_id  = each.value.billing_scope_id
  subscription_id   = each.value.subscription_id
  alias             = each.value.alias
  workload          = each.value.workload
  tags              = each.value.tags
}
