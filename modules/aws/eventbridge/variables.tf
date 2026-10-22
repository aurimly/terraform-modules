variable "event_buses" {
  description = "Map of event buses keyed by an arbitrary identifier. Each entry creates one aws_cloudwatch_event_bus plus optional policy and archives. Set `name` for a custom bus; set it to the partner event source and also pass `event_source_name` for a partner bus."
  type = map(object({
    name              = string
    event_source_name = optional(string)
    description       = optional(string)
    policy            = optional(string)
    archives = optional(map(object({
      name             = string
      description      = optional(string)
      event_source_arn = optional(string)
      retention_days   = optional(number)
      event_pattern    = optional(string)
      kms_key_arn      = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for b in var.event_buses : length(b.name) <= 256 && can(regex("^[a-zA-Z0-9_.-]+$", b.name))])
    error_message = "name must be up to 256 characters of alphanumerics, underscores, periods and hyphens (EventBridge bus naming rules)."
  }

  validation {
    condition     = alltrue([for b in var.event_buses : b.policy == null || can(jsondecode(b.policy))])
    error_message = "policy must be a valid JSON policy document."
  }

  validation {
    condition = alltrue(flatten([
      for b in var.event_buses : [
        for a in b.archives : length(a.name) <= 48 && can(regex("^[a-zA-Z0-9_.-]+$", a.name))
      ]
    ]))
    error_message = "archives.name must be up to 48 characters of alphanumerics, underscores, periods and hyphens (EventBridge archive naming rules)."
  }

  validation {
    condition = alltrue(flatten([
      for b in var.event_buses : [
        for a in b.archives : a.retention_days == null || a.retention_days > 0
      ]
    ]))
    error_message = "archives.retention_days must be positive when set; a null retention_days (together with a null event_pattern) archives with no delete date."
  }

  validation {
    condition = alltrue(flatten([
      for b in var.event_buses : [
        for a in b.archives : a.event_pattern == null || can(jsondecode(a.event_pattern))
      ]
    ]))
    error_message = "archives.event_pattern must be a valid JSON event pattern document."
  }

  validation {
    condition     = alltrue([for b in var.event_buses : b.event_source_name == null || can(regex("^aws\\.partner/.+", b.event_source_name))])
    error_message = "event_source_name must be an aws.partner/... ARN prefix (partner event sources only)."
  }
}

variable "rules" {
  description = "Map of event rules keyed by an arbitrary identifier, with targets attached per rule. Each entry creates one aws_cloudwatch_event_rule; every entry in `targets` creates one aws_cloudwatch_event_target on that rule. Names must be unique per bus — two keys may share a `name` only if they resolve to different buses (validated)."
  type = map(object({
    name                = string
    event_bus_key       = optional(string)
    event_bus_name      = optional(string)
    description         = optional(string)
    schedule_expression = optional(string)
    event_pattern       = optional(string)
    role_arn            = optional(string)
    state               = optional(string)
    force_destroy       = optional(bool, false)
    targets = optional(map(object({
      arn              = string
      target_id        = optional(string)
      role_arn         = optional(string)
      input            = optional(string)
      input_path       = optional(string)
      dead_letter_arn  = optional(string)
      message_group_id = optional(string)
      retry_policy = optional(object({
        maximum_event_age_in_seconds = optional(number)
        maximum_retry_attempts       = optional(number)
      }), {})
      batch_parameters = optional(object({
        job_definition = string
        job_name       = string
        array_size     = optional(number)
        job_attempts   = optional(number)
      }))
      http_parameters = optional(object({
        path_parameter_values   = optional(list(string))
        query_string_parameters = optional(map(string))
        header_parameters       = optional(map(string))
      }))
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.rules : can(regex("^[.\\-_A-Za-z0-9]{1,64}$", r.name))])
    error_message = "name must be up to 64 characters of periods, hyphens, underscores, alphanumerics (EventBridge rule naming rules)."
  }

  validation {
    condition     = length(var.rules) == length(distinct([for k, r in var.rules : "${r.event_bus_key != null ? "K:${r.event_bus_key}" : "N:${r.event_bus_name == null ? "" : r.event_bus_name}"}.${r.name}"]))
    error_message = "rule names must be unique per bus: two keys sharing a name must live on different buses (coalesce uses event_bus_key or event_bus_name as the bus identifier here)."
  }

  validation {
    condition     = alltrue([for r in var.rules : r.event_bus_name == null || can(regex("^[a-zA-Z0-9_.-]+$", r.event_bus_name))])
    error_message = "event_bus_name must be a literal bus name (e.g. \"default\") matching EventBridge bus naming rules."
  }

  validation {
    condition     = alltrue([for r in var.rules : r.state == null || contains(["ENABLED", "DISABLED"], r.state)])
    error_message = "state must be one of ENABLED or DISABLED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.rules : r.schedule_expression == null || can(regex("^(cron|rate)\\(", r.schedule_expression))])
    error_message = "schedule_expression must start with cron(...) or rate(...) (EventBridge rule scheduling syntax)."
  }

  validation {
    condition     = alltrue([for r in var.rules : r.event_pattern == null || can(jsondecode(r.event_pattern))])
    error_message = "event_pattern must be a valid JSON event pattern document."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.rules : [
        for t in r.targets : t.retry_policy.maximum_retry_attempts == null || t.retry_policy.maximum_retry_attempts >= 0
      ]
    ]))
    error_message = "targets.retry_policy.maximum_retry_attempts must be >= 0."
  }
}

variable "schedules" {
  description = "Map of EventBridge Scheduler schedules keyed by an arbitrary identifier. Independent of the buses/rules maps above (the Scheduler API is separate); a schedule invokes one target, which always needs a `role_arn`. Schedules reference schedule groups by literal `group_name` (omit it for the implicit `default` group)."
  type = map(object({
    name                         = string
    group_name                   = optional(string)
    description                  = optional(string)
    schedule_expression          = string
    schedule_expression_timezone = optional(string)
    start_date                   = optional(string)
    end_date                     = optional(string)
    state                        = optional(string)
    kms_key_arn                  = optional(string)
    flexible_time_window = optional(object({
      mode                      = optional(string, "OFF")
      maximum_window_in_minutes = optional(number)
    }), {})
    target = object({
      arn                     = string
      role_arn                = string
      input                   = optional(string)
      dead_letter_arn         = optional(string)
      action_after_completion = optional(string)
      retry_policy = optional(object({
        maximum_event_age_in_seconds = optional(number)
        maximum_retry_attempts       = optional(number)
      }), {})
    })
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.schedules : can(regex("^[a-zA-Z0-9_.-]{1,64}$", s.name))])
    error_message = "name must be up to 64 characters of alphanumerics, underscores, periods and hyphens (Scheduler naming rules)."
  }

  validation {
    condition     = alltrue([for s in var.schedules : can(regex("^(cron|rate|at)\\(", s.schedule_expression))])
    error_message = "schedule_expression must start with cron(...), rate(...) or at(...) (one-time schedules use at)."
  }

  validation {
    condition     = alltrue([for s in var.schedules : s.state == null || contains(["ENABLED", "DISABLED"], s.state)])
    error_message = "state must be one of ENABLED or DISABLED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.schedules : s.flexible_time_window.mode == null || contains(["OFF", "FLEXIBLE"], s.flexible_time_window.mode)])
    error_message = "flexible_time_window.mode must be one of OFF or FLEXIBLE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.schedules : s.flexible_time_window.maximum_window_in_minutes == null || s.flexible_time_window.maximum_window_in_minutes > 0 && s.flexible_time_window.maximum_window_in_minutes <= 1440])
    error_message = "flexible_time_window.maximum_window_in_minutes must be between 1 and 1440 (Scheduler caps the window at one day)."
  }

  validation {
    condition     = alltrue([for s in var.schedules : s.target.action_after_completion == null || contains(["DELETE", "NONE"], s.target.action_after_completion)])
    error_message = "target.action_after_completion must be one of DELETE or NONE (case-sensitive). DELETE deletes the one-time schedule itself after its final invocation completes; NONE keeps it."
  }

  validation {
    condition     = alltrue([for s in var.schedules : s.target.input == null || can(jsondecode(s.target.input))])
    error_message = "target.input must be a valid JSON payload document."
  }

  validation {
    condition     = alltrue([for s in var.schedules : s.target.retry_policy.maximum_retry_attempts == null || s.target.retry_policy.maximum_retry_attempts >= 0 && s.target.retry_policy.maximum_retry_attempts <= 185])
    error_message = "target.retry_policy.maximum_retry_attempts must be between 0 and 185 (Scheduler retry policy limits)."
  }

  validation {
    condition     = alltrue([for s in var.schedules : s.target.retry_policy.maximum_event_age_in_seconds == null || s.target.retry_policy.maximum_event_age_in_seconds >= 60 && s.target.retry_policy.maximum_event_age_in_seconds <= 86400])
    error_message = "target.retry_policy.maximum_event_age_in_seconds must be between 60 and 86400 (Scheduler retry policy limits)."
  }

  validation {
    condition     = alltrue([for s in var.schedules : s.group_name == null || can(regex("^[a-zA-Z0-9_.-]{1,64}$", s.group_name))])
    error_message = "group_name must be up to 64 characters of alphanumerics, underscores, periods and hyphens; omit for the default group."
  }
}

variable "schedule_groups" {
  description = "Map of EventBridge Scheduler schedule groups keyed by an arbitrary identifier. Standalone namespace objects: schedules reference them by literal `group_name` (no in-module key resolution)."
  type = map(object({
    name = string
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for g in var.schedule_groups : can(regex("^[a-zA-Z0-9_.-]{1,64}$", g.name))])
    error_message = "name must be up to 64 characters of alphanumerics, underscores, periods and hyphens (Scheduler group naming rules)."
  }
}
