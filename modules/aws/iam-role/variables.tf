variable "roles" {
  description = "Map of IAM roles keyed by an arbitrary identifier. Each entry creates one aws_iam_role plus optional managed policy attachments, inline policies, and an instance profile."
  type = map(object({
    name                  = string
    path                  = optional(string)
    description           = optional(string)
    max_session_duration  = optional(number, 3600)
    permissions_boundary  = optional(string)
    force_detach_policies = optional(bool, false)
    trust_policy_json     = optional(string)
    trust = optional(object({
      principal_type = string
      identifiers    = list(string)
      conditions = optional(map(object({
        test     = string
        variable = string
        values   = list(string)
      })), {})
    }))
    managed_policy_arns = optional(list(string), [])
    inline_policies = optional(map(object({
      name        = string
      policy_json = string
    })), {})
    create_instance_profile = optional(bool, false)
    tags                    = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.roles) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (attachment and inline policy resource addresses are composed from role and policy keys)."
  }

  validation {
    condition     = alltrue([for v in var.roles : length(v.name) <= 64 && can(regex("^[A-Za-z0-9+=,.@_-]+$", v.name))])
    error_message = "name must be at most 64 characters and contain only letters, digits and +=,.@_- (IAM role name limit; also applied to the instance profile, which reuses the role name)."
  }

  validation {
    condition     = alltrue([for v in var.roles : (v.trust_policy_json == null) != (v.trust == null)])
    error_message = "set exactly one of trust_policy_json or trust (the assume-role policy must come from one of the two)."
  }

  validation {
    condition     = alltrue([for v in var.roles : v.trust == null || (length(v.trust.principal_type) > 0 && length(v.trust.identifiers) > 0)])
    error_message = "trust.principal_type and trust.identifiers must be non-empty (an assume-role statement without principals is invalid)."
  }

  validation {
    condition     = alltrue([for v in var.roles : v.trust == null || contains(["AWS", "Service", "Federated", "CanonicalUser", "*"], v.trust.principal_type)])
    error_message = "trust.principal_type must be one of AWS, Service, Federated, CanonicalUser or * (case-sensitive)."
  }

  validation {
    condition     = alltrue([for v in var.roles : v.trust_policy_json == null || can(jsondecode(v.trust_policy_json))])
    error_message = "trust_policy_json must be a valid JSON policy document."
  }

  validation {
    condition     = alltrue([for v in var.roles : v.max_session_duration >= 3600 && v.max_session_duration <= 43200])
    error_message = "max_session_duration must be within 3600-43200 seconds (AWS limit)."
  }

  validation {
    condition     = alltrue([for v in var.roles : alltrue([for k in keys(v.inline_policies) : can(regex("^[^.]+$", k))])])
    error_message = "inline_policies map keys must not contain '.' (inline policy resource addresses are composed from role and policy keys)."
  }

  validation {
    condition     = alltrue([for v in var.roles : alltrue([for p in v.inline_policies : length(p.name) > 0 && length(p.name) <= 128])])
    error_message = "inline_policies name must be 1-128 characters (AWS limit)."
  }

  validation {
    condition     = alltrue([for v in var.roles : alltrue([for p in v.inline_policies : can(jsondecode(p.policy_json))])])
    error_message = "inline_policies policy_json must be a valid JSON policy document."
  }
}
