variable "project_id" {
  description = "Project ID service accounts are created in by default (e.g. \"my-project\"). Each entry can override it with its own project."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}

variable "service_accounts" {
  description = "Map of service accounts keyed by an arbitrary identifier. Each entry creates one google_service_account."
  type = map(object({
    account_id                   = string
    display_name                 = optional(string)
    description                  = optional(string)
    disabled                     = optional(bool, false)
    create_ignore_already_exists = optional(bool, false)
    deletion_policy              = optional(string, "DELETE")
    project                      = optional(string)
  }))

  validation {
    condition = alltrue([
      for sa in var.service_accounts :
      length(sa.account_id) >= 6 && length(sa.account_id) <= 30 && can(regex("^[a-z]([-a-z0-9]*[a-z0-9])$", sa.account_id))
    ])
    error_message = "account_id must be 6 to 30 characters, start with a lowercase letter, and contain only lowercase letters, digits and hyphens (RFC1035)."
  }

  validation {
    condition = alltrue([
      for sa in var.service_accounts :
      sa.project == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", sa.project))
    ])
    error_message = "project must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition = alltrue([
      for sa in var.service_accounts :
      sa.description == null || length(sa.description) <= 256
    ])
    error_message = "description must be at most 256 characters (the API allows 256 UTF-8 bytes)."
  }

  validation {
    condition = alltrue([
      for sa in var.service_accounts :
      contains(["DELETE", "ABANDON", "PREVENT"], sa.deletion_policy)
    ])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }

  validation {
    condition = length(distinct([
      for sa in var.service_accounts : "${coalesce(sa.project, var.project_id)}/${sa.account_id}"
    ])) == length(var.service_accounts)
    error_message = "account_id must be unique within a project; two entries resolve to the same project/account_id pair."
  }
}
