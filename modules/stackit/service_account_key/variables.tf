variable "service_account_keys" {
  description = "Map of STACKIT service account keys keyed by an arbitrary identifier. Each entry creates one key for one service account and outputs the credentials JSON."
  type = map(object({
    project_id            = string
    service_account_email = string
    public_key            = optional(string)
    ttl_days              = optional(number)
    rotate_when_changed   = optional(map(string))
  }))

  validation {
    condition     = alltrue([for key in var.service_account_keys : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", key.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for key in var.service_account_keys : length(key.service_account_email) >= 1 && can(regex("@", key.service_account_email))])
    error_message = "service_account_email must be the full service account email (e.g. from the stackit/service_account module's output email)."
  }

  validation {
    condition     = alltrue([for key in var.service_account_keys : key.ttl_days == null || key.ttl_days >= 1])
    error_message = "ttl_days must be at least 1 when set."
  }

  validation {
    condition     = alltrue([for key in var.service_account_keys : key.rotate_when_changed == null || length(key.rotate_when_changed) > 0])
    error_message = "rotate_when_changed must be a non-empty map when set."
  }
}
