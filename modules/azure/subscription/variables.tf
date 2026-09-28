variable "subscriptions" {
  description = "Map of Azure subscriptions keyed by an arbitrary identifier. Each entry creates one subscription alias: either a new subscription created under a billing scope (billing_scope_id) or management of an existing subscription (subscription_id). Exactly one of the two must be set per entry."
  type = map(object({
    subscription_name = string
    billing_scope_id  = optional(string)
    subscription_id   = optional(string)
    alias             = optional(string)
    workload          = optional(string)
    tags              = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for s in var.subscriptions : can(regex("^[^<>;|]{1,64}$", s.subscription_name))
    ])
    error_message = "subscription_name must be 1 to 64 characters and must not contain any of the characters <, >, ; or |."
  }

  validation {
    condition = alltrue([
      for s in var.subscriptions : s.alias == null || length(trimspace(s.alias)) > 0
    ])
    error_message = "alias must not be empty when set."
  }

  validation {
    condition     = length(distinct([for s in var.subscriptions : s.alias if s.alias != null])) == length([for s in var.subscriptions : s.alias if s.alias != null])
    error_message = "alias must not repeat across entries; Azure supports only one alias per subscription."
  }

  validation {
    condition = alltrue([
      for s in var.subscriptions : s.workload == null || contains(["Production", "DevTest"], s.workload)
    ])
    error_message = "workload must be one of \"Production\" or \"DevTest\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for s in var.subscriptions : s.subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.subscription_id))
    ])
    error_message = "subscription_id must be a subscription GUID (8-4-4-4-12 hex)."
  }

  validation {
    condition = alltrue([
      for s in var.subscriptions : s.billing_scope_id == null || can(regex("^/providers/Microsoft\\.Billing/billingAccounts/[^/]+/enrollmentAccounts/[^/]+$", s.billing_scope_id)) || can(regex("^/providers/Microsoft\\.Billing/billingAccounts/[^/]+/billingProfiles/[^/]+/invoiceSections/[^/]+$", s.billing_scope_id)) || can(regex("^/providers/Microsoft\\.Billing/billingAccounts/[^/]+/customers/[^/]+$", s.billing_scope_id))
    ])
    error_message = "billing_scope_id must be an enrollment-account scope (\"/providers/Microsoft.Billing/billingAccounts/<id>/enrollmentAccounts/<id>\"), a Microsoft Customer Account scope (\"/providers/Microsoft.Billing/billingAccounts/<id>/billingProfiles/<id>/invoiceSections/<id>\") or a Microsoft Partner Account scope (\"/providers/Microsoft.Billing/billingAccounts/<id>/customers/<id>\")."
  }

  validation {
    condition = alltrue([
      for s in var.subscriptions : (s.billing_scope_id == null) != (s.subscription_id == null)
    ])
    error_message = "each subscription must set exactly one of billing_scope_id (create a new subscription under a billing scope) or subscription_id (adopt an existing subscription)."
  }

  validation {
    condition = alltrue([
      for s in var.subscriptions : length(s.tags) <= 50 && alltrue([for k, v in s.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per subscription, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
