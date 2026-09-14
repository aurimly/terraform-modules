variable "jobs" {
  description = "Map of Cloud Scheduler jobs keyed by an arbitrary identifier. Each entry creates one google_cloud_scheduler_job."
  type = map(object({
    name             = string
    description      = optional(string)
    schedule         = optional(string)
    time_zone        = optional(string)
    paused           = optional(bool)
    attempt_deadline = optional(string)
    region           = optional(string)
    project_id       = optional(string)
    deletion_policy  = optional(string)
    retry_config = optional(object({
      retry_count          = optional(number)
      max_retry_duration   = optional(string)
      min_backoff_duration = optional(string)
      max_backoff_duration = optional(string)
      max_doublings        = optional(number)
    }))
    pubsub_target = optional(object({
      topic_name = string
      data       = optional(string)
      attributes = optional(map(string))
    }))
    http_target = optional(object({
      uri         = string
      http_method = optional(string)
      body        = optional(string)
      headers     = optional(map(string))
      oauth_token = optional(object({
        service_account_email = string
        scope                 = optional(string)
      }))
      oidc_token = optional(object({
        service_account_email = string
        audience              = optional(string)
      }))
    }))
    app_engine_http_target = optional(object({
      http_method  = optional(string)
      relative_uri = string
      body         = optional(string)
      headers      = optional(map(string))
      app_engine_routing = optional(object({
        service  = optional(string)
        version  = optional(string)
        instance = optional(string)
      }))
    }))
  }))

  validation {
    condition     = alltrue([for j in var.jobs : can(regex("^[a-zA-Z0-9-]{4,100}$", j.name))])
    error_message = "name must be 4 to 100 characters and contain only letters, digits and hyphens (Cloud Scheduler naming rules). Immutable; changing forces replacement."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", j.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], j.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON."
  }

  validation {
    condition     = alltrue([for j in var.jobs : length([for t in [j.pubsub_target, j.http_target, j.app_engine_http_target] : t if t != null]) == 1])
    error_message = "each job must set exactly one of pubsub_target, http_target or app_engine_http_target."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.pubsub_target == null || j.attempt_deadline == null])
    error_message = "attempt_deadline is ignored for pubsub_target jobs and produces an unresolvable diff; omit it."
  }

  validation {
    condition = alltrue([
      for j in var.jobs : j.http_target == null || j.http_target.http_method == null || contains(["POST", "GET", "HEAD", "PUT", "DELETE", "PATCH", "OPTIONS"], j.http_target.http_method)
    ])
    error_message = "http_target.http_method must be one of POST, GET, HEAD, PUT, DELETE, PATCH or OPTIONS."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.http_target == null || j.http_target.oauth_token == null || j.http_target.oidc_token == null])
    error_message = "http_target may set at most one of oauth_token or oidc_token."
  }

  validation {
    condition     = alltrue([for j in var.jobs : j.retry_config == null || j.retry_config.retry_count == null || (j.retry_config.retry_count <= 5 && j.retry_config.retry_count >= 0)])
    error_message = "retry_config.retry_count values greater than 5 and negative values are not allowed."
  }
}
