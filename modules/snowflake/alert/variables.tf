variable "alerts" {
  description = "Map of Snowflake alerts keyed by an arbitrary identifier. Each entry creates one snowflake_alert in the given database and schema."
  type = map(object({
    database  = string
    schema    = string
    name      = string
    warehouse = string
    condition = string
    action    = string
    enabled   = optional(bool, false)
    comment   = optional(string)
    alert_schedule = optional(object({
      interval = optional(number)
      cron = optional(object({
        expression = string
        time_zone  = string
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for a in var.alerts :
      a.alert_schedule == null || ((a.alert_schedule.interval == null) != (a.alert_schedule.cron == null))
    ])
    error_message = "alert_schedule must set exactly one of interval or cron."
  }

  validation {
    condition     = alltrue([for a in var.alerts : a.alert_schedule == null || a.alert_schedule.interval == null || (a.alert_schedule.interval >= 1 && a.alert_schedule.interval <= 1439)])
    error_message = "alert_schedule.interval must be between 1 and 1439 minutes (provider limit, less than 24 hours)."
  }

  validation {
    condition     = alltrue([for a in var.alerts : a.alert_schedule == null || a.alert_schedule.cron == null || can(regex("\\S", a.alert_schedule.cron.expression)) && can(regex("\\S", a.alert_schedule.cron.time_zone))])
    error_message = "alert_schedule.cron requires a non-empty expression (\"minute hours day-of-month month day-of-week\" format) and time_zone (IANA zone, e.g. \"Europe/Paris\")."
  }

  validation {
    condition = alltrue([
      for a in var.alerts :
      can(regex("^[^|]+$", a.database)) && can(regex("^[^|]+$", a.schema)) && can(regex("^[^|]+$", a.name))
    ])
    error_message = "database, schema and name must not contain \"|\" (pipe-separated import identifiers; values containing it would apply but can't be imported afterwards)."
  }
}
