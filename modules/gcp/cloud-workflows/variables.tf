variable "workflows" {
  description = "Map of Workflows workflows keyed by an arbitrary identifier. Each entry creates one google_workflows_workflow."
  type = map(object({
    name                    = string
    region                  = string
    project_id              = optional(string)
    description             = optional(string)
    service_account         = optional(string)
    crypto_key_name         = optional(string)
    call_log_level          = optional(string)
    execution_history_level = optional(string)
    labels                  = optional(map(string), {})
    user_env_vars           = optional(map(string), {})
    tags                    = optional(map(string))
    source_contents         = string
    deletion_protection     = optional(bool, true)
  }))

  validation {
    condition     = alltrue([for w in var.workflows : can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,63}$", w.name))])
    error_message = "name must start with a letter and contain only letters, digits, underscores and dashes (up to 64 chars; Workflows naming rules). Immutable; changing forces replacement."
  }

  validation {
    condition     = alltrue([for w in var.workflows : w.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", w.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for w in var.workflows : w.tags == null || alltrue([for k, v in w.tags : can(regex("^tagKeys/[a-z][a-z0-9_-]{0,99}$", k)) && can(regex("^tagValues/[0-9]+$", v))])])
    error_message = "tags keys must be full tag key names (tagKeys/{tag_key_id}) and values full tag value names (tagValues/{tag_value_id})."
  }

  validation {
    condition = alltrue([
      for w in var.workflows : w.call_log_level == null || contains(["CALL_LOG_LEVEL_UNSPECIFIED", "LOG_ALL_CALLS", "LOG_ERRORS_ONLY", "LOG_NONE"], w.call_log_level)
    ])
    error_message = "call_log_level must be one of CALL_LOG_LEVEL_UNSPECIFIED, LOG_ALL_CALLS, LOG_ERRORS_ONLY or LOG_NONE."
  }

  validation {
    condition = alltrue([
      for w in var.workflows : w.execution_history_level == null || contains(["EXECUTION_HISTORY_LEVEL_UNSPECIFIED", "EXECUTION_HISTORY_BASIC", "EXECUTION_HISTORY_DETAILED"], w.execution_history_level)
    ])
    error_message = "execution_history_level must be one of EXECUTION_HISTORY_LEVEL_UNSPECIFIED, EXECUTION_HISTORY_BASIC or EXECUTION_HISTORY_DETAILED."
  }

  validation {
    condition     = alltrue([for w in var.workflows : length(w.user_env_vars) <= 20 && !anytrue([for k in keys(w.user_env_vars) : startswith(k, "GOOGLE") || startswith(k, "WORKFLOWS") || k == ""])])
    error_message = "user_env_vars accepts at most 20 entries; keys cannot be empty and cannot start with GOOGLE or WORKFLOWS."
  }

  validation {
    condition     = alltrue([for w in var.workflows : can(regex("^projects/[a-z][a-z0-9-]*/locations/[a-z0-9-]*/keyRings/.+/cryptoKeys/.+$", w.crypto_key_name)) if w.crypto_key_name != null])
    error_message = "crypto_key_name must be a full resource name: projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{cryptoKey}."
  }
}
