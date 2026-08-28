variable "service_accounts" {
  description = "Map of service accounts to manage IAM on, keyed by an arbitrary identifier. Values are the fully-qualified service account resource names, \"projects/<project_id>/serviceAccounts/<email>\" — the service_accounts output of the gcp/service-account module."
  type        = map(string)

  validation {
    condition = alltrue([
      for sa in var.service_accounts :
      can(regex("^projects/[^/]+/serviceAccounts/[^/]+$", sa))
    ])
    error_message = "service_accounts values must be fully-qualified service account resource names (\"projects/<project_id>/serviceAccounts/<email>\")."
  }
}

variable "mode" {
  description = "Which IAM resource family to manage: \"member\" (one role per member, non-authoritative), \"binding\" (authoritative per role) or \"policy\" (authoritative whole-policy per service account). Defaults to \"member\"."
  type        = string
  default     = "member"

  validation {
    condition     = contains(["member", "binding", "policy"], var.mode)
    error_message = "mode must be one of \"member\", \"binding\" or \"policy\"."
  }

  validation {
    condition = (
      (var.mode == "member" && length(var.bindings) == 0 && length(var.policies) == 0) ||
      (var.mode == "binding" && length(var.members) == 0 && length(var.policies) == 0) ||
      (var.mode == "policy" && length(var.members) == 0 && length(var.bindings) == 0 && length(var.policies) > 0)
    )
    error_message = "Only the input matching the selected mode may be set: members for mode \"member\", bindings for mode \"binding\", policies for mode \"policy\"."
  }
}

variable "members" {
  description = "Map of IAM grants keyed by an arbitrary identifier. Each entry grants all roles to one member on one service account (keyed in service_accounts), creating one google_service_account_iam_member per role; a condition applies to all of the entry's roles. Only used when mode = \"member\"."
  type = map(object({
    service_account = string
    member          = string
    roles           = list(string)
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
      contains(keys(var.service_accounts), m.service_account)
    ])
    error_message = "Each members entry's service_account must be a key of service_accounts."
  }

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
      m.member == "allUsers" || m.member == "allAuthenticatedUsers" ||
      can(regex("^(user|serviceAccount|group|domain|deleted:(user|serviceAccount|group)):.+$", m.member)) ||
      can(regex("^(principal|principalSet|principalGroup)://.+$", m.member))
    ])
    error_message = "member must be \"allUsers\", \"allAuthenticatedUsers\", \"user|serviceAccount|group|domain:<id>\", \"deleted:user|serviceAccount|group:<id>\" or a federated principal (\"principal://...\", \"principalSet://...\", \"principalGroup://...\")."
  }

  validation {
    condition = alltrue(flatten([
      for m in var.members : [
        for role in m.roles :
        can(regex("^roles/.+$", role)) || can(regex("^projects/[^/]+/roles/.+$", role)) || can(regex("^organizations/[0-9]+/roles/.+$", role))
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
  description = "Map of IAM bindings keyed by an arbitrary identifier. Each entry creates one google_service_account_iam_binding on the referenced service account. Only used when mode = \"binding\". A role must not be bound twice on the same service account."
  type = map(object({
    service_account = string
    role            = string
    members         = list(string)
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for b in var.bindings :
      contains(keys(var.service_accounts), b.service_account)
    ])
    error_message = "Each bindings entry's service_account must be a key of service_accounts."
  }

  validation {
    condition = alltrue(flatten([
      for b in var.bindings : [
        for m in b.members :
        m == "allUsers" || m == "allAuthenticatedUsers" ||
        can(regex("^(user|serviceAccount|group|domain|deleted:(user|serviceAccount|group)):.+$", m)) ||
        can(regex("^(principal|principalSet|principalGroup)://.+$", m))
      ]
    ]))
    error_message = "members entries must be \"allUsers\", \"allAuthenticatedUsers\", \"user|serviceAccount|group|domain:<id>\", \"deleted:user|serviceAccount|group:<id>\" or federated principals (\"principal://...\", \"principalSet://...\", \"principalGroup://...\")."
  }

  validation {
    condition = alltrue([
      for b in var.bindings :
      can(regex("^roles/.+$", b.role)) || can(regex("^projects/[^/]+/roles/.+$", b.role)) || can(regex("^organizations/[0-9]+/roles/.+$", b.role))
    ])
    error_message = "role must be a predefined role (\"roles/...\") or a custom role (\"projects/<project_id>/roles/<role_id>\" or \"organizations/<organization_id>/roles/<role_id>\")."
  }

  validation {
    condition = length(distinct([
      for b in var.bindings : "${b.service_account}/${b.role}"
    ])) == length(var.bindings)
    error_message = "bindings must not grant the same role twice on the same service account; google_service_account_iam_binding is authoritative per role."
  }

  validation {
    condition = alltrue([
      for b in var.bindings :
      b.condition == null || (length(b.condition.title) > 0 && length(b.condition.expression) > 0)
    ])
    error_message = "condition title and expression must not be empty."
  }
}

variable "policies" {
  description = "Map of whole-policy grants keyed by service account key (a key of service_accounts; one policy per service account). Each entry creates one google_service_account_iam_policy with the given JSON policy. Only used when mode = \"policy\"."
  type = map(object({
    policy_data = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k in keys(var.policies) :
      contains(keys(var.service_accounts), k)
    ])
    error_message = "policies keys must be service account keys (keys of service_accounts); one policy per service account."
  }

  validation {
    condition = alltrue([
      for p in var.policies :
      can(jsondecode(p.policy_data)) && can(tomap(jsondecode(p.policy_data)))
    ])
    error_message = "policy_data must be a JSON object string (build it with a google_iam_policy data source or jsonencode)."
  }
}
