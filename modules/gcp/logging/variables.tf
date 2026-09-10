variable "sinks" {
  description = "Map of project-level log sinks keyed by an arbitrary identifier. Each entry creates one google_logging_project_sink."
  type = map(object({
    name                   = string
    destination            = string
    filter                 = string
    description            = optional(string)
    disabled               = optional(bool)
    unique_writer_identity = optional(bool, true)
    project_id             = optional(string)
    deletion_policy        = optional(string)
    bigquery_options = optional(object({
      use_partitioned_tables = bool
    }))
    exclusions = optional(list(object({
      name        = string
      filter      = string
      description = optional(string)
      disabled    = optional(bool)
    })), [])
  }))

  validation {
    condition     = alltrue([for k, s in var.sinks : can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,99}$", s.name))])
    error_message = "name must be 1-100 characters: letters, digits, underscores, hyphens or periods, starting with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : can(regex("^(storage\\.googleapis\\.com/|pubsub\\.googleapis\\.com/|bigquery\\.googleapis\\.com/|logging\\.googleapis\\.com/|bucket\\.|pubsub\\.|bigquery\\.|logging\\.)", s.destination))])
    error_message = "destination must be one of: a Cloud Storage bucket URI (storage.googleapis.com/<bucket>), a Pub/Sub topic URI (pubsub.googleapis.com/<topic>), a BigQuery dataset URI (bigquery.googleapis.com/datasets/<dataset>), a Cloud Logging bucket URI (logging.googleapis.com/projects/<project>/locations/<location>/buckets/<bucket>), or the bare name of a shared sink destination (bucket.<name>, pubsub.<name>, bigquery.<name> or logging.<name>)."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : length(s.filter) > 0])
    error_message = "filter must be a non-empty Cloud Logging query filter string (e.g. severity>=WARNING)."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : s.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], s.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : s.bigquery_options == null || can(regex("^bigquery\\.googleapis\\.com/", s.destination))])
    error_message = "bigquery_options can only be set when destination is a BigQuery dataset (bigquery.googleapis.com/datasets/<dataset>)."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : alltrue([for e in s.exclusions : can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,99}$", e.name))])])
    error_message = "exclusions.name must be up to 100 characters: letters, digits, underscores, hyphens or periods, starting with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : alltrue([for e in s.exclusions : length(e.filter) > 0])])
    error_message = "exclusions.filter must be a non-empty Cloud Logging query filter string."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : alltrue([for e in s.exclusions : length(distinct([for x in s.exclusions : x.name])) == length(s.exclusions)])])
    error_message = "exclusions.name must be unique within each sink."
  }

  validation {
    condition     = alltrue([for k, s in var.sinks : s.bigquery_options == null || s.unique_writer_identity])
    error_message = "bigquery_options.use_partitioned_tables requires unique_writer_identity = true set explicitly."
  }
}
