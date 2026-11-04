variable "resource_monitors" {
  description = "Map of Snowflake resource monitors keyed by an arbitrary identifier. Each entry creates one snowflake_resource_monitor."
  type = map(object({
    name                      = string
    credit_quota              = optional(number)
    frequency                 = optional(string)
    start_timestamp           = optional(string)
    end_timestamp             = optional(string)
    notify_triggers           = optional(list(number))
    suspend_trigger           = optional(number)
    suspend_immediate_trigger = optional(number)
    notify_users              = optional(list(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for m in var.resource_monitors : can(regex("^[^|.\"]+$", m.name))])
    error_message = "name must not contain \"|\", \" or . (Snowflake limitation on resource monitor identifiers; values with these characters don't survive apply and break imports)."
  }

  validation {
    condition     = alltrue([for m in var.resource_monitors : m.frequency == null || contains(["MONTHLY", "DAILY", "WEEKLY", "YEARLY", "NEVER"], upper(m.frequency))])
    error_message = "frequency must be one of MONTHLY, DAILY, WEEKLY, YEARLY or NEVER (case-insensitive, matching the provider)."
  }

  validation {
    condition     = alltrue([for m in var.resource_monitors : (m.frequency == null) == (m.start_timestamp == null)])
    error_message = "frequency and start_timestamp must be set together or neither set (Snowflake requires the pair)."
  }

  validation {
    condition = alltrue(flatten([
      for key, m in var.resource_monitors : [
        for other_key, n in var.resource_monitors :
        key == other_key || upper(m.name) != upper(n.name)
      ]
    ]))
    error_message = "resource monitor names must be unique within the account, case-insensitively — two entries sharing a name conflict at apply."
  }
}
