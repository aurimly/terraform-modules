variable "groups" {
  description = "Map of IAM groups keyed by an arbitrary identifier. Each entry creates one aws_iam_group plus optional managed policy attachments and inline policies. Group membership is managed on the user side — see the aws/iam-user module."
  type = map(object({
    name                = string
    path                = optional(string, "/")
    managed_policy_arns = optional(list(string), [])
    inline_policies = optional(map(object({
      name        = string
      policy_json = string
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.groups) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (attachment and inline policy resource addresses are composed from group and policy keys)."
  }

  validation {
    condition     = alltrue([for v in var.groups : length(v.name) <= 128 && can(regex("^[A-Za-z0-9+=,.@_-]+$", v.name))])
    error_message = "name must be at most 128 characters and contain only letters, digits and +=,.@_- (IAM group name limit; group names are not distinguished by case)."
  }

  validation {
    condition     = alltrue([for v in var.groups : alltrue([for k in keys(v.inline_policies) : can(regex("^[^.]+$", k))])])
    error_message = "inline_policies map keys must not contain '.' (inline policy resource addresses are composed from group and policy keys)."
  }

  validation {
    condition     = alltrue([for v in var.groups : alltrue([for p in v.inline_policies : length(p.name) > 0 && length(p.name) <= 128])])
    error_message = "inline_policies name must be 1-128 characters (AWS limit)."
  }

  validation {
    condition     = alltrue([for v in var.groups : alltrue([for p in v.inline_policies : can(jsondecode(p.policy_json))])])
    error_message = "inline_policies policy_json must be a valid JSON policy document."
  }
}
