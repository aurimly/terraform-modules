variable "channels" {
  description = "Map of Monitoring notification channels keyed by an arbitrary identifier. Each entry creates one google_monitoring_notification_channel."
  type = map(object({
    type         = string
    project_id   = optional(string)
    description  = optional(string)
    display_name = optional(string)
    enabled      = optional(bool)
    force_delete = optional(bool)
    labels       = optional(map(string), {})
    user_labels  = optional(map(string), {})
    sensitive_labels = optional(object({
      auth_token             = optional(string)
      password               = optional(string)
      service_key            = optional(string)
      auth_token_wo          = optional(string)
      auth_token_wo_version  = optional(number)
      password_wo            = optional(string)
      password_wo_version    = optional(number)
      service_key_wo         = optional(string)
      service_key_wo_version = optional(number)
    }))
  }))

  validation {
    condition     = alltrue([for c in var.channels : c.display_name != null && c.display_name != ""])
    error_message = "display_name is required on every channel: make it non-empty and unique so channels can be identified at a glance."
  }

  validation {
    condition = alltrue([
      for c in var.channels : c.sensitive_labels == null || (c.sensitive_labels.auth_token == null || c.sensitive_labels.auth_token_wo == null) && (c.sensitive_labels.password == null || c.sensitive_labels.password_wo == null) && (c.sensitive_labels.service_key == null || c.sensitive_labels.service_key_wo == null)
    ])
    error_message = "sensitive_labels may set at most one of auth_token/auth_token_wo, password/password_wo and service_key/service_key_wo each."
  }

  validation {
    condition = alltrue(flatten([
      for c in var.channels : c.sensitive_labels == null ? [true] : [
        c.sensitive_labels.auth_token != null || c.sensitive_labels.auth_token_wo == null || c.sensitive_labels.auth_token_wo_version != null,
        c.sensitive_labels.password != null || c.sensitive_labels.password_wo == null || c.sensitive_labels.password_wo_version != null,
        c.sensitive_labels.service_key != null || c.sensitive_labels.service_key_wo == null || c.sensitive_labels.service_key_wo_version != null,
      ]
    ]))
    error_message = "when passing *_wo write-only variants, also set the matching *_wo_version so updates can be triggered."
  }

  validation {
    condition = alltrue([
      for c in var.channels : length([
        for k in keys(c.labels) : k if c.sensitive_labels != null && contains(["auth_token", "password", "service_key"], k)
      ]) == 0
    ])
    error_message = "sensitive settings (auth_token, password, service_key) must be configured either in labels or sensitive_labels, not both."
  }
}
