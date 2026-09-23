variable "clusters" {
  description = "Map of ECS clusters keyed by an arbitrary identifier. Each entry creates one aws_ecs_cluster plus an optional capacity provider association."
  type = map(object({
    name                      = string
    enable_container_insights = optional(bool)
    execute_command_configuration = optional(object({
      kms_key_id = optional(string)
      logging    = optional(string, "DEFAULT")
      log_configuration = optional(object({
        cloud_watch_log_group_name     = optional(string)
        cloud_watch_encryption_enabled = optional(bool)
        s3_bucket_name                 = optional(string)
        s3_bucket_encryption_enabled   = optional(bool)
        s3_key_prefix                  = optional(string)
      }))
    }))
    capacity_providers = optional(list(string), [])
    default_capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      weight            = optional(number, 0)
      base              = optional(number, 0)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for c in var.clusters : length(c.name) >= 1 && length(c.name) <= 255 && can(regex("^[a-zA-Z0-9_-]+$", c.name))])
    error_message = "name must be 1-255 characters of letters, digits, hyphens and underscores (ECS cluster naming rules)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.execute_command_configuration == null || contains(["DEFAULT", "OVERRIDE", "NONE"], c.execute_command_configuration.logging)])
    error_message = "execute_command_configuration.logging must be one of DEFAULT, OVERRIDE or NONE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.execute_command_configuration == null || c.execute_command_configuration.logging != "OVERRIDE" || c.execute_command_configuration.log_configuration != null])
    error_message = "execute_command_configuration: logging = OVERRIDE requires log_configuration (the API rejects OVERRIDE without a log destination)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : alltrue([for s in c.default_capacity_provider_strategy : contains(c.capacity_providers, s.capacity_provider)])])
    error_message = "default_capacity_provider_strategy entries must reference a capacity provider listed in capacity_providers (the API rejects an unassociated default strategy)."
  }
}
