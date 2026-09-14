variable "queues" {
  description = "Map of Cloud Tasks queues keyed by an arbitrary identifier. Each entry creates one google_cloud_tasks_queue plus optional IAM bindings."
  type = map(object({
    name            = string
    location        = string
    project_id      = optional(string)
    desired_state   = optional(string)
    deletion_policy = optional(string)
    rate_limits = optional(object({
      max_dispatches_per_second = optional(number)
      max_concurrent_dispatches = optional(number)
    }))
    retry_config = optional(object({
      max_attempts       = optional(number)
      max_retry_duration = optional(string)
      min_backoff        = optional(string)
      max_backoff        = optional(string)
      max_doublings      = optional(number)
    }))
    stackdriver_logging_config = optional(object({
      sampling_ratio = number
    }))
    http_target = optional(object({
      http_method = optional(string)
      uri_override = optional(object({
        scheme                    = optional(string)
        host                      = optional(string)
        port                      = optional(number)
        uri_override_enforce_mode = optional(string)
        path_override = optional(object({
          path = optional(string)
        }))
        query_override = optional(object({
          query_params = optional(string)
        }))
      }))
      header_overrides = optional(map(string), {})
      oauth_token = optional(object({
        service_account_email = string
        scope                 = optional(string)
      }))
      oidc_token = optional(object({
        service_account_email = string
        audience              = optional(string)
      }))
    }))
    role_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        expression  = string
        description = optional(string)
      }))
    })), {})
  }))

  validation {
    condition     = alltrue([for q in var.queues : can(regex("^[a-zA-Z0-9-]{1,100}$", q.name))])
    error_message = "name must be 1 to 100 characters and contain only letters, digits and hyphens (Cloud Tasks naming rules). Immutable; changing forces replacement."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", q.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.desired_state == null || contains(["RUNNING", "PAUSED"], q.desired_state)])
    error_message = "desired_state must be one of RUNNING or PAUSED. PAUSED queues accept tasks but do not dispatch them."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], q.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON."
  }

  validation {
    condition = alltrue([
      for q in var.queues : (q.rate_limits == null || q.rate_limits.max_dispatches_per_second == null || (q.rate_limits.max_dispatches_per_second > 0 && q.rate_limits.max_dispatches_per_second <= 10000000)) &&
      (q.rate_limits == null || q.rate_limits.max_concurrent_dispatches == null || q.rate_limits.max_concurrent_dispatches > 0)
    ])
    error_message = "rate_limits.max_dispatches_per_second must be between 0 and 10000000 exclusive of 0 and max_concurrent_dispatches must be positive."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.retry_config == null || q.retry_config.max_attempts == null || q.retry_config.max_attempts >= -1])
    error_message = "retry_config.max_attempts must be -1 (unlimited) or a positive number."
  }

  validation {
    condition = alltrue([
      for q in var.queues : q.stackdriver_logging_config == null || (q.stackdriver_logging_config.sampling_ratio >= 0.0 && q.stackdriver_logging_config.sampling_ratio <= 1.0)
    ])
    error_message = "stackdriver_logging_config.sampling_ratio must be between 0.0 and 1.0 inclusive."
  }

  validation {
    condition = alltrue([
      for q in var.queues : q.http_target == null || (q.http_target.http_method != null && contains(["POST", "GET", "HEAD", "PUT", "DELETE", "PATCH", "OPTIONS"], q.http_target.http_method))
    ])
    error_message = "http_target.http_method must be one of POST, GET, HEAD, PUT, DELETE, PATCH or OPTIONS."
  }

  validation {
    condition = alltrue([
      for q in var.queues : q.http_target == null || q.http_target.uri_override == null || q.http_target.uri_override.uri_override_enforce_mode == null || contains(["ALWAYS", "IF_NOT_EXISTS"], q.http_target.uri_override.uri_override_enforce_mode)
    ])
    error_message = "http_target.uri_override.uri_override_enforce_mode must be one of ALWAYS or IF_NOT_EXISTS."
  }

  validation {
    condition = alltrue([
      for q in var.queues : q.http_target == null || q.http_target.uri_override == null || (q.http_target.uri_override.host != null && q.http_target.uri_override.host != "")
    ])
    error_message = "http_target.uri_override.host is required when a URI override is set and cannot be empty."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.http_target == null || q.http_target.oauth_token == null || q.http_target.oidc_token == null])
    error_message = "http_target may set at most one of oauth_token or oidc_token."
  }

  validation {
    condition     = alltrue([for q in var.queues : length(distinct([for r in q.role_bindings : r.role])) == length(q.role_bindings)])
    error_message = "role_bindings.role must be unique within each queue; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for q in var.queues : alltrue([for r in q.role_bindings : length(r.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }
}
