variable "state_machines" {
  description = "Map of Step Functions state machines keyed by an arbitrary unique identifier. Each entry creates one aws_sfn_state_machine (Standard or Express workflows). Definitions are raw Amazon States Language strings; substitutions stay consumer-side via templatefile()."
  type = map(object({
    name        = optional(string)
    name_prefix = optional(string)
    type        = optional(string, "STANDARD")
    role_arn    = string
    definition  = string
    publish     = optional(bool, false)
    logging_configuration = optional(object({
      log_destination        = optional(string)
      include_execution_data = optional(bool)
      level                  = optional(string)
    }))
    tracing_configuration = optional(object({
      enabled = optional(bool)
    }))
    encryption_configuration = optional(object({
      type                              = string
      kms_key_id                        = optional(string)
      kms_data_key_reuse_period_seconds = optional(number)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for sm in var.state_machines : (sm.name != null) != (sm.name_prefix != null)])
    error_message = "each state machine must set exactly one of name or name_prefix."
  }

  validation {
    condition     = alltrue([for sm in var.state_machines : sm.name == null || length(sm.name) <= 80 && can(regex("^[0-9A-Za-z_-]+$", sm.name))])
    error_message = "name must be 1 to 80 characters of alphanumerics, hyphens and underscores (matches the provider's name validator)."
  }

  validation {
    condition     = alltrue([for sm in var.state_machines : sm.name_prefix == null || length(sm.name_prefix) <= 54 && can(regex("^[0-9A-Za-z_-]+$", sm.name_prefix))])
    error_message = "name_prefix must be 1 to 54 characters of alphanumerics, hyphens and underscores (the provider appends a 26-hex-character suffix, so the prefix is capped at 80 minus 26)."
  }

  validation {
    condition     = alltrue([for sm in var.state_machines : contains(["STANDARD", "EXPRESS"], sm.type)])
    error_message = "type must be STANDARD or EXPRESS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for sm in var.state_machines : length(sm.definition) <= 1048576])
    error_message = "definition must be at most 1 MiB (1048576 characters, the API limit for inline definitions)."
  }

  validation {
    condition = alltrue([
      for sm in var.state_machines :
      sm.logging_configuration == null || sm.logging_configuration.log_destination == null || can(regex("^arn:.+:\\*$", sm.logging_configuration.log_destination))
    ])
    error_message = "logging_configuration.log_destination must be a CloudWatch log-group ARN ending in :* (the provider requires the :* suffix)."
  }

  validation {
    condition     = alltrue([for sm in var.state_machines : sm.logging_configuration == null || sm.logging_configuration.level == null || contains(["ALL", "ERROR", "FATAL", "OFF"], sm.logging_configuration.level)])
    error_message = "logging_configuration.level must be one of ALL, ERROR, FATAL or OFF (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for sm in var.state_machines :
      sm.encryption_configuration == null ||
      (contains(["AWS_OWNED_KEY", "CUSTOMER_MANAGED_KMS_KEY"], sm.encryption_configuration.type) &&
      (sm.encryption_configuration.type != "CUSTOMER_MANAGED_KMS_KEY" || sm.encryption_configuration.kms_key_id != null))
    ])
    error_message = "encryption_configuration.type must be AWS_OWNED_KEY or CUSTOMER_MANAGED_KMS_KEY (case-sensitive), and kms_key_id is required when type is CUSTOMER_MANAGED_KMS_KEY (the API rejects a customer-managed encryption configuration without a key)."
  }
}

variable "activities" {
  description = "Map of Step Functions worker activities (legacy poll-based task tokens via GetActivityTask/SendTask* APIs) keyed by an arbitrary unique identifier. Each entry creates one aws_sfn_activity. Names are required (CreateActivity is idempotent on name) and no name_prefix is offered."
  type = map(object({
    name = string
    encryption_configuration = optional(object({
      type                              = string
      kms_key_id                        = optional(string)
      kms_data_key_reuse_period_seconds = optional(number)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for a in var.activities : length(a.name) <= 80 && can(regex("^[0-9A-Za-z_-]+$", a.name))])
    error_message = "name must be 1 to 80 characters of alphanumerics, hyphens and underscores (stricter than the API: names with other characters are API-valid but lose CloudWatch-Logs-compatible naming)."
  }

  validation {
    condition     = alltrue([for a in var.activities : a.encryption_configuration == null || contains(["AWS_OWNED_KEY", "CUSTOMER_MANAGED_KMS_KEY"], a.encryption_configuration.type)])
    error_message = "encryption_configuration.type must be AWS_OWNED_KEY or CUSTOMER_MANAGED_KMS_KEY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for a in var.activities : a.encryption_configuration == null || a.encryption_configuration.type != "CUSTOMER_MANAGED_KMS_KEY" || a.encryption_configuration.kms_key_id != null])
    error_message = "encryption_configuration.kms_key_id is required when type is CUSTOMER_MANAGED_KMS_KEY (the API rejects a customer-managed encryption configuration without a key)."
  }

  validation {
    condition     = alltrue([for a in var.activities : a.encryption_configuration == null || a.encryption_configuration.kms_data_key_reuse_period_seconds == null || (a.encryption_configuration.kms_data_key_reuse_period_seconds >= 60 && a.encryption_configuration.kms_data_key_reuse_period_seconds <= 900)])
    error_message = "encryption_configuration.kms_data_key_reuse_period_seconds must be between 60 and 900 seconds."
  }
}
