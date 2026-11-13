variable "tasks" {
  description = "Map of Snowflake tasks keyed by an arbitrary identifier. Each entry creates one snowflake_task; DAG wiring uses after/finalize with predecessor task fully qualified names."
  type = map(object({
    database      = string
    schema        = string
    name          = string
    sql_statement = string
    started       = optional(bool, false)
    warehouse     = optional(string)
    when          = optional(string)
    comment       = optional(string)
    config        = optional(string)
    after         = optional(list(string))
    finalize      = optional(string)
    schedule = optional(object({
      seconds    = optional(number)
      minutes    = optional(number)
      hours      = optional(number)
      using_cron = optional(string)
    }))
    target_completion_interval = optional(object({
      seconds = optional(number)
      minutes = optional(number)
      hours   = optional(number)
    }))
    allow_overlapping_execution                   = optional(bool)
    error_integration                             = optional(string)
    execute_as_user                               = optional(string)
    user_task_managed_initial_warehouse_size      = optional(string)
    serverless_task_min_statement_size            = optional(string)
    serverless_task_max_statement_size            = optional(string)
    suspend_task_after_num_failures               = optional(number)
    task_auto_retry_attempts                      = optional(number)
    user_task_timeout_ms                          = optional(number)
    user_task_minimum_trigger_interval_in_seconds = optional(number)
    log_level                                     = optional(string)
    log_event_level                               = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for t in var.tasks :
      can(regex("^[^|.\"]+$", t.database)) && can(regex("^[^|.\"]+$", t.schema)) && can(regex("^[^|.\"]+$", t.name)) &&
      (t.execute_as_user == null || can(regex("^[^|.\"]+$", t.execute_as_user)))
    ])
    error_message = "database, schema, name and execute_as_user must not contain \"|\", \" or . (provider limitation on identifiers; values with these characters don't survive apply and break imports)."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.schedule == null || length([for v in [t.schedule.seconds, t.schedule.minutes, t.schedule.hours, t.schedule.using_cron] : v if v != null]) == 1
    ])
    error_message = "schedule must set exactly one of seconds, minutes, hours or using_cron — Snowflake takes a single schedule form."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.target_completion_interval == null || length([for v in [t.target_completion_interval.seconds, t.target_completion_interval.minutes, t.target_completion_interval.hours] : v if v != null]) == 1
    ])
    error_message = "target_completion_interval must set exactly one of seconds, minutes or hours."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.schedule == null || (length(t.after != null ? t.after : []) == 0 && t.finalize == null)
    ])
    error_message = "a scheduled task cannot be part of a DAG — the provider documents that schedule conflicts with both after and finalize; use after/finalize alone for child tasks."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.warehouse == null || t.user_task_managed_initial_warehouse_size == null
    ])
    error_message = "set either warehouse (server-managed) or user_task_managed_initial_warehouse_size (serverless) — the provider documents them as mutually exclusive."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.after == null || alltrue([for a in t.after : can(regex("\\S", a))])
    ])
    error_message = "after entries must be non-empty fully qualified names of predecessor tasks."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.config == null || (can(jsondecode(t.config)) && !can(regex("\\$\\$", t.config)))
    ])
    error_message = "config must parse as JSON and must not contain \"$$\" (the provider wraps the config in $$ delimiters)."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.user_task_managed_initial_warehouse_size == null || contains(["XSMALL", "X-SMALL", "SMALL", "MEDIUM", "LARGE", "XLARGE", "X-LARGE", "XXLARGE", "X2LARGE", "2X-LARGE", "XXXLARGE", "X3LARGE", "3X-LARGE", "X4LARGE", "4X-LARGE", "X5LARGE", "5X-LARGE", "X6LARGE", "6X-LARGE"], upper(t.user_task_managed_initial_warehouse_size))
    ])
    error_message = "user_task_managed_initial_warehouse_size must be one of the warehouse sizes the provider accepts (canonical XSMALL..X6LARGE names or their hyphenated/nominal aliases, case-insensitive)."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.serverless_task_min_statement_size == null || contains(["XSMALL", "X-SMALL", "SMALL", "MEDIUM", "LARGE", "XLARGE", "X-LARGE", "XXLARGE", "X2LARGE", "2X-LARGE", "XXXLARGE", "X3LARGE", "3X-LARGE", "X4LARGE", "4X-LARGE", "X5LARGE", "5X-LARGE", "X6LARGE", "6X-LARGE"], upper(t.serverless_task_min_statement_size))
    ])
    error_message = "serverless_task_min_statement_size must be one of the warehouse sizes the provider accepts (canonical XSMALL..X6LARGE names or their hyphenated/nominal aliases, case-insensitive)."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      t.serverless_task_max_statement_size == null || contains(["XSMALL", "X-SMALL", "SMALL", "MEDIUM", "LARGE", "XLARGE", "X-LARGE", "XXLARGE", "X2LARGE", "2X-LARGE", "XXXLARGE", "X3LARGE", "3X-LARGE", "X4LARGE", "4X-LARGE", "X5LARGE", "5X-LARGE", "X6LARGE", "6X-LARGE"], upper(t.serverless_task_max_statement_size))
    ])
    error_message = "serverless_task_max_statement_size must be one of the warehouse sizes the provider accepts (canonical XSMALL..X6LARGE names or their hyphenated/nominal aliases, case-insensitive)."
  }

  validation {
    condition = alltrue([
      for k, t in var.tasks :
      (t.log_level == null || contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF"], upper(t.log_level))) &&
      (t.log_event_level == null || contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF"], upper(t.log_event_level)))
    ])
    error_message = "log_level and log_event_level must be one of TRACE, DEBUG, INFO, WARN, ERROR, FATAL or OFF (case-insensitive, matching the provider)."
  }

  validation {
    condition = alltrue(flatten([
      for key, t in var.tasks : [
        for other_key, n in var.tasks :
        key == other_key || upper(t.database) != upper(n.database) || upper(t.schema) != upper(n.schema) || upper(t.name) != upper(n.name)
      ]
    ]))
    error_message = "task names must be unique within each (database, schema), case-insensitively — two entries sharing a (database, schema, name) triple conflict at apply."
  }
}
