variable "resource_groups" {
  description = "Map of Azure resource groups keyed by an arbitrary identifier. Each entry creates one azurerm_resource_group in the subscription configured on the provider — the resource has no subscription argument, so all entries share one subscription."
  type = map(object({
    name       = string
    location   = string
    managed_by = optional(string)
    tags       = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for g in var.resource_groups : can(regex("^[\\p{L}\\p{Nd}_.()-]{0,89}[\\p{L}\\p{Nd}_()-]$", g.name))
    ])
    error_message = "name must be 1 to 90 characters and contain only letters, digits (any Unicode script), underscores, hyphens, periods and parentheses, and must not end in a period."
  }

  validation {
    condition = alltrue(flatten([
      for key, g in var.resource_groups : [
        for other_key, h in var.resource_groups :
        key == other_key || lower(g.name) != lower(h.name)
      ]
    ]))
    error_message = "resource group names must be unique within a subscription, case-insensitively — every entry in this module lands in the provider's subscription, so two names differing only in case conflict at apply."
  }

  validation {
    condition = alltrue([
      for g in var.resource_groups : length(trimspace(g.location)) > 0
    ])
    error_message = "location must not be empty or whitespace; use an Azure region name — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue([
      for g in var.resource_groups : g.managed_by == null || can(regex("^/", g.managed_by))
    ])
    error_message = "managed_by must be a full ARM resource ID (starts with \"/\"), e.g. \"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Automation/automationAccounts/<name>\"."
  }

  validation {
    condition = alltrue([
      for g in var.resource_groups : length(g.tags) <= 50 && alltrue([for k, v in g.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource group, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
