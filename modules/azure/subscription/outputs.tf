output "subscription_ids" {
  description = "Map of subscription key => subscription GUID (the UUID of the /subscriptions/<id> scope)."
  value       = { for k, s in azurerm_subscription.subscription : k => s.subscription_id }
}

output "alias_ids" {
  description = "Map of subscription key => alias resource ID (\"/providers/Microsoft.Subscription/aliases/<alias>\") — the azurerm_subscription resource ID, used for imports."
  value       = { for k, s in azurerm_subscription.subscription : k => s.id }
}

output "tenant_ids" {
  description = "Map of subscription key => tenant GUID the subscription belongs to."
  value       = { for k, s in azurerm_subscription.subscription : k => s.tenant_id }
}
