variable "account_id" {
  description = "Fallback Cloudflare account ID used when a bucket omits its own account_id. Must be set if any bucket omits account_id."
  type        = string
  default     = ""
}

variable "buckets" {
  description = "Map of R2 buckets keyed by an arbitrary unique identifier."
  type = map(object({
    account_id    = optional(string)
    name          = string
    location      = optional(string)
    jurisdiction  = optional(string)
    storage_class = optional(string)
    lifecycle_rules = optional(list(object({
      id      = string
      enabled = optional(bool, true)
      conditions = object({
        prefix = string
      })
      abort_multipart_uploads_transition = optional(object({
        condition = object({
          type    = string
          max_age = number
        })
      }))
      delete_objects_transition = optional(object({
        condition = object({
          type    = string
          max_age = optional(number)
          date    = optional(string)
        })
      }))
      storage_class_transitions = optional(list(object({
        condition = object({
          type    = string
          max_age = optional(number)
          date    = optional(string)
        })
        storage_class = string
      })), [])
    })), [])
    cors_rules = optional(list(object({
      id = optional(string)
      allowed = object({
        methods = list(string)
        origins = list(string)
        headers = optional(list(string))
      })
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })), [])
    custom_domains = optional(list(object({
      domain  = string
      zone_id = string
      enabled = optional(bool, true)
      min_tls = optional(string)
      ciphers = optional(list(string))
    })), [])
    managed_domain = optional(bool)
  }))

  validation {
    condition = alltrue([
      for b in var.buckets : alltrue([
        for r in b.lifecycle_rules : r.abort_multipart_uploads_transition == null || r.abort_multipart_uploads_transition.condition.type == "Age"
      ])
    ])
    error_message = "abort_multipart_uploads_transition.condition.type must be \"Age\"; the API supports only age-based aborts."
  }

  validation {
    condition = alltrue(flatten([
      for b in var.buckets : [
        for r in b.lifecycle_rules : [
          for t in concat(
            try([r.delete_objects_transition.condition], []),
            [for st in r.storage_class_transitions : st.condition]
          ) : t.type == "Age" ? (t.max_age != null && t.date == null) :
          t.type == "Date" ? (t.date != null && t.max_age == null && can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$", t.date))) : false
        ]
      ]
    ]))
    error_message = "transition condition type must be \"Age\" (requires max_age, date must be unset) or \"Date\" (requires date, max_age must be unset); date must be an RFC3339 timestamp."
  }

  validation {
    condition = alltrue([
      for b in var.buckets : alltrue(flatten([
        for r in b.lifecycle_rules : [
          for t in r.storage_class_transitions : t.storage_class == "InfrequentAccess"
        ]
      ]))
    ])
    error_message = "storage_class_transitions.storage_class must be \"InfrequentAccess\"; it is the only supported transition target."
  }

  validation {
    condition = alltrue([
      for b in var.buckets : alltrue([
        for d in b.custom_domains : d.min_tls == null || contains(["1.0", "1.1", "1.2", "1.3"], d.min_tls)
      ])
    ])
    error_message = "custom_domains.min_tls must be one of 1.0, 1.1, 1.2 or 1.3."
  }
}
