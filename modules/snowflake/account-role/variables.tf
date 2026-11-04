variable "account_roles" {
  description = "Map of Snowflake account roles keyed by an arbitrary identifier. Each entry creates one snowflake_account_role."
  type = map(object({
    name    = string
    comment = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.account_roles : can(regex("^[^|.\"]+$", r.name))])
    error_message = "name must not contain \"|\", \" or . (provider limitation on role identifiers; values with these characters don't survive apply and break imports)."
  }

  validation {
    condition = alltrue(flatten([
      for key, r in var.account_roles : [
        for other_key, n in var.account_roles :
        key == other_key || upper(r.name) != upper(n.name)
      ]
    ]))
    error_message = "account role names must be unique within the account, case-insensitively — two entries sharing a name conflict at apply."
  }
}
