variable "databases" {
  description = "Map of Snowflake databases keyed by an arbitrary identifier. Each entry creates one snowflake_database."
  type = map(object({
    name                            = string
    comment                         = optional(string)
    is_transient                    = optional(bool)
    data_retention_time_in_days     = optional(number)
    max_data_extension_time_in_days = optional(number)
    drop_public_schema_on_creation  = optional(bool)
    default_ddl_collation           = optional(string)
    log_level                       = optional(string)
    replication = optional(object({
      enable_to_account = list(object({
        account_identifier = string
        with_failover      = optional(bool)
      }))
      ignore_edition_check = optional(bool)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for d in var.databases : can(regex("^[^|.\"]+$", d.name))])
    error_message = "name must not contain \"|\", \" or . (provider limitation on database identifiers; values with these characters don't survive apply and break imports)."
  }

  validation {
    condition     = alltrue([for d in var.databases : d.log_level == null || contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF"], upper(d.log_level))])
    error_message = "log_level must be one of TRACE, DEBUG, INFO, WARN, ERROR, FATAL or OFF (case-insensitive, matching the provider)."
  }

  validation {
    condition = alltrue([
      for d in var.databases :
      d.data_retention_time_in_days == null || (d.data_retention_time_in_days >= 0 && d.data_retention_time_in_days <= 90)
    ])
    error_message = "data_retention_time_in_days must be between 0 and 90 (Snowflake's maximum retention)."
  }

  validation {
    condition = alltrue([
      for d in var.databases :
      d.is_transient != true || d.data_retention_time_in_days == null || d.data_retention_time_in_days <= 1
    ])
    error_message = "transient databases allow 0 or 1 day of Time Travel — set data_retention_time_in_days to 0 or 1, or leave it unset."
  }

  validation {
    condition     = alltrue([for d in var.databases : d.replication == null || length(d.replication.enable_to_account) > 0])
    error_message = "replication.enable_to_account must list at least one target account — an empty list is rejected by the provider at apply."
  }

  validation {
    condition = alltrue([
      for d in var.databases : d.replication == null || alltrue([
        for a in d.replication.enable_to_account : can(regex("^[^\".|]+\\.[^\".|]+$", a.account_identifier))
      ])
    ])
    error_message = "replication.enable_to_account.account_identifier must be the plain two-segment <org>.<account> form without quotes, pipes or dots in the segments (quoted identifiers are valid in Snowflake but rejected here)."
  }

  validation {
    condition = alltrue(flatten([
      for key, d in var.databases : [
        for other_key, n in var.databases :
        key == other_key || upper(d.name) != upper(n.name)
      ]
    ]))
    error_message = "database names must be unique within the account, case-insensitively — two entries sharing a name conflict at apply."
  }
}
