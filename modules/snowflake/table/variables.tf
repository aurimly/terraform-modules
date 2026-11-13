variable "tables" {
  description = "Map of Snowflake tables keyed by an arbitrary identifier. Each entry creates one snowflake_table. Provider preview feature — enable it in the consumer's provider block (preview_features_enabled = [\"snowflake_table_resource\"])."
  type = map(object({
    database = string
    schema   = string
    name     = string
    columns = list(object({
      name           = string
      type           = string
      nullable       = optional(bool)
      collate        = optional(string)
      comment        = optional(string)
      masking_policy = optional(string)
      default = optional(object({
        constant   = optional(string)
        expression = optional(string)
        sequence   = optional(string)
      }))
      identity = optional(object({
        start_num = optional(number)
        step_num  = optional(number)
      }))
    }))
    cluster_by                  = optional(list(string))
    change_tracking             = optional(bool)
    comment                     = optional(string)
    data_retention_time_in_days = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for t in var.tables :
      can(regex("^[^|.\"]+$", t.database)) && can(regex("^[^|.\"]+$", t.schema)) && can(regex("^[^|.\"]+$", t.name))
    ])
    error_message = "database, schema and name must not contain \"|\", \" or . (provider limitation on identifiers; values with these characters don't survive apply and break imports)."
  }

  validation {
    condition = alltrue([
      for k, t in var.tables : length(t.columns) >= 1
    ])
    error_message = "columns must contain at least one column per table (the provider requires at least one column block)."
  }

  validation {
    condition = alltrue([
      for k, t in var.tables :
      alltrue([
        for c in t.columns : can(regex("^[^|.\"]+$", c.name))
      ])
    ])
    error_message = "column names must not contain \"|\", \" or . (provider limitation on identifiers; values with these characters don't survive apply)."
  }

  validation {
    condition = alltrue([
      for k, t in var.tables :
      length(distinct([for c in t.columns : upper(c.name)])) == length(t.columns)
    ])
    error_message = "column names must be unique within each table, case-insensitively — duplicate column names conflict at apply."
  }

  validation {
    condition = alltrue([
      for k, t in var.tables :
      alltrue([
        for c in t.columns :
        c.default == null || c.identity == null
      ])
    ])
    error_message = "a column cannot set both default and identity — the provider documents them as mutually exclusive."
  }

  validation {
    condition = alltrue([
      for k, t in var.tables :
      alltrue([
        for c in t.columns :
        c.default == null || length([for v in [c.default.constant, c.default.expression, c.default.sequence] : v if v != null]) == 1
      ])
    ])
    error_message = "a column default must set exactly one of constant, expression or sequence — Snowflake takes a single default form."
  }

  validation {
    condition = alltrue([
      for k, t in var.tables :
      t.data_retention_time_in_days == null || (t.data_retention_time_in_days >= 0 && t.data_retention_time_in_days <= 90)
    ])
    error_message = "data_retention_time_in_days must be between 0 and 90 (Snowflake's maximum retention)."
  }
}
