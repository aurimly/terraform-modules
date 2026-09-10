variable "volumes" {
  description = "Map of STACKIT volumes keyed by an arbitrary identifier. Each entry creates one volume."
  type = map(object({
    project_id        = string
    availability_zone = string
    region            = optional(string)
    name              = optional(string)
    description       = optional(string)
    performance_class = optional(string)
    size              = optional(number)
    source = optional(object({
      type = string
      id   = string
    }))
    encryption_parameters = optional(object({
      service_account    = string
      kek_keyring_id     = string
      kek_key_id         = string
      kek_key_version    = number
      key_payload_base64 = optional(string)
    }))
    labels = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for v in var.volumes : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v.project_id))])
    error_message = "project_id must be a STACKIT project UUID."
  }

  validation {
    condition     = alltrue([for v in var.volumes : length(v.availability_zone) >= 1])
    error_message = "availability_zone must be set (e.g. eu01-3); changing it replaces the volume."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.name == null || (length(v.name) >= 1 && length(v.name) <= 63 && can(regex("^[A-Za-z0-9]+((-|_|\\s|\\.)[A-Za-z0-9]+)*$", v.name)))])
    error_message = "name must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, hyphens, underscores, dots and whitespace in between."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.description == null || (length(v.description) >= 1 && length(v.description) <= 127)])
    error_message = "description must be 1 to 127 characters when set."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.size != null || v.source != null])
    error_message = "at least one of size or source must be set."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.size == null || v.size > 0])
    error_message = "size must be greater than 0 when set (gigabytes)."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.source == null || contains(["volume", "image", "snapshot", "backup"], v.source.type)])
    error_message = "source.type must be one of volume, image, snapshot or backup."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.source == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v.source.id))])
    error_message = "source.id must be a UUID of the volume, image, snapshot or backup the volume is created from."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.performance_class == null || (length(v.performance_class) >= 1 && length(v.performance_class) <= 63 && can(regex("^[A-Za-z0-9]+((-|_|\\s|\\.)[A-Za-z0-9]+)*$", v.performance_class)))])
    error_message = "performance_class must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, hyphens, underscores, dots and whitespace in between (e.g. storage_premium_perf1, storage_standard)."
  }

  validation {
    condition     = alltrue([for v in var.volumes : alltrue([for k, val in v.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", val))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }
}
