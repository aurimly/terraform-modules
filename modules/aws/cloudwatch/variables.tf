variable "log_groups" {
  description = "Map of CloudWatch log groups keyed by an arbitrary identifier. Each entry creates one aws_cloudwatch_log_group."
  type = map(object({
    name                        = optional(string)
    name_prefix                 = optional(string)
    retention_in_days           = optional(number)
    kms_key_id                  = optional(string)
    log_group_class             = optional(string)
    skip_destroy                = optional(bool, false)
    deletion_protection_enabled = optional(bool)
    tags                        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for g in var.log_groups : (g.name == null) != (g.name_prefix == null)
    ])
    error_message = "exactly one of name or name_prefix must be set per log group."
  }

  validation {
    condition     = alltrue([for g in var.log_groups : g.name == null || can(regex("^[._\\-#/A-Za-z0-9]{1,512}$", g.name))])
    error_message = "name must be 1-512 characters of alphanumerics, '.', '_', '-', '#' or '/' (CloudWatch log group naming rules)."
  }

  validation {
    condition = alltrue([
      for g in var.log_groups : g.name_prefix == null || can(regex("^[._\\-#/A-Za-z0-9]{1,512}$", g.name_prefix))
    ])
    error_message = "name_prefix must be 1-512 characters of alphanumerics, '.', '_', '-', '#' or '/' (CloudWatch log group naming rules)."
  }

  validation {
    condition = alltrue([
      for g in var.log_groups : g.retention_in_days == null || contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], g.retention_in_days)
    ])
    error_message = "retention_in_days must be one of 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288 or 3653 (CloudWatch Logs allowed retention values)."
  }

  validation {
    condition     = alltrue([for g in var.log_groups : g.log_group_class == null || contains(["STANDARD", "INFREQUENT_ACCESS", "DELIVERY"], g.log_group_class)])
    error_message = "log_group_class must be one of STANDARD, INFREQUENT_ACCESS or DELIVERY (case-sensitive)."
  }
}

variable "metric_alarms" {
  description = "Map of CloudWatch metric alarms keyed by an arbitrary identifier. Each entry creates one aws_cloudwatch_metric_alarm using the classic metric path (metric_name/namespace/statistic; metric_query anomaly detection is out of scope)."
  type = map(object({
    alarm_name                = string
    alarm_description         = optional(string)
    namespace                 = string
    metric_name               = string
    dimensions                = optional(map(string), {})
    statistic                 = optional(string)
    extended_statistic        = optional(string)
    period                    = optional(number, 300)
    evaluation_periods        = number
    datapoints_to_alarm       = optional(number)
    threshold                 = number
    comparison_operator       = string
    treat_missing_data        = optional(string, "missing")
    unit                      = optional(string)
    actions_enabled           = optional(bool, true)
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    tags                      = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for a in var.metric_alarms : (a.statistic == null) != (a.extended_statistic == null)
    ])
    error_message = "exactly one of statistic or extended_statistic must be set per alarm."
  }

  validation {
    condition = alltrue([
      for a in var.metric_alarms : a.statistic == null || contains(["SampleCount", "Average", "Sum", "Minimum", "Maximum"], a.statistic)
    ])
    error_message = "statistic must be one of SampleCount, Average, Sum, Minimum or Maximum (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for a in var.metric_alarms : a.comparison_operator == null || contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], a.comparison_operator)
    ])
    error_message = "comparison_operator must be one of GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold or LessThanOrEqualToThreshold (the band/anomaly-detection operators require metric_query alarm support, which this module does not model)."
  }

  validation {
    condition     = alltrue([for a in var.metric_alarms : a.treat_missing_data == null || contains(["missing", "ignore", "breaching", "notBreaching"], a.treat_missing_data)])
    error_message = "treat_missing_data must be one of missing, ignore, breaching or notBreaching (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for a in var.metric_alarms : a.datapoints_to_alarm == null || a.datapoints_to_alarm <= a.evaluation_periods
    ])
    error_message = "datapoints_to_alarm must be less than or equal to evaluation_periods."
  }

  validation {
    condition = alltrue([
      for a in var.metric_alarms : a.period == null || a.period == 10 || a.period == 20 || a.period == 30 || a.period % 60 == 0
    ])
    error_message = "period must be 10, 20, 30 or a multiple of 60 seconds (CloudWatch alarm period rules)."
  }

  validation {
    condition     = alltrue([for a in var.metric_alarms : alltrue([for arn in concat(a.alarm_actions, a.ok_actions, a.insufficient_data_actions) : can(regex("^arn:", arn))])])
    error_message = "alarm_actions, ok_actions and insufficient_data_actions entries must be ARNs (SNS topic ARNs from aws/sns, or other alarm ARNs)."
  }
}

variable "dashboards" {
  description = "Map of CloudWatch dashboards keyed by an arbitrary identifier. Each entry creates one aws_cloudwatch_dashboard; the body is a JSON dashboard document, typically built with jsonencode()."
  type = map(object({
    dashboard_name = string
    dashboard_body = string
  }))
  default = {}

  validation {
    condition     = alltrue([for d in var.dashboards : can(jsondecode(d.dashboard_body))])
    error_message = "dashboard_body must be a valid JSON document."
  }
}
