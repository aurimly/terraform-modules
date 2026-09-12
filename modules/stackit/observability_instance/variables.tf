variable "instances" {
  description = "Map of STACKIT Observability instances keyed by an arbitrary identifier. Region is taken from the provider configuration — the resource has no region attribute."
  type = map(object({
    project_id                             = string
    name                                   = string
    plan_name                              = string
    acl                                    = optional(list(string))
    grafana_admin_enabled                  = optional(bool)
    logs_retention_days                    = optional(number)
    traces_retention_days                  = optional(number)
    metrics_retention_days                 = optional(number)
    metrics_retention_days_5m_downsampling = optional(number)
    metrics_retention_days_1h_downsampling = optional(number)
    parameters                             = optional(map(string))
    alert_config = optional(object({
      receivers = list(object({
        name = string
        email_configs = optional(list(object({
          auth_identity = optional(string)
          auth_password = optional(string)
          auth_username = optional(string)
          from          = optional(string)
          send_resolved = optional(bool)
          smart_host    = optional(string)
          to            = optional(string)
        })))
        opsgenie_configs = optional(list(object({
          api_key       = optional(string)
          api_url       = optional(string)
          priority      = optional(string)
          send_resolved = optional(bool)
          tags          = optional(string)
        })))
        webhooks_configs = optional(list(object({
          url           = optional(string)
          ms_teams      = optional(bool)
          google_chat   = optional(bool)
          send_resolved = optional(bool)
        })))
      }))
      route = object({
        receiver        = string
        group_by        = optional(list(string))
        group_wait      = optional(string)
        group_interval  = optional(string)
        repeat_interval = optional(string)
        routes = optional(list(object({
          receiver        = string
          continue        = optional(bool)
          group_by        = optional(list(string))
          group_wait      = optional(string)
          group_interval  = optional(string)
          matchers        = optional(list(string))
          repeat_interval = optional(string)
        })))
      })
      global = optional(object({
        opsgenie_api_key   = optional(string)
        opsgenie_api_url   = optional(string)
        resolve_timeout    = optional(string)
        smtp_auth_identity = optional(string)
        smtp_auth_password = optional(string)
        smtp_auth_username = optional(string)
        smtp_from          = optional(string)
        smtp_smart_host    = optional(string)
      }))
    }))
  }))

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.name) >= 1 && length(i.name) <= 200])
    error_message = "name must be 1-200 characters."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.plan_name) >= 1 && length(i.plan_name) <= 200])
    error_message = "plan_name must be 1-200 characters."
  }

  validation {
    condition = alltrue([
      for i in var.instances : i.acl == null || alltrue([for cidr in i.acl : can(cidrnetmask(cidr))])
    ])
    error_message = "acl entries must be valid IPv4 CIDRs (e.g. 10.1.0.0/16)."
  }

  validation {
    condition = alltrue([
      for i in var.instances : i.alert_config == null || alltrue(flatten([
        for r in i.alert_config.receivers : [
          for w in coalesce(r.webhooks_configs, []) : !(w.ms_teams == true && w.google_chat == true)
        ]
      ]))
    ])
    error_message = "webhooks_configs ms_teams and google_chat cannot both be true (mirrors the provider rule)."
  }

  validation {
    condition = alltrue([
      for i in var.instances : i.metrics_retention_days_5m_downsampling == null || i.metrics_retention_days == null ||
      i.metrics_retention_days_5m_downsampling < i.metrics_retention_days
    ])
    error_message = "metrics_retention_days_5m_downsampling must be less than metrics_retention_days (documented API rule)."
  }

  validation {
    condition = alltrue([
      for i in var.instances : i.metrics_retention_days_1h_downsampling == null || i.metrics_retention_days_5m_downsampling == null ||
      i.metrics_retention_days_1h_downsampling < i.metrics_retention_days_5m_downsampling
    ])
    error_message = "metrics_retention_days_1h_downsampling must be less than metrics_retention_days_5m_downsampling (documented API rule)."
  }
}
