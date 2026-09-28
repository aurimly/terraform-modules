variable "subscription_id" {
  description = "GUID of the subscription the role assignments apply to. Assignments at subscription scope apply to every resource group and resource inside it; grants cascading down from management groups are not managed here. Not inferred from the provider default."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a bare subscription GUID (8-4-4-4-12 hex), e.g. \"12345678-1234-5678-9012-123456789012\"."
  }
}

variable "role_assignments" {
  description = "Map of role assignments keyed by an arbitrary identifier. Each entry creates one azurerm_role_assignment. Exactly one of role_definition_name (built-in role) or role_definition_id (fully-qualified role definition ID) per entry."
  type = map(object({
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    description                            = optional(string)
    delegated_managed_identity_resource_id = optional(string)
    skip_service_principal_aad_check       = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for a in var.role_assignments : (a.role_definition_name == null) != (a.role_definition_id == null)
    ])
    error_message = "each role assignment must set exactly one of role_definition_name (built-in role) or role_definition_id (fully-qualified role definition ID)."
  }

  validation {
    condition = alltrue([
      for a in var.role_assignments : a.role_definition_name == null || length(trimspace(a.role_definition_name)) > 0
    ])
    error_message = "role_definition_name must not be empty when set."
  }

  validation {
    condition = alltrue([
      for a in var.role_assignments : a.role_definition_id == null || can(regex("^/subscriptions/[^/]+/providers/Microsoft\\.Authorization/roleDefinitions/[^/]+$", a.role_definition_id)) || can(regex("^/providers/Microsoft\\.Management/managementGroups/[^/]+/providers/Microsoft\\.Authorization/roleDefinitions/[^/]+$", a.role_definition_id)) || can(regex("^/providers/Microsoft\\.Authorization/roleDefinitions/[^/]+$", a.role_definition_id))
    ])
    error_message = "role_definition_id must be a fully-qualified role definition ID: \"/subscriptions/<id>/providers/Microsoft.Authorization/roleDefinitions/<guid>\", \"/providers/Microsoft.Management/managementGroups/<id>/providers/Microsoft.Authorization/roleDefinitions/<guid>\" or \"/providers/Microsoft.Authorization/roleDefinitions/<guid>\" (custom roles; built-in roles can use their name instead)."
  }

  validation {
    condition = alltrue([
      for a in var.role_assignments : a.principal_type == null || contains(["User", "Group", "ServicePrincipal"], a.principal_type)
    ])
    error_message = "principal_type must be one of \"User\", \"Group\" or \"ServicePrincipal\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for a in var.role_assignments : !a.skip_service_principal_aad_check || a.principal_type == "ServicePrincipal"
    ])
    error_message = "skip_service_principal_aad_check is only valid for service principal grants; set principal_type = \"ServicePrincipal\" for the entry."
  }

  validation {
    condition = alltrue([
      for a in var.role_assignments : a.condition_version == null || contains(["1.0", "2.0"], a.condition_version)
    ])
    error_message = "condition_version must be \"1.0\" or \"2.0\"."
  }

  validation {
    condition = alltrue([
      for a in var.role_assignments : (a.condition == null || length(trimspace(a.condition)) > 0) && (a.description == null || length(trimspace(a.description)) > 0)
    ])
    error_message = "condition and description must not be empty when set."
  }

  validation {
    condition = alltrue([
      for a in var.role_assignments : a.delegated_managed_identity_resource_id == null || can(regex("^/", a.delegated_managed_identity_resource_id))
    ])
    error_message = "delegated_managed_identity_resource_id must be a full ARM resource ID (starts with \"/\")."
  }

  validation {
    condition = alltrue(flatten([
      for key, a in var.role_assignments : [
        for other_key, b in var.role_assignments :
        key == other_key || a.principal_id != b.principal_id || lower(coalesce(a.role_definition_name, a.role_definition_id)) != lower(coalesce(b.role_definition_name, b.role_definition_id))
      ]
    ]))
    error_message = "entries sharing one principal_id and role conflict regardless of conditions — Azure enforces one assignment per principal and role at the same scope and rejects duplicates with \"role assignment already exists\". Grant the same role via a group, or not at all."
  }
}
