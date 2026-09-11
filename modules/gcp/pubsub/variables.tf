variable "topics" {
  description = "Map of Pub/Sub topics keyed by an arbitrary identifier. Each entry creates one google_pubsub_topic plus optional nested subscriptions and IAM bindings."
  type = map(object({
    name       = string
    project_id = optional(string)
    labels     = optional(map(string), {})

    message_retention_duration = optional(string)
    deletion_policy            = optional(string)
    kms_key_name               = optional(string)

    schema_settings = optional(object({
      schema            = string
      encoding          = optional(string)
      first_revision_id = optional(string)
      last_revision_id  = optional(string)
    }))

    message_storage_policy = optional(object({
      allowed_persistence_regions = list(string)
      enforce_in_transit          = optional(bool)
    }))

    subscriptions = optional(map(object({
      name       = string
      project_id = optional(string)
      labels     = optional(map(string), {})

      ack_deadline_seconds         = optional(number, 10)
      message_retention_duration   = optional(string)
      retain_acked_messages        = optional(bool)
      deletion_policy              = optional(string)
      enable_message_ordering      = optional(bool, false)
      enable_exactly_once_delivery = optional(bool)
      filter                       = optional(string)

      expiration_policy = optional(object({
        ttl = optional(string, "")
      }))

      dead_letter_policy = optional(object({
        dead_letter_topic     = string
        max_delivery_attempts = optional(number)
      }))

      retry_policy = optional(object({
        minimum_backoff = optional(string)
        maximum_backoff = optional(string)
      }))

      push_config = optional(object({
        push_endpoint = string
        attributes    = optional(map(string))
        no_wrapper = optional(object({
          write_metadata = bool
        }))
        oidc_token = optional(object({
          service_account_email = string
          audience              = optional(string)
        }))
      }))

      bigquery_config = optional(object({
        table                 = string
        use_topic_schema      = optional(bool)
        use_table_schema      = optional(bool)
        write_metadata        = optional(bool)
        drop_unknown_fields   = optional(bool)
        service_account_email = optional(string)
      }))

      cloud_storage_config = optional(object({
        bucket                   = string
        filename_prefix          = optional(string)
        filename_suffix          = optional(string)
        filename_datetime_format = optional(string)
        max_duration             = optional(string)
        max_bytes                = optional(number)
        max_messages             = optional(number)
        service_account_email    = optional(string)
        text_config              = optional(bool)
        avro_config = optional(object({
          write_metadata   = optional(bool)
          use_topic_schema = optional(bool)
        }))
      }))

      role_bindings = optional(map(object({
        role    = string
        members = list(string)
        condition = optional(object({
          title       = string
          expression  = string
          description = optional(string)
        }))
      })), {})
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
    condition     = alltrue([for t in var.topics : can(regex("^[a-zA-Z][a-zA-Z0-9-_.~+%]{2,254}$", t.name))])
    error_message = "name must be 3 to 255 characters, starting with a letter (Pub/Sub topic naming rules)."
  }

  validation {
    condition     = alltrue([for t in var.topics : t.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", t.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for t in var.topics : t.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], t.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.topics : t.message_retention_duration == null || (can(regex("^[0-9]+s$", t.message_retention_duration)) && tonumber(trimsuffix(t.message_retention_duration, "s")) >= 600 && tonumber(trimsuffix(t.message_retention_duration, "s")) <= 2678400)])
    error_message = "message_retention_duration must be a seconds-suffixed duration string between 600s (10 minutes) and 2678400s (31 days)."
  }

  validation {
    condition     = alltrue([for t in var.topics : t.schema_settings == null || t.schema_settings.encoding == null || contains(["JSON", "BINARY"], t.schema_settings.encoding)])
    error_message = "schema_settings.encoding must be one of JSON or BINARY (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : length([for v in [s.push_config != null, s.bigquery_config != null, s.cloud_storage_config != null] : v if v]) <= 1
      ])
    ])
    error_message = "subscriptions allow at most one of push_config, bigquery_config or cloud_storage_config; none set means a pull subscription, multiple sink configs conflict."
  }

  validation {
    condition     = alltrue([for t in var.topics : alltrue([for s in t.subscriptions : can(regex("^[a-zA-Z][a-zA-Z0-9-_.~+%]{2,254}$", s.name))])])
    error_message = "subscriptions.name must be 3 to 255 characters, starting with a letter (Pub/Sub subscription naming rules)."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))
      ])
    ])
    error_message = "subscriptions.project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.ack_deadline_seconds == null || s.ack_deadline_seconds == 0 || (s.ack_deadline_seconds >= 10 && s.ack_deadline_seconds <= 600)
      ])
    ])
    error_message = "subscriptions.ack_deadline_seconds must be 0 (never time out; push only) or between 10 and 600 seconds."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.message_retention_duration == null || (can(regex("^[0-9]+s$", s.message_retention_duration)) && tonumber(trimsuffix(s.message_retention_duration, "s")) >= 600 && tonumber(trimsuffix(s.message_retention_duration, "s")) <= 2678400)
      ])
    ])
    error_message = "subscriptions.message_retention_duration must be a seconds-suffixed duration string between 600s (10 minutes) and 2678400s (31 days)."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.expiration_policy == null || s.expiration_policy.ttl == "" || (can(regex("^[0-9]+s$", s.expiration_policy.ttl)) && tonumber(trimsuffix(s.expiration_policy.ttl, "s")) >= 86400)
      ])
    ])
    error_message = "subscriptions.expiration_policy.ttl must be an empty string (never expire) or a seconds-suffixed duration string of at least 86400s (1 day)."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.dead_letter_policy == null || can(regex("^projects/[^/]+/topics/[^/]+$", s.dead_letter_policy.dead_letter_topic))
      ])
    ])
    error_message = "subscriptions.dead_letter_policy.dead_letter_topic must be a fully-qualified topic resource name (projects/{project}/topics/{topic})."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.dead_letter_policy == null || s.dead_letter_policy.max_delivery_attempts == null || (s.dead_letter_policy.max_delivery_attempts >= 5 && s.dead_letter_policy.max_delivery_attempts <= 100)
      ])
    ])
    error_message = "subscriptions.dead_letter_policy.max_delivery_attempts must be between 5 and 100."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.retry_policy == null || alltrue([
          s.retry_policy.minimum_backoff == null || can(regex("^[0-9]+s$", s.retry_policy.minimum_backoff)),
          s.retry_policy.maximum_backoff == null || can(regex("^[0-9]+s$", s.retry_policy.maximum_backoff)),
          s.retry_policy.minimum_backoff == null || s.retry_policy.maximum_backoff == null || !(can(regex("^[0-9]+s$", s.retry_policy.minimum_backoff)) && can(regex("^[0-9]+s$", s.retry_policy.maximum_backoff))) || tonumber(trimsuffix(s.retry_policy.minimum_backoff, "s")) <= tonumber(trimsuffix(s.retry_policy.maximum_backoff, "s")),
        ])
      ])
    ])
    error_message = "subscriptions.retry_policy.minimum_backoff and maximum_backoff must be seconds-suffixed duration strings and the minimum must not exceed the maximum."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.bigquery_config == null || can(regex("^[^.]+\\.[^.]+\\.[^.]+$", s.bigquery_config.table))
      ])
    ])
    error_message = "subscriptions.bigquery_config.table must be in {projectId}.{datasetId}.{tableId} format (dot-separated), e.g. example-prj.example_dataset.example_table."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.cloud_storage_config == null || length(s.cloud_storage_config.bucket) > 0
      ])
    ])
    error_message = "subscriptions.cloud_storage_config.bucket must be non-empty."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : s.cloud_storage_config == null || s.cloud_storage_config.max_duration == null || s.cloud_storage_config.max_duration == "" || (can(regex("^[0-9]+s$", s.cloud_storage_config.max_duration)) && tonumber(trimsuffix(s.cloud_storage_config.max_duration, "s")) >= 60)
      ])
    ])
    error_message = "subscriptions.cloud_storage_config.max_duration must be a seconds-suffixed duration string of at least 60s."
  }

  validation {
    condition     = alltrue([for t in var.topics : alltrue([for s in t.subscriptions : s.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], s.deletion_policy)])])
    error_message = "subscriptions.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.topics : length(distinct([for r in t.role_bindings : r.role])) == length(t.role_bindings)])
    error_message = "role_bindings.role must be unique within each topic; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for t in var.topics : alltrue([for r in t.role_bindings : length(r.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : length(distinct([for r in s.role_bindings : r.role])) == length(s.role_bindings)
      ])
    ])
    error_message = "subscriptions.role_bindings.role must be unique within each subscription; one IAM binding resource exists per role."
  }

  validation {
    condition = alltrue([
      for t in var.topics : alltrue([
        for s in t.subscriptions : alltrue([for r in s.role_bindings : length(r.members) > 0])
      ])
    ])
    error_message = "subscriptions.role_bindings.members must contain at least one member."
  }
}
