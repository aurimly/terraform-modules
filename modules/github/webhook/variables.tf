variable "repository_webhooks" {
  description = "Map of repository webhooks keyed by an arbitrary stable identifier — not the payload URL. Each entry pins one webhook to one repository."
  type = map(object({
    repository = string
    events     = list(string)
    configuration = object({
      url          = string
      content_type = string
      secret       = optional(string)
      insecure_ssl = optional(bool, false)
    })
    active = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, hook in var.repository_webhooks : contains(["form", "json"], hook.configuration.content_type)
    ])
    error_message = "repository_webhooks configuration content_type must be \"form\" or \"json\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for key, hook in var.repository_webhooks : length(hook.events) > 0
    ])
    error_message = "repository_webhooks events must list at least one event."
  }
}

variable "organization_webhooks" {
  description = "Map of organization webhooks keyed by an arbitrary stable identifier. Requires a token with admin:org_hook scope — organization webhooks cannot be managed with repository-scoped tokens."
  type = map(object({
    events = list(string)
    configuration = object({
      url          = string
      content_type = string
      secret       = optional(string)
      insecure_ssl = optional(bool, false)
    })
    active = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, hook in var.organization_webhooks : contains(["form", "json"], hook.configuration.content_type)
    ])
    error_message = "organization_webhooks configuration content_type must be \"form\" or \"json\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for key, hook in var.organization_webhooks : length(hook.events) > 0
    ])
    error_message = "organization_webhooks events must list at least one event."
  }
}
