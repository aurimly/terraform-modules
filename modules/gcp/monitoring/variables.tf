variable "dashboards" {
  description = "Map of Cloud Monitoring dashboards keyed by an arbitrary identifier, given as Cloud Monitoring dashboard JSON."
  type = map(object({
    dashboard_json = string
    project_id     = optional(string)
  }))

  validation {
    condition     = alltrue([for d in var.dashboards : can(jsondecode(d.dashboard_json))])
    error_message = "dashboard_json must be valid JSON."
  }

  validation {
    condition     = alltrue([for d in var.dashboards : can(jsondecode(d.dashboard_json)) && can(jsondecode(d.dashboard_json).displayName)])
    error_message = "dashboard_json must contain a displayName key (Cloud Monitoring dashboard JSON schema)."
  }
}

variable "alert_policies" {
  description = "Map of Cloud Monitoring alert policies keyed by an arbitrary identifier. Notification channels are referenced by resource name and are not managed here."
  type = map(object({
    display_name          = string
    combiner              = string
    project_id            = optional(string)
    enabled               = optional(bool, true)
    notification_channels = optional(list(string), [])
    user_labels           = optional(map(string), {})
    documentation = optional(object({
      content   = string
      mime_type = optional(string, "text/markdown")
      subject   = optional(string)
      links = optional(list(object({
        display_name = optional(string)
        url          = optional(string)
      })), [])
    }))
    alert_strategy = optional(object({
      auto_close = optional(string)
      notification_rate_limit = optional(object({
        period = string
      }))
    }))
    conditions = list(object({
      display_name = string
      condition_threshold = optional(object({
        filter          = string
        duration        = string
        comparison      = string
        threshold_value = optional(number)
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
        evaluation_missing_data = optional(string)
        denominator_filter      = optional(string)
        aggregations = optional(list(object({
          alignment_period     = optional(string)
          per_series_aligner   = optional(string)
          cross_series_reducer = optional(string)
          group_by_fields      = optional(list(string), [])
        })), [])
        denominator_aggregations = optional(list(object({
          alignment_period     = optional(string)
          per_series_aligner   = optional(string)
          cross_series_reducer = optional(string)
          group_by_fields      = optional(list(string), [])
        })), [])
      }))
      condition_absent = optional(object({
        filter   = string
        duration = string
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
        aggregations = optional(list(object({
          alignment_period     = optional(string)
          per_series_aligner   = optional(string)
          cross_series_reducer = optional(string)
          group_by_fields      = optional(list(string), [])
        })), [])
      }))
      condition_monitoring_query_language = optional(object({
        query    = string
        duration = optional(string)
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
        evaluation_missing_data = optional(string)
      }))
      condition_prometheus_query_language = optional(object({
        query               = string
        duration            = optional(string)
        evaluation_interval = optional(string)
      }))
    }))
  }))

  validation {
    condition     = alltrue([for p in var.alert_policies : contains(["OR", "AND", "AND_WITH_MATCHING_RESOURCE"], p.combiner)])
    error_message = "combiner must be one of OR, AND or AND_WITH_MATCHING_RESOURCE (the values the provider accepts)."
  }

  validation {
    condition     = alltrue([for p in var.alert_policies : length(p.conditions) >= 1])
    error_message = "each alert policy requires at least one condition."
  }

  validation {
    condition = alltrue([
      for p in var.alert_policies : alltrue([
        for c in p.conditions : length([
          for t in [
            "condition_threshold",
            "condition_absent",
            "condition_monitoring_query_language",
            "condition_prometheus_query_language",
          ] : t if c[t] != null
        ]) == 1
      ])
    ])
    error_message = "each condition must set exactly one of condition_threshold, condition_absent, condition_monitoring_query_language or condition_prometheus_query_language."
  }

  validation {
    condition     = alltrue([for p in var.alert_policies : alltrue([for c in p.conditions : c.condition_threshold == null || contains(["COMPARISON_GT", "COMPARISON_GE", "COMPARISON_LT", "COMPARISON_LE", "COMPARISON_EQ", "COMPARISON_NE"], c.condition_threshold.comparison)])])
    error_message = "condition_threshold.comparison must be one of COMPARISON_GT, COMPARISON_GE, COMPARISON_LT, COMPARISON_LE, COMPARISON_EQ or COMPARISON_NE."
  }

  validation {
    condition     = alltrue([for p in var.alert_policies : alltrue([for c in p.conditions : c.condition_threshold == null || c.condition_threshold.evaluation_missing_data == null || contains(["EVALUATION_MISSING_DATA_INACTIVE", "EVALUATION_MISSING_DATA_ACTIVE", "EVALUATION_MISSING_DATA_NO_OP"], c.condition_threshold.evaluation_missing_data)])])
    error_message = "condition_threshold.evaluation_missing_data must be one of EVALUATION_MISSING_DATA_INACTIVE, EVALUATION_MISSING_DATA_ACTIVE or EVALUATION_MISSING_DATA_NO_OP."
  }

  validation {
    condition = alltrue([
      for p in var.alert_policies : alltrue(flatten([
        for c in p.conditions : flatten([
          for t in [c.condition_threshold, c.condition_absent] : t == null || t.trigger == null ? [] : [
            (t.trigger.count == null) != (t.trigger.percent == null)
          ]
        ])
      ]))
    ])
    error_message = "trigger requires exactly one of count or percent."
  }

  validation {
    condition     = alltrue([for p in var.alert_policies : p.documentation == null || p.documentation.mime_type == null || contains(["text/markdown", "text/plain"], p.documentation.mime_type)])
    error_message = "documentation.mime_type must be one of text/markdown or text/plain."
  }
}
