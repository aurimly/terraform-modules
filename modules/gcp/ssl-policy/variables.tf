variable "ssl_policies" {
  description = "Map of SSL policies keyed by an arbitrary identifier. Each entry creates one google_compute_ssl_policy."
  type = map(object({
    name                      = string
    project_id                = optional(string)
    description               = optional(string)
    profile                   = optional(string)
    min_tls_version           = optional(string)
    post_quantum_key_exchange = optional(string)
    custom_features           = optional(list(string))
  }))

  validation {
    condition     = alltrue([for k, s in var.ssl_policies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", s.name))])
    error_message = "name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, s in var.ssl_policies : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, s in var.ssl_policies : s.profile == null || contains(["COMPATIBLE", "MODERN", "RESTRICTED", "CUSTOM", "FIPS_202205"], s.profile)])
    error_message = "profile must be one of COMPATIBLE, MODERN, RESTRICTED, CUSTOM or FIPS_202205 (case-sensitive; defaults to COMPATIBLE)."
  }

  validation {
    condition     = alltrue([for k, s in var.ssl_policies : s.min_tls_version == null || contains(["TLS_1_0", "TLS_1_1", "TLS_1_2", "TLS_1_3"], s.min_tls_version)])
    error_message = "min_tls_version must be one of TLS_1_0, TLS_1_1, TLS_1_2 or TLS_1_3 (case-sensitive; defaults to TLS_1_0)."
  }

  validation {
    condition     = alltrue([for k, s in var.ssl_policies : s.min_tls_version != "TLS_1_3" || s.profile == "RESTRICTED"])
    error_message = "min_tls_version TLS_1_3 requires profile RESTRICTED."
  }

  validation {
    condition     = alltrue([for k, s in var.ssl_policies : s.profile != "FIPS_202205" || s.min_tls_version == "TLS_1_2"])
    error_message = "profile FIPS_202205 requires min_tls_version TLS_1_2."
  }

  validation {
    condition     = alltrue([for k, s in var.ssl_policies : (s.profile == "CUSTOM") == (length(coalesce(s.custom_features, [])) > 0)])
    error_message = "profile CUSTOM requires custom_features to be set, and custom_features can only be set with profile CUSTOM."
  }

  validation {
    condition     = alltrue([for k, s in var.ssl_policies : s.post_quantum_key_exchange == null || contains(["DEFAULT", "ENABLED", "DEFERRED"], s.post_quantum_key_exchange)])
    error_message = "post_quantum_key_exchange must be one of DEFAULT, ENABLED or DEFERRED (case-sensitive)."
  }
}
