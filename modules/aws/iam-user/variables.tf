variable "users" {
  description = "Map of IAM users keyed by an arbitrary identifier. Each entry creates one aws_iam_user plus optional group memberships, managed policy attachments, inline policies, and an access key."
  type = map(object({
    name                 = string
    path                 = optional(string, "/")
    permissions_boundary = optional(string)
    force_destroy        = optional(bool, false)
    managed_policy_arns  = optional(list(string), [])
    inline_policies = optional(map(object({
      name        = string
      policy_json = string
    })), {})
    groups = optional(list(string), [])
    access_key = optional(object({
      pgp_key = optional(string)
      status  = optional(string, "Active")
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.users) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (attachment and inline policy resource addresses are composed from user and policy keys)."
  }

  validation {
    condition     = alltrue([for v in var.users : length(v.name) <= 64 && can(regex("^[A-Za-z0-9+=,.@_-]+$", v.name))])
    error_message = "name must be at most 64 characters and contain only letters, digits and +=,.@_- (IAM user name limit; user names are not distinguished by case)."
  }

  validation {
    condition     = alltrue([for v in var.users : alltrue([for k in keys(v.inline_policies) : can(regex("^[^.]+$", k))])])
    error_message = "inline_policies map keys must not contain '.' (inline policy resource addresses are composed from user and policy keys)."
  }

  validation {
    condition     = alltrue([for v in var.users : alltrue([for p in v.inline_policies : length(p.name) > 0 && length(p.name) <= 128])])
    error_message = "inline_policies name must be 1-128 characters (AWS limit)."
  }

  validation {
    condition     = alltrue([for v in var.users : alltrue([for p in v.inline_policies : can(jsondecode(p.policy_json))])])
    error_message = "inline_policies policy_json must be a valid JSON policy document."
  }

  validation {
    condition     = alltrue([for v in var.users : alltrue([for g in v.groups : length(g) > 0])])
    error_message = "groups entries must be non-empty group names."
  }

  validation {
    condition     = alltrue([for v in var.users : v.access_key == null || contains(["Active", "Inactive"], v.access_key.status)])
    error_message = "access_key.status must be Active or Inactive."
  }
}
