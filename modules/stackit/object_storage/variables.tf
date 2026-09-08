variable "buckets" {
  description = "Map of STACKIT Object Storage buckets keyed by an arbitrary identifier. Each entry creates one bucket; creating the first bucket (or credentials group/credential) enables Object Storage for the project automatically."
  type = map(object({
    name        = string
    project_id  = string
    region      = optional(string)
    object_lock = optional(bool)
  }))

  validation {
    condition     = alltrue([for b in var.buckets : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", b.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for b in var.buckets : length(b.name) >= 3 && length(b.name) <= 63 && can(regex("^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$", b.name)) && !can(regex("\\.\\.", b.name))])
    error_message = "bucket name must be DNS conform: 3 to 63 characters of lowercase letters, digits, dots and hyphens, starting and ending with a letter or digit, no consecutive dots (the API requires bucket names to be DNS conform)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : !can(regex(",", b.name))])
    error_message = "bucket name must not contain a comma (the import ID is comma-joined)."
  }
}

variable "credentials_groups" {
  description = "Map of STACKIT Object Storage credentials groups keyed by an arbitrary identifier. Each entry creates one credentials group."
  type = map(object({
    name       = string
    project_id = string
    region     = optional(string)
  }))

  validation {
    condition     = alltrue([for g in var.credentials_groups : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", g.project_id))])
    error_message = "project_id must be a UUID."
  }
}

variable "credentials" {
  description = "Map of STACKIT Object Storage credentials keyed by an arbitrary identifier. Each entry creates one S3 credential (access key/secret pair, API-generated) in a credentials group. Use rotate_when_changed to force rotation — see the module README."
  type = map(object({
    project_id            = string
    region                = optional(string)
    credentials_group_id  = optional(string)
    credentials_group_key = optional(string)
    expiration_timestamp  = optional(string)
    rotate_when_changed   = optional(map(string))
  }))

  validation {
    condition     = alltrue([for c in var.credentials : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", c.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for c in var.credentials : (c.credentials_group_id != null) != (c.credentials_group_key != null)])
    error_message = "exactly one of credentials_group_id or credentials_group_key must be set."
  }

  validation {
    condition     = alltrue([for c in var.credentials : c.credentials_group_key == null || can(var.credentials_groups[c.credentials_group_key])])
    error_message = "credentials_group_key must be a key of the credentials_groups map."
  }

  validation {
    condition     = alltrue([for c in var.credentials : c.expiration_timestamp == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(Z|[+-]\\d{2}:\\d{2})$", c.expiration_timestamp))])
    error_message = "expiration_timestamp must be an RFC3339 timestamp with seconds precision and no fractional seconds (e.g. 2027-01-02T03:04:05Z or 2027-01-02T03:04:05+02:00)."
  }
}
