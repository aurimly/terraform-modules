output "budget_names" {
  description = "Map of budget key => full resource name (billingAccounts/{billing_account}/budgets/{budget})."
  value       = { for k, b in google_billing_budget.budget : k => b.name }
}
