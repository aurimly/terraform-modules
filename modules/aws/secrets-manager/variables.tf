variable "secrets" {
  description = "Map of Secrets Manager secrets keyed by an arbitrary identifier. Each entry creates one aws_secretsmanager_secret plus an optional secret version (when a payload is set) and an optional rotation schedule."
  type = map(object({
    name                           = optional(string)
    name_prefix                    = optional(string)
    description                    = optional(string)
    kms_key_id                     = optional(string)
    recovery_window_in_days        = optional(number, 30)
    force_overwrite_replica_secret = optional(bool)
    type                           = optional(string)
    secret_string                  = optional(string)
    secret_binary                  = optional(string)
    version_stages                 = optional(list(string))
    replicas = optional(map(object({
      region     = string
      kms_key_id = optional(string)
    })), {})
    rotation = optional(object({
      rotation_lambda_arn = string
      rotate_immediately  = optional(bool)
      rotation_rules = object({
        automatically_after_days = optional(number)
        schedule_expression      = optional(string)
        duration                 = optional(string)
      })
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.secrets : s.name == null || (length(s.name) >= 1 && length(s.name) <= 512 && can(regex("^[a-zA-Z0-9/_+=.@-]+$", s.name)))])
    error_message = "name must be 1 to 512 characters of alphanumerics and /_+=.@- (CreateSecret naming rules)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.name_prefix == null || (length(s.name_prefix) <= 486 && can(regex("^[a-zA-Z0-9/_+=.@-]+$", s.name_prefix)))])
    error_message = "name_prefix must be up to 486 characters of alphanumerics and /_+=.@- (leaves room for the generated suffix under the 512-char name limit)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : contains([0], s.recovery_window_in_days) || (s.recovery_window_in_days >= 7 && s.recovery_window_in_days <= 30)])
    error_message = "recovery_window_in_days must be 0 (immediate, unrecoverable deletion) or between 7 and 30 (DeleteSecret recovery window)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : !(s.secret_string != null && s.secret_binary != null)])
    error_message = "exactly one of secret_string or secret_binary per secret (the API accepts one payload field, not both)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.version_stages == null || s.secret_string != null || s.secret_binary != null])
    error_message = "version_stages requires a payload (secret_string or secret_binary); otherwise it would be silently ignored."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.version_stages == null || alltrue([for stage in s.version_stages : length(stage) > 0])])
    error_message = "version_stages entries must be non-empty."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : alltrue([
        for r in s.replicas : can(regex("^[a-z0-9-]{1,32}$", r.region))
      ])
    ])
    error_message = "replicas.*.region must look like an AWS region (e.g. us-east-1); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.rotation == null || can(regex("^arn:", s.rotation.rotation_lambda_arn))])
    error_message = "rotation.rotation_lambda_arn must be a Lambda function ARN (arn:...)."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : s.rotation == null || (
        (s.rotation.rotation_rules.automatically_after_days != null) != (s.rotation.rotation_rules.schedule_expression != null)
      )
    ])
    error_message = "rotation.rotation_rules requires exactly one of automatically_after_days or schedule_expression (RotateSecret rejects both)."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : s.rotation == null || s.rotation.rotation_rules.automatically_after_days == null || (
        s.rotation.rotation_rules.automatically_after_days >= 1 && s.rotation.rotation_rules.automatically_after_days <= 1000
      )
    ])
    error_message = "rotation.rotation_rules.automatically_after_days must be between 1 and 1000 (RotationRulesType API range)."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : s.rotation == null || s.rotation.rotation_rules.duration == null || (
        s.rotation.rotation_rules.schedule_expression != null && can(regex("^[0-9]{1,2}h$", s.rotation.rotation_rules.duration))
      )
    ])
    error_message = "rotation.rotation_rules.duration requires schedule_expression and must match [0-9]+h, 1–2 digits (API pattern, window starts per the schedule expression)."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : s.rotation == null || s.rotation.rotation_rules.schedule_expression == null || (
        can(regex("^(cron|rate)\\(", s.rotation.rotation_rules.schedule_expression))
      )
    ])
    error_message = "rotation.rotation_rules.schedule_expression must start with cron( or rate( (AWS rejects bad expressions at apply)."
  }
}
