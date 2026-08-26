variable "organization_id" {
  description = "Bare numeric ID of the organization the IAM resources apply to (e.g. \"123456789012\")."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "organization_id must be the bare numeric organization ID (e.g. \"123456789012\")."
  }
}

variable "mode" {
  description = "Which IAM resource family to manage: \"member\" (one role per member, non-authoritative), \"binding\" (authoritative per role) or \"policy\" (authoritative whole-policy). Defaults to \"member\"."
  type        = string
  default     = "member"

  validation {
    condition     = contains(["member", "binding", "policy"], var.mode)
    error_message = "mode must be one of \"member\", \"binding\" or \"policy\"."
  }

  validation {
    condition = (
      (var.mode == "member" && length(var.bindings) == 0 && var.policy_data == null) ||
      (var.mode == "binding" && length(var.members) == 0 && var.policy_data == null) ||
      (var.mode == "policy" && length(var.members) == 0 && length(var.bindings) == 0 && var.policy_data != null)
    )
    error_message = "Only the input matching the selected mode may be set: members for mode \"member\", bindings for mode \"binding\", policy_data for mode \"policy\"."
  }

  validation {
    condition     = var.mode != "policy" || !var.audit_config_enabled || length(var.audit_configs) == 0
    error_message = "google_organization_iam_policy cannot be combined with google_organization_iam_audit_config (they fight over the policy). Disable audit_config_enabled or empty audit_configs when mode = \"policy\"."
  }
}

variable "members" {
  description = "Map of IAM members keyed by an arbitrary identifier. Each entry creates one google_organization_iam_member. Only used when mode = \"member\"."
  type = map(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for m in var.members :
      m.member == "allUsers" || m.member == "allAuthenticatedUsers" || can(regex("^(user|serviceAccount|group|domain|deleted:(user|serviceAccount|group)):.+$", m.member))
    ])
    error_message = "member must be \"allUsers\", \"allAuthenticatedUsers\", \"user|serviceAccount|group|domain:<id>\" or \"deleted:user|serviceAccount|group:<id>\"."
  }

  validation {
    condition = alltrue([
      for m in var.members :
      can(regex("^roles/.+", m.role)) || can(regex(format("^organizations/%s/roles/.+", var.organization_id), m.role))
    ])
    error_message = "role must be a predefined role (\"roles/...\") or a custom role (\"organizations/<organization_id>/roles/<role_id>\")."
  }

  validation {
    condition = alltrue([
      for m in var.members :
      m.condition == null || (length(m.condition.title) > 0 && length(m.condition.expression) > 0)
    ])
    error_message = "condition title and expression must not be empty."
  }
}

variable "bindings" {
  description = "Map of IAM bindings keyed by an arbitrary identifier. Each entry creates one google_organization_iam_binding. Only used when mode = \"binding\". Roles must be unique across bindings."
  type = map(object({
    role    = string
    members = list(string)
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for b in var.bindings : [
        for m in b.members :
        m == "allUsers" || m == "allAuthenticatedUsers" || can(regex("^(user|serviceAccount|group|domain|deleted:(user|serviceAccount|group)):.+$", m))
      ]
    ]))
    error_message = "members entries must be \"allUsers\", \"allAuthenticatedUsers\", \"user|serviceAccount|group|domain:<id>\" or \"deleted:user|serviceAccount|group:<id>\"."
  }

  validation {
    condition = alltrue([
      for b in var.bindings :
      can(regex("^roles/.+", b.role)) || can(regex(format("^organizations/%s/roles/.+", var.organization_id), b.role))
    ])
    error_message = "role must be a predefined role (\"roles/...\") or a custom role (\"organizations/<organization_id>/roles/<role_id>\")."
  }

  validation {
    condition     = length(distinct([for b in var.bindings : b.role])) == length(var.bindings)
    error_message = "bindings must not grant the same role twice; google_organization_iam_binding is authoritative per role."
  }

  validation {
    condition = alltrue([
      for b in var.bindings :
      b.condition == null || (length(b.condition.title) > 0 && length(b.condition.expression) > 0)
    ])
    error_message = "condition title and expression must not be empty."
  }
}

variable "policy_data" {
  description = "JSON-encoded IAM policy (build it with a google_iam_policy data source or jsonencode). Creates one google_organization_iam_policy when mode = \"policy\"."
  type        = string
  default     = null

  validation {
    condition     = var.policy_data == null || (can(jsondecode(var.policy_data)) && can(tomap(jsondecode(var.policy_data))))
    error_message = "policy_data must be a JSON object string (build it with a google_iam_policy data source or jsonencode)."
  }
}

variable "audit_configs" {
  description = "Map of audit log configurations keyed by an arbitrary identifier (typically the service name). Each entry creates one google_organization_iam_audit_config. Services must be unique across entries."
  type = map(object({
    service = string
    audit_log_configs = list(object({
      log_type         = string
      exempted_members = optional(list(string), [])
    }))
  }))
  default = {}

  validation {
    condition     = length(distinct([for a in var.audit_configs : a.service])) == length(var.audit_configs)
    error_message = "audit_configs must not configure the same service twice; google_organization_iam_audit_config is authoritative per service."
  }

  validation {
    condition = alltrue([
      for a in var.audit_configs :
      length(a.audit_log_configs) > 0
    ])
    error_message = "audit_configs entries need at least one audit_log_config."
  }

  validation {
    condition = alltrue([
      for a in var.audit_configs : alltrue([
        for c in a.audit_log_configs :
        contains(["DATA_READ", "DATA_WRITE", "ADMIN_READ"], c.log_type)
      ])
    ])
    error_message = "audit_log_config log_type must be one of DATA_READ, DATA_WRITE or ADMIN_READ."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.audit_configs : [
        for c in a.audit_log_configs : [
          for m in c.exempted_members :
          m == "allUsers" || m == "allAuthenticatedUsers" || can(regex("^(user|serviceAccount|group|domain|deleted:(user|serviceAccount|group)):.+$", m))
        ]
      ]
    ]))
    error_message = "exempted_members entries must be \"allUsers\", \"allAuthenticatedUsers\", \"user|serviceAccount|group|domain:<id>\" or \"deleted:user|serviceAccount|group:<id>\"."
  }
}

variable "audit_config_enabled" {
  description = "Master toggle for google_organization_iam_audit_config resources. Enabled by default; set false to manage no audit configs."
  type        = bool
  default     = true

  validation {
    condition     = var.audit_config_enabled || length(var.audit_configs) == 0
    error_message = "audit_configs must be empty when audit_config_enabled is false."
  }
}
