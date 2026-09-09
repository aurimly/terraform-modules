variable "keyrings" {
  description = "Map of KMS key rings keyed by an arbitrary identifier. Each entry creates one google_kms_key_ring plus its crypto keys and optional IAM bindings."
  type = map(object({
    name       = string
    location   = string
    project_id = optional(string)
    keys = optional(map(object({
      name            = string
      purpose         = optional(string, "ENCRYPT_DECRYPT")
      rotation_period = optional(string)
      labels          = optional(map(string), {})
      version_template = optional(object({
        algorithm        = string
        protection_level = optional(string)
      }))
      destroy_scheduled_duration    = optional(string)
      import_only                   = optional(bool)
      skip_initial_version_creation = optional(bool)
      deletion_policy               = optional(string)
      role_bindings = optional(map(object({
        role    = string
        members = list(string)
      })), {})
    })), {})
    role_bindings = optional(map(object({
      role    = string
      members = list(string)
    })), {})
  }))

  validation {
    condition     = alltrue([for kr in var.keyrings : can(regex("^[a-zA-Z0-9_-]{1,63}$", kr.name))])
    error_message = "name must be 1 to 63 characters and contain only letters, digits, underscores and hyphens (KMS key ring naming rules)."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for k in kr.keys : can(regex("^[a-zA-Z0-9_-]{1,63}$", k.name))])])
    error_message = "keys.name must be 1 to 63 characters and contain only letters, digits, underscores and hyphens (KMS crypto key naming rules)."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : kr.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", kr.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for k in kr.keys : contains(["ENCRYPT_DECRYPT", "ASYMMETRIC_SIGN", "ASYMMETRIC_DECRYPT", "RAW_ENCRYPT_DECRYPT", "MAC", "KEY_ENCAPSULATION", "AES_WRAPPING"], k.purpose)])])
    error_message = "keys.purpose must be one of ENCRYPT_DECRYPT, ASYMMETRIC_SIGN, ASYMMETRIC_DECRYPT, RAW_ENCRYPT_DECRYPT, MAC, KEY_ENCAPSULATION or AES_WRAPPING (case-sensitive; there are no HARDWARE_* purposes — hardware keys use version_template.protection_level = HSM)."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for k in kr.keys : k.rotation_period == null || (can(regex("^[0-9]+s$", k.rotation_period)) && tonumber(substr(k.rotation_period, 0, length(k.rotation_period) - 1)) >= 86400)])])
    error_message = "keys.rotation_period must be a seconds-suffixed duration string (e.g. 86400s) of at least one day (86400s)."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for k in kr.keys : k.destroy_scheduled_duration == null || (can(regex("^[0-9]+s$", k.destroy_scheduled_duration)) && tonumber(substr(k.destroy_scheduled_duration, 0, length(k.destroy_scheduled_duration) - 1)) >= 86400 && tonumber(substr(k.destroy_scheduled_duration, 0, length(k.destroy_scheduled_duration) - 1)) <= 432000)])])
    error_message = "keys.destroy_scheduled_duration must be a seconds-suffixed duration string (e.g. 86400s) between 86400s (24h) and 432000s (120h)."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for k in kr.keys : k.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], k.deletion_policy)])])
    error_message = "keys.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for k in kr.keys : k.version_template == null || k.version_template.protection_level == null || contains(["SOFTWARE", "HSM", "EXTERNAL", "EXTERNAL_VPC"], k.version_template.protection_level)])])
    error_message = "keys.version_template.protection_level must be one of SOFTWARE, HSM, EXTERNAL or EXTERNAL_VPC (case-sensitive); HSM gives hardware-backed keys."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : length(distinct([for b in kr.role_bindings : b.role])) == length(kr.role_bindings)])
    error_message = "role_bindings.role must be unique within each key ring; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for b in kr.role_bindings : length(b.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for k in kr.keys : length(distinct([for b in k.role_bindings : b.role])) == length(k.role_bindings)])])
    error_message = "keys.role_bindings.role must be unique within each crypto key; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for kr in var.keyrings : alltrue([for k in kr.keys : alltrue([for b in k.role_bindings : length(b.members) > 0])])])
    error_message = "keys.role_bindings.members must contain at least one member."
  }
}
