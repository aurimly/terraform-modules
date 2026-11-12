variable "schemas" {
  description = "Map of Snowflake schemas keyed by an arbitrary identifier. Each entry creates one snowflake_schema inside an existing database (created by the database module or outside Terraform)."
  type = map(object({
    database                        = string
    name                            = string
    with_managed_access             = optional(bool)
    is_transient                    = optional(bool)
    comment                         = optional(string)
    data_retention_time_in_days     = optional(number)
    max_data_extension_time_in_days = optional(number)
    default_ddl_collation           = optional(string)
    log_level                       = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for s in var.schemas :
      can(regex("^[^|.\"]+$", s.database)) && can(regex("^[^|.\"]+$", s.name))
    ])
    error_message = "database and name must not contain \"|\", \" or . (provider limitation on schema identifiers; values with these characters don't survive apply and break imports)."
  }

  validation {
    condition     = alltrue([for s in var.schemas : s.log_level == null || contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF"], upper(s.log_level))])
    error_message = "log_level must be one of TRACE, DEBUG, INFO, WARN, ERROR, FATAL or OFF (case-insensitive, matching the provider)."
  }

  validation {
    condition = alltrue([
      for s in var.schemas :
      s.data_retention_time_in_days == null || (s.data_retention_time_in_days >= 0 && s.data_retention_time_in_days <= 90)
    ])
    error_message = "data_retention_time_in_days must be between 0 and 90 (Snowflake's maximum retention)."
  }

  validation {
    condition = alltrue([
      for s in var.schemas :
      s.is_transient != true || s.data_retention_time_in_days == null || s.data_retention_time_in_days <= 1
    ])
    error_message = "transient schemas allow 0 or 1 day of Time Travel — set data_retention_time_in_days to 0 or 1, or leave it unset."
  }

  validation {
    condition = alltrue(flatten([
      for key, s in var.schemas : [
        for other_key, n in var.schemas :
        key == other_key || upper(s.database) != upper(n.database) || upper(s.name) != upper(n.name)
      ]
    ]))
    error_message = "schema names must be unique within each database, case-insensitively — two entries sharing a (database, name) pair conflict at apply."
  }
}
