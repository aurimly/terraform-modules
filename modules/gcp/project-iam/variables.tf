variable "project_id" {
  description = "Project ID of the project the IAM resources apply to (e.g. \"my-project\"). Not inferred from the provider default."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
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
    error_message = "google_project_iam_policy cannot be combined with google_project_iam_audit_config (they fight over the policy). Disable audit_config_enabled or empty audit_configs when mode = \"policy\"."
  }
}

variable "members" {
  description = "Map of IAM grants keyed by an arbitrary identifier. Each entry grants all roles to one member, creating one google_project_iam_member per role; a condition applies to all of the entry's roles. Only used when mode = \"member\"."
  type = map(object({
    member = string
    roles  = list(string)
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
      length(m.roles) > 0
    ])
    error_message = "Each members entry needs at least one role."
  }

  validation {
    condition = alltrue([
      for m in var.members :
      length(distinct(m.roles)) == length(m.roles)
    ])
    error_message = "roles must not repeat within a members entry."
  }

  validation {
    condition = alltrue([
      for m in var.members :
      m.member == "allUsers" || m.member == "allAuthenticatedUsers" || can(regex("^(user|serviceAccount|group|domain|deleted:(user|serviceAccount|group)):.+$", m.member))
    ])
    error_message = "member must be \"allUsers\", \"allAuthenticatedUsers\", \"user|serviceAccount|group|domain:<id>\" or \"deleted:user|serviceAccount|group:<id>\"."
  }

  validation {
    condition = alltrue(flatten([
      for m in var.members : [
        for role in m.roles :
        can(regex("^roles/.+", role)) || can(regex(format("^projects/%s/roles/.+", var.project_id), role)) || can(regex("^organizations/[0-9]+/roles/.+$", role))
      ]
    ]))
    error_message = "roles must be predefined roles (\"roles/...\") or custom roles (\"projects/<project_id>/roles/<role_id>\" or \"organizations/<organization_id>/roles/<role_id>\")."
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
  description = "Map of IAM bindings keyed by an arbitrary identifier. Each entry creates one google_project_iam_binding. Only used when mode = \"binding\". Roles must be unique across bindings."
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
      can(regex("^roles/.+", b.role)) || can(regex(format("^projects/%s/roles/.+", var.project_id), b.role)) || can(regex("^organizations/[0-9]+/roles/.+$", b.role))
    ])
    error_message = "role must be a predefined role (\"roles/...\") or a custom role (\"projects/<project_id>/roles/<role_id>\" or \"organizations/<organization_id>/roles/<role_id>\")."
  }

  validation {
    condition     = length(distinct([for b in var.bindings : b.role])) == length(var.bindings)
    error_message = "bindings must not grant the same role twice; google_project_iam_binding is authoritative per role."
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
  description = "JSON-encoded IAM policy (build it with a google_iam_policy data source or jsonencode). Creates one google_project_iam_policy when mode = \"policy\"."
  type        = string
  default     = null

  validation {
    condition     = var.policy_data == null || (can(jsondecode(var.policy_data)) && can(tomap(jsondecode(var.policy_data))))
    error_message = "policy_data must be a JSON object string (build it with a google_iam_policy data source or jsonencode)."
  }
}

variable "audit_configs" {
  description = "Map of audit log configurations keyed by an arbitrary identifier (typically the service name). Each entry creates one google_project_iam_audit_config. Services must be unique across entries."
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
    error_message = "audit_configs must not configure the same service twice; google_project_iam_audit_config is authoritative per service."
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
  description = "Master toggle for google_project_iam_audit_config resources. Enabled by default; set false to manage no audit configs."
  type        = bool
  default     = true

  validation {
    condition     = var.audit_config_enabled || length(var.audit_configs) == 0
    error_message = "audit_configs must be empty when audit_config_enabled is false."
  }
}
