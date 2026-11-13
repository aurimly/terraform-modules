variable "pipes" {
  description = "Map of Snowflake pipes keyed by an arbitrary identifier. Each entry creates one snowflake_pipe around its COPY statement. Provider preview feature — enable it in the consumer's provider block (preview_features_enabled = [\"snowflake_pipe_resource\"])."
  type = map(object({
    database              = string
    schema                = string
    name                  = string
    copy_statement        = string
    auto_ingest           = optional(bool)
    aws_sns_topic_arn     = optional(string)
    integration           = optional(string)
    error_integration     = optional(string)
    pipe_execution_paused = optional(bool)
    log_event_level       = optional(string)
    comment               = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in var.pipes :
      can(regex("^[^|.\"]+$", p.database)) && can(regex("^[^|.\"]+$", p.schema)) && can(regex("^[^|.\"]+$", p.name)) && can(regex("\\S", p.copy_statement))
    ])
    error_message = "database, schema and name must not contain \"|\", \" or . (provider limitation on identifiers), and copy_statement must be a non-blank COPY statement."
  }

  validation {
    condition = alltrue([
      for k, p in var.pipes :
      p.auto_ingest != true || p.aws_sns_topic_arn != null || p.integration != null
    ])
    error_message = "auto_ingest = true requires a notification source — set aws_sns_topic_arn (AWS) or integration (Azure Event Grid / GCP Pub/Sub notification integration)."
  }

  validation {
    condition = alltrue([
      for k, p in var.pipes : p.log_event_level == null || contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF"], upper(p.log_event_level))
    ])
    error_message = "log_event_level must be one of TRACE, DEBUG, INFO, WARN, ERROR, FATAL or OFF (case-insensitive, matching the provider)."
  }

  validation {
    condition = alltrue(flatten([
      for key, p in var.pipes : [
        for other_key, n in var.pipes :
        key == other_key || upper(p.database) != upper(n.database) || upper(p.schema) != upper(n.schema) || upper(p.name) != upper(n.name)
      ]
    ]))
    error_message = "pipe names must be unique within each (database, schema), case-insensitively — two entries sharing a (database, schema, name) triple conflict at apply."
  }
}
