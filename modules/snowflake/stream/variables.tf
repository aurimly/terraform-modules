variable "streams" {
  description = "Map of Snowflake streams on tables keyed by an arbitrary identifier. Each entry creates one snowflake_stream_on_table; the source table may come from snowflake/table or outside Terraform."
  type = map(object({
    database          = string
    schema            = string
    name              = string
    table             = string
    append_only       = optional(bool)
    show_initial_rows = optional(bool)
    copy_grants       = optional(bool, false)
    comment           = optional(string)
    at = optional(object({
      offset    = optional(string)
      statement = optional(string)
      stream    = optional(string)
      timestamp = optional(string)
    }))
    before = optional(object({
      offset    = optional(string)
      statement = optional(string)
      stream    = optional(string)
      timestamp = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for s in var.streams :
      can(regex("^[^|.\"]+$", s.database)) && can(regex("^[^|.\"]+$", s.schema)) && can(regex("^[^|.\"]+$", s.name)) && can(regex("\\S", s.table))
    ])
    error_message = "database, schema and name must not contain \"|\", \" or . (provider limitation on identifiers), and table must be a non-blank fully qualified source-table name."
  }

  validation {
    condition     = alltrue([for k, s in var.streams : s.at == null || s.before == null])
    error_message = "at and before are mutually exclusive — a stream takes a single Time Travel anchor."
  }

  validation {
    condition = alltrue(flatten([
      for k, s in var.streams : [
        for anchor in [s.at, s.before] : [
          anchor == null || length([for v in [anchor.offset, anchor.statement, anchor.stream, anchor.timestamp] : v if v != null]) == 1
        ]
      ]
    ]))
    error_message = "each at/before anchor must set exactly one of offset, statement, stream or timestamp — Snowflake takes a single anchor form."
  }

  validation {
    condition = alltrue(flatten([
      for key, s in var.streams : [
        for other_key, n in var.streams :
        key == other_key || upper(s.database) != upper(n.database) || upper(s.schema) != upper(n.schema) || upper(s.name) != upper(n.name)
      ]
    ]))
    error_message = "stream names must be unique within each (database, schema), case-insensitively — two entries sharing a (database, schema, name) triple conflict at apply."
  }
}
