variable "buckets" {
  description = "Map of storage buckets keyed by an arbitrary identifier. Each entry creates one google_storage_bucket plus optional IAM bindings."
  type = map(object({
    name                        = string
    location                    = string
    project_id                  = optional(string)
    force_destroy               = optional(bool, false)
    storage_class               = optional(string, "STANDARD")
    uniform_bucket_level_access = optional(bool, true)
    public_access_prevention    = optional(string)
    requester_pays              = optional(bool)
    rpo                         = optional(string)
    default_event_based_hold    = optional(bool)
    enable_object_retention     = optional(bool)
    deletion_policy             = optional(string)
    labels                      = optional(map(string), {})
    versioning                  = optional(bool)
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                                     = optional(number)
        created_before                          = optional(string)
        with_state                              = optional(string)
        matches_storage_class                   = optional(list(string))
        matches_prefix                          = optional(list(string))
        matches_suffix                          = optional(list(string))
        num_newer_versions                      = optional(number)
        size_above_bytes                        = optional(number)
        size_below_bytes                        = optional(number)
        days_since_custom_time                  = optional(number)
        days_since_noncurrent_time              = optional(number)
        custom_time_before                      = optional(string)
        noncurrent_time_before                  = optional(string)
        send_age_if_zero                        = optional(bool)
        send_num_newer_versions_if_zero         = optional(bool)
        send_days_since_custom_time_if_zero     = optional(bool)
        send_days_since_noncurrent_time_if_zero = optional(bool)
      })
    })), [])
    logging = optional(object({
      log_bucket        = string
      log_object_prefix = optional(string)
    }))
    encryption = optional(object({
      default_kms_key_name = string
    }))
    retention_policy = optional(object({
      retention_period = string
      is_locked        = optional(bool, false)
    }))
    soft_delete_policy = optional(object({
      retention_duration_seconds = optional(number)
    }))
    custom_placement_config = optional(object({
      data_locations = set(string)
    }))
    website = optional(object({
      main_page_suffix = optional(string)
      not_found_page   = optional(string)
    }))
    autoclass = optional(object({
      enabled                = bool
      terminal_storage_class = optional(string)
    }))
    cors = optional(list(object({
      origin          = optional(list(string))
      method          = optional(list(string))
      response_header = optional(list(string))
      max_age_seconds = optional(number)
    })), [])
    hierarchical_namespace = optional(bool)
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
    condition     = alltrue([for b in var.buckets : length(b.name) >= 3 && length(b.name) <= 222 && !can(regex("\\.\\.", b.name))])
    error_message = "name must be 3 to 222 characters and must not contain consecutive dots."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for c in split(".", b.name) : can(regex("^[a-z0-9]([-a-z0-9_]{0,61}[a-z0-9])?$", c))])])
    error_message = "name dot-separated components must be 1 to 63 characters, start and end with a lowercase letter or digit, and contain only lowercase letters, digits, hyphens and underscores (GCS naming rules)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : can(regex("^[A-Za-z0-9-]+(\\+[A-Za-z0-9-]+)?$", b.location))])
    error_message = "location must look like a GCS location (e.g. us-central1, US, US-CENTRAL1, or a dual-region US-CENTRAL1+US-EAST1); it is a shape check, not a list of valid locations."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", b.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.public_access_prevention == null || contains(["enforced", "inherited"], b.public_access_prevention)])
    error_message = "public_access_prevention must be one of enforced or inherited (lowercase, as the API expects)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.rpo == null || contains(["DEFAULT", "ASYNC_TURBO"], b.rpo)])
    error_message = "rpo must be one of DEFAULT or ASYNC_TURBO (case-sensitive); ASYNC_TURBO is only valid on turbo-replication buckets (dual/multi-region)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], b.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : contains(["Delete", "SetStorageClass", "AbortIncompleteMultipartUpload"], r.action.type)])])
    error_message = "lifecycle_rules.action.type must be one of Delete, SetStorageClass or AbortIncompleteMultipartUpload (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : r.action.type != "SetStorageClass" || r.action.storage_class != null])])
    error_message = "lifecycle_rules.action.storage_class is required when action.type is SetStorageClass."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.lifecycle_rules : r.condition.with_state == null || contains(["LIVE", "ARCHIVED", "ANY"], r.condition.with_state)])])
    error_message = "lifecycle_rules.condition.with_state must be one of LIVE, ARCHIVED or ANY (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for b in var.buckets : alltrue([
        for r in b.lifecycle_rules : anytrue([
          r.condition.age != null,
          r.condition.created_before != null,
          r.condition.with_state != null,
          r.condition.matches_storage_class != null,
          r.condition.matches_prefix != null,
          r.condition.matches_suffix != null,
          r.condition.num_newer_versions != null,
          r.condition.size_above_bytes != null,
          r.condition.size_below_bytes != null,
          r.condition.days_since_custom_time != null,
          r.condition.days_since_noncurrent_time != null,
          r.condition.custom_time_before != null,
          r.condition.noncurrent_time_before != null,
        ])
      ])
    ])
    error_message = "lifecycle_rules.condition requires at least one substantive field (the send_*_if_zero flags only adjust already-set fields)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.retention_policy == null || (can(regex("^[0-9]+$", b.retention_policy.retention_period)) && tonumber(b.retention_policy.retention_period) >= 86400 && tonumber(b.retention_policy.retention_period) < 3155760000)])
    error_message = "retention_policy.retention_period must be a numeric string between 86400 (one day) and 3155759999 seconds; the provider expects a string since v7."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.soft_delete_policy == null || b.soft_delete_policy.retention_duration_seconds == null || b.soft_delete_policy.retention_duration_seconds == 0 || (b.soft_delete_policy.retention_duration_seconds >= 604800 && b.soft_delete_policy.retention_duration_seconds <= 7776000)])
    error_message = "soft_delete_policy.retention_duration_seconds must be 0 (disables soft delete) or between 604800 (7 days) and 7776000 (90 days)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.custom_placement_config == null || length(b.custom_placement_config.data_locations) >= 1])
    error_message = "custom_placement_config.data_locations requires at least one location (dual-regions use exactly 2)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.autoclass == null || b.autoclass.terminal_storage_class == null || contains(["NEARLINE", "ARCHIVE"], b.autoclass.terminal_storage_class)])
    error_message = "autoclass.terminal_storage_class must be one of NEARLINE or ARCHIVE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.website == null || b.website.main_page_suffix != null || b.website.not_found_page != null])
    error_message = "website requires at least one of main_page_suffix or not_found_page."
  }

  validation {
    condition     = alltrue([for b in var.buckets : b.hierarchical_namespace == null || b.uniform_bucket_level_access != false])
    error_message = "hierarchical_namespace requires uniform_bucket_level_access; set it to true (default) or omit hierarchical_namespace."
  }

  validation {
    condition     = alltrue([for b in var.buckets : length(distinct([for r in b.role_bindings : r.role])) == length(b.role_bindings)])
    error_message = "role_bindings.role must be unique within each bucket; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for b in var.buckets : alltrue([for r in b.role_bindings : length(r.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }
}
