variable "views" {
  description = "Map of Snowflake views keyed by an arbitrary identifier. Each entry creates one snowflake_view from its SELECT statement."
  type = map(object({
    database        = string
    schema          = string
    name            = string
    statement       = string
    is_secure       = optional(bool)
    is_recursive    = optional(bool)
    change_tracking = optional(bool)
    copy_grants     = optional(bool, false)
    comment         = optional(string)
    columns = optional(list(object({
      column_name = string
      comment     = optional(string)
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in var.views :
      can(regex("^[^|.\"]+$", v.database)) && can(regex("^[^|.\"]+$", v.schema)) && can(regex("^[^|.\"]+$", v.name))
    ])
    error_message = "database, schema and name must not contain \"|\", \" or . (provider limitation on identifiers; values with these characters don't survive apply and break imports)."
  }

  validation {
    condition     = alltrue([for v in var.views : can(regex("\\S", v.statement))])
    error_message = "statement must be a non-blank SELECT (it is sent to Snowflake verbatim)."
  }

  validation {
    condition = alltrue(flatten([
      for key, v in var.views : [
        for other_key, n in var.views :
        key == other_key || upper(v.database) != upper(n.database) || upper(v.schema) != upper(n.schema) || upper(v.name) != upper(n.name)
      ]
    ]))
    error_message = "view names must be unique within each (database, schema), case-insensitively — two entries sharing a (database, schema, name) triple conflict at apply."
  }

  validation {
    condition = alltrue([
      for k, v in var.views :
      v.columns == null || length(distinct([for c in v.columns : upper(c.column_name)])) == length(v.columns)
    ])
    error_message = "column aliases must be unique within each view, case-insensitively — duplicate column aliases conflict at apply."
  }
}
