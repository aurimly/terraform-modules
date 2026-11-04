variable "integrations" {
  description = "Map of Snowflake email notification integrations keyed by an arbitrary identifier. Each entry creates one snowflake_email_notification_integration (account-level object)."
  type = map(object({
    name               = string
    enabled            = bool
    allowed_recipients = optional(list(string))
    comment            = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for i in var.integrations :
      i.allowed_recipients == null || alltrue([for e in i.allowed_recipients : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    ])
    error_message = "allowed_recipients entries must look like email addresses (Snowflake itself further requires each recipient to exist as a user in the account with a verified email address)."
  }

  validation {
    condition = alltrue([
      for i in var.integrations :
      length(trimspace(i.name)) > 0
    ])
    error_message = "name must not be empty or whitespace."
  }

  validation {
    condition = alltrue(flatten([
      for key, i in var.integrations : [
        for other_key, n in var.integrations :
        key == other_key || upper(i.name) != upper(n.name)
      ]
    ]))
    error_message = "integration names must be unique within the account, case-insensitively — two entries sharing a name conflict at apply."
  }
}
