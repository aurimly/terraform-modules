variable "secrets" {
  description = "Map of Secret Manager secrets keyed by an arbitrary identifier. Omitting the versions map manages payloads out of band; each entry in it creates one google_secret_manager_secret_version plus optional IAM bindings on the secret."
  type = map(object({
    secret_id   = string
    project_id  = optional(string)
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})

    replication = optional(object({
      auto = optional(object({
        customer_managed_encryption = optional(object({
          kms_key_name = string
        }))
      }))
      user_managed = optional(object({
        replicas = list(object({
          location = string
          customer_managed_encryption = optional(object({
            kms_key_name = string
          }))
        }))
      }))
    }))

    rotation = optional(object({
      next_rotation_time = optional(string)
      rotation_period    = optional(string)
    }))
    topics = optional(list(object({
      name = string
    })))

    version_aliases     = optional(map(string))
    version_destroy_ttl = optional(string)
    ttl                 = optional(string)
    deletion_policy     = optional(string)

    versions = optional(map(object({
      secret_data           = optional(string)
      is_secret_data_base64 = optional(bool, false)
      enabled               = optional(bool, true)
      deletion_policy       = optional(string, "DELETE")
    })), {})

    role_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        expression  = string
        description = optional(string)
      }))
    })), {})
  }))

  validation {
    condition     = alltrue([for s in var.secrets : can(regex("^[a-zA-Z0-9_-]{1,255}$", s.secret_id))])
    error_message = "secret_id must be 1 to 255 characters and contain only letters, digits, hyphens and underscores (Secret Manager naming rules)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], s.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : s.replication == null || alltrue([
        anytrue([s.replication.auto != null, s.replication.user_managed != null]),
        !(s.replication.auto != null && s.replication.user_managed != null),
      ])
    ])
    error_message = "replication requires exactly one of auto or user_managed (the API rejects a replication block without a mode, and more than one mode)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.replication == null || s.replication.user_managed == null || length(s.replication.user_managed.replicas) > 0])
    error_message = "replication.user_managed requires at least one replica."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : s.replication == null || s.replication.user_managed == null || alltrue([
        for r in s.replication.user_managed.replicas : can(regex("^[a-z0-9-]{1,32}$", r.location))
      ])
    ])
    error_message = "replication.user_managed.replicas.location must look like a GCP location (e.g. us-central1 or eur4); it is a shape check, not a list of valid locations."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.rotation == null || s.rotation.rotation_period == null || (can(regex("^[0-9]+s$", s.rotation.rotation_period)) && tonumber(trimsuffix(s.rotation.rotation_period, "s")) >= 3600 && tonumber(trimsuffix(s.rotation.rotation_period, "s")) <= 3153600000)])
    error_message = "rotation.rotation_period must be a seconds-suffixed duration string (e.g. 86400s) between 3600s and 3153600000s (100 years)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.rotation == null || s.rotation.next_rotation_time == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}[Tt][0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$", s.rotation.next_rotation_time))])
    error_message = "rotation.next_rotation_time must be an RFC3339 timestamp (e.g. 2025-01-15T08:00:00Z)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.rotation == null || s.rotation.rotation_period == null || s.rotation.next_rotation_time != null])
    error_message = "rotation.next_rotation_time is required when rotation.rotation_period is set."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.rotation == null || (s.topics != null && length(s.topics) > 0)])
    error_message = "topics requires at least one fully-qualified topic when a rotation block is present; the API rejects rotation without a notification topic."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : s.topics == null || alltrue([
        for t in s.topics : can(regex("^projects/[^/]+/topics/[^/]+$", t.name))
      ])
    ])
    error_message = "topics.name must be a fully-qualified topic resource name (projects/{project}/topics/{topic})."
  }

  validation {
    condition     = alltrue([for s in var.secrets : s.version_aliases == null || alltrue([for k in keys(s.version_aliases) : length(k) > 0])])
    error_message = "version_aliases keys must be non-empty."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : alltrue([
        for v in s.versions : v.secret_data != null
      ])
    ])
    error_message = "versions entries require secret_data; there is no other payload field."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : alltrue([
        for v in s.versions : contains(["DELETE", "DISABLE", "ABANDON", "PREVENT"], v.deletion_policy)
      ])
    ])
    error_message = "versions.deletion_policy must be one of DELETE, DISABLE, ABANDON or PREVENT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.secrets : length(distinct([for r in s.role_bindings : r.role])) == length(s.role_bindings)])
    error_message = "role_bindings.role must be unique within each secret; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for s in var.secrets : alltrue([for r in s.role_bindings : length(r.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }
}
