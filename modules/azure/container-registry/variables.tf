variable "container_registries" {
  description = "Map of Azure Container Registries keyed by an arbitrary identifier. Each entry creates one azurerm_container_registry in the named resource group; registry names are alphanumeric and globally unique across all of Azure. Nested georeplications, webhooks, scope maps and tokens wire into the registry resources this module creates itself."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    sku                           = optional(string, "Premium")
    admin_enabled                 = optional(bool, false)
    public_network_access_enabled = optional(bool, true)

    anonymous_pull_enabled                       = optional(bool)
    data_endpoint_enabled                        = optional(bool)
    quarantine_policy_enabled                    = optional(bool)
    retention_policy_in_days                     = optional(number)
    zone_redundancy_enabled                      = optional(bool)
    export_policy_enabled                        = optional(bool)
    azuread_authentication_as_arm_policy_enabled = optional(bool)

    network_rule_bypass_option            = optional(string, "AzureServices")
    network_rule_bypass_for_tasks_enabled = optional(bool)
    role_assignment_mode                  = optional(string, "LegacyRegistryPermissions")

    network_rule_set = optional(object({
      default_action = optional(string, "Allow")
      ip_rule = optional(map(object({
        action   = optional(string, "Allow")
        ip_range = string
      })), {})
    }))

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    encryption = optional(object({
      key_vault_key_id   = string
      identity_client_id = string
    }))

    georeplications = optional(map(object({
      location                        = string
      global_endpoint_routing_enabled = optional(bool, true)
      zone_redundancy_enabled         = optional(bool)
      tags                            = optional(map(string), {})
    })), {})

    webhooks = optional(map(object({
      name           = string
      service_uri    = string
      actions        = list(string)
      status         = optional(string, "enabled")
      scope          = optional(string)
      custom_headers = optional(map(string), {})
      tags           = optional(map(string), {})
    })), {})

    scope_maps = optional(map(object({
      name        = string
      actions     = list(string)
      description = optional(string)
    })), {})

    tokens = optional(map(object({
      name             = string
      scope_map_key    = string
      enabled          = optional(bool, true)
      password1_expiry = optional(string)
      password2_expiry = optional(string)
    })), {})

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue(flatten([
      for registry in var.container_registries : [
        for token in registry.tokens : can(regex("^[a-zA-Z0-9-]{5,50}$", token.name))
      ]
    ]))
    error_message = "tokens: name must be 5–50 alphanumeric/hyphen characters (the Azure API's registry-resource naming rule, validated provider-side too) — token names are unique within their registry."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries : can(regex("^[a-zA-Z0-9]{5,50}$", registry.name))
    ])
    error_message = "name must be 5–50 alphanumeric characters (no hyphens) — the registry name doubles as the login-server host (<name>.azurecr.io), globally unique across all of Azure, which the module cannot check: a claimed name fails at apply. See the Azure naming docs for details."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries : contains(["Basic", "Standard", "Premium"], registry.sku)
    ])
    error_message = "sku must be Basic, Standard or Premium (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries :
      registry.sku == "Premium" || (
        registry.data_endpoint_enabled != true
        && registry.quarantine_policy_enabled != true
        && registry.retention_policy_in_days == null
        && registry.zone_redundancy_enabled != true
        && length(registry.georeplications) == 0
        && registry.network_rule_set == null
      )
    ])
    error_message = "georeplications, network_rule_set, data_endpoint_enabled, quarantine_policy_enabled, retention_policy_in_days and zone_redundancy_enabled are Premium-only features — they require sku = \"Premium\"."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries :
      !(registry.sku == "Basic" && registry.anonymous_pull_enabled == true)
    ])
    error_message = "anonymous_pull_enabled is only supported on the Standard and Premium SKUs."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries :
      registry.network_rule_set == null || (
        contains(["Allow", "Deny"], registry.network_rule_set.default_action)
        && alltrue([for ip, rule in registry.network_rule_set.ip_rule : rule.action == "Allow"])
      )
    ])
    error_message = "network_rule_set default_action must be Allow or Deny, and each ip_rule action must be \"Allow\" — Allow is the only action the API supports."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries :
      registry.export_policy_enabled != false || !registry.public_network_access_enabled
    ])
    error_message = "export_policy_enabled = false requires public_network_access_enabled = false — the provider rule: with export locked, the public endpoint must be closed."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries :
      contains(["None", "AzureServices"], registry.network_rule_bypass_option)
    ])
    error_message = "network_rule_bypass_option must be None or AzureServices."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries :
      contains(["LegacyRegistryPermissions", "AbacRepositoryPermissions"], registry.role_assignment_mode)
    ])
    error_message = "role_assignment_mode must be LegacyRegistryPermissions or AbacRepositoryPermissions — ABAC repositories scope RBAC to repositories (see Notes)."
  }

  validation {
    condition = alltrue(flatten([
      for registry in var.container_registries : [
        length(distinct([for geo_key, geo in registry.georeplications : lower(geo.location)])) == length(registry.georeplications)
        && alltrue([for geo_key, geo in registry.georeplications : lower(geo.location) != lower(registry.location)])
      ]
    ]))
    error_message = "georeplication locations must be unique within the entry and must not repeat the registry's own location — the Azure API rejects duplicates and the native location. The module emits the blocks sorted by location so the API's alphabetic-order rule is met no matter how the map is written (see Notes)."
  }

  validation {
    condition = alltrue(flatten([
      for registry in var.container_registries : [
        for webhook in registry.webhooks :
        can(regex("^[a-zA-Z0-9]+$", webhook.name))
        && length(webhook.actions) >= 1
        && alltrue([for action in webhook.actions : contains(["push", "delete", "quarantine", "chart_push", "chart_delete"], action)])
        && contains(["enabled", "disabled"], webhook.status)
      ]
    ]))
    error_message = "webhooks: name is alphanumeric only, actions at least one of push, delete, quarantine, chart_push, chart_delete, and status enabled or disabled (lowercase)."
  }

  validation {
    condition = alltrue(flatten([
      for registry in var.container_registries : [
        for scope_map in registry.scope_maps :
        length(scope_map.actions) >= 1
        && alltrue([for action in scope_map.actions : can(regex("^repositories/[^/]+/(content|metadata)/[a-z]+$", action))])
      ]
    ]))
    error_message = "scope_maps actions look like \"repositories/<repo>/content/<perm>\" — content|metadata followed by permissions (read, write, delete or the matrix .../action, e.g. \"repositories/app/content/read\")."
  }

  validation {
    condition = alltrue(flatten([
      for registry in var.container_registries : [
        for token_key, token in registry.tokens : can(registry.scope_maps[token.scope_map_key].name)
      ]
    ]))
    error_message = "tokens scope_map_key must reference an existing scope_maps key of the same registry entry — tokens cannot bind to externally-managed scope maps from this module."
  }

  validation {
    condition = alltrue(flatten([
      for registry in var.container_registries : [
        for token in registry.tokens :
        (token.password1_expiry == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T", token.password1_expiry)))
        && (token.password2_expiry == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T", token.password2_expiry)))
      ]
    ]))
    error_message = "token password expiries are RFC 3339 timestamps (\"2027-01-02T03:04:05Z\") when set — changing them forces a new password resource (rotation)."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries :
      registry.identity == null || !contains(["UserAssigned", "SystemAssigned, UserAssigned"], registry.identity.type) || alltrue([for id in coalesce(registry.identity.identity_ids, []) : can(regex("^/", id))])
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — full ARM resource IDs of user-assigned managed identities."
  }

  validation {
    condition = alltrue([
      for registry in var.container_registries :
      registry.encryption == null || registry.identity != null
    ])
    error_message = "encryption requires an identity block — the customer-managed key is unlocked through a user-assigned identity referenced in the encryption block's identity_client_id (it must also appear in identity.identity_ids)."
  }

  validation {
    condition = alltrue(flatten([
      for registry in var.container_registries : [
        length(registry.tags) <= 50 && alltrue([for tag_key, tag_value in registry.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
      ]
    ]))
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }

  validation {
    condition = alltrue(concat(
      [for registry_key in keys(var.container_registries) : !can(regex("\\.", registry_key))],
      flatten([
        for registry in var.container_registries : [
          for web_key in concat(keys(registry.webhooks), keys(registry.scope_maps), keys(registry.tokens)) : !can(regex("\\.", web_key))
        ]
      ])
    ))
    error_message = "map keys of container_registries and its nested georeplications, webhooks, scope_maps and tokens maps must not contain \".\" — registry keys are composed into child identifiers of the form \"<registry_key>.<child_key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for registry in var.container_registries : [
        length(distinct([for webhook in registry.webhooks : lower(webhook.name)])) == length(registry.webhooks),
        length(distinct([for scope_map in registry.scope_maps : scope_map.name])) == length(registry.scope_maps),
        length(distinct([for token in registry.tokens : token.name])) == length(registry.tokens)
      ]
    ]))
    error_message = "webhook names must be unique within their registry case-insensitively, scope-map and token names unique within their registry — all three live under the registry's naming scope at the Azure API."
  }
}
