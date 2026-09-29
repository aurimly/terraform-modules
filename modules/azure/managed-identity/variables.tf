variable "managed_identities" {
  description = "Map of Azure user-assigned managed identities keyed by an arbitrary identifier. Each entry creates one azurerm_user_assigned_identity in the named resource group, in the subscription configured on the provider."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    tags                = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for m in var.managed_identities : can(regex("^[\\p{L}\\p{Nd}][\\p{L}\\p{Nd}_-]{2,127}$", m.name))
    ])
    error_message = "name must be 3 to 128 characters and contain only letters, digits (any Unicode script), underscores and hyphens, and must start with a letter or digit."
  }

  validation {
    condition = alltrue(flatten([
      for key, m in var.managed_identities : [
        for other_key, n in var.managed_identities :
        key == other_key || lower(m.resource_group_name) != lower(n.resource_group_name) || lower(m.name) != lower(n.name)
      ]
    ]))
    error_message = "managed identity names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for m in var.managed_identities : length(trimspace(m.name)) > 0 && length(trimspace(m.resource_group_name)) > 0 && length(trimspace(m.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace; use an Azure region name for location — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue([
      for m in var.managed_identities : length(m.tags) <= 50 && alltrue([for k, v in m.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
