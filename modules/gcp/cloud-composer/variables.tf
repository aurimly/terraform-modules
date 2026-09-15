variable "environments" {
  description = "Map of Cloud Composer (Managed Airflow, Gen 3) environments keyed by an arbitrary identifier. Targets Composer 3 image versions only."
  type = map(object({
    name            = string
    region          = string
    project_id      = optional(string)
    labels          = optional(map(string), {})
    deletion_policy = optional(string)
    storage_config = optional(object({
      bucket = string
    }))
    config = optional(object({
      environment_size           = optional(string)
      enable_private_environment = optional(bool)
      enable_private_builds_only = optional(bool)
      node_config = optional(object({
        network                           = optional(string)
        subnetwork                        = optional(string)
        service_account                   = optional(string)
        tags                              = optional(list(string))
        composer_network_attachment       = optional(string)
        composer_internal_ipv4_cidr_block = optional(string)
      }))
      encryption_config = optional(object({
        kms_key_name = string
      }))
      maintenance_window = optional(object({
        start_time = string
        end_time   = string
        recurrence = string
      }))
      software_config = optional(object({
        image_version            = optional(string)
        airflow_config_overrides = optional(map(string), {})
        pypi_packages            = optional(map(string), {})
        env_variables            = optional(map(string), {})
        web_server_plugins_mode  = optional(string)
        cloud_data_lineage_integration = optional(object({
          enabled = bool
        }))
      }))
      workloads_config = optional(object({
        scheduler = optional(object({
          cpu        = optional(number)
          memory_gb  = optional(number)
          storage_gb = optional(number)
          count      = optional(number)
        }))
        triggerer = optional(object({
          cpu       = number
          memory_gb = number
          count     = number
        }))
        web_server = optional(object({
          cpu        = optional(number)
          memory_gb  = optional(number)
          storage_gb = optional(number)
        }))
        worker = optional(object({
          cpu        = optional(number)
          memory_gb  = optional(number)
          storage_gb = optional(number)
          min_count  = optional(number)
          max_count  = optional(number)
        }))
        dag_processor = optional(object({
          cpu        = optional(number)
          memory_gb  = optional(number)
          storage_gb = optional(number)
          count      = number
        }))
      }))
      recovery_config = optional(object({
        scheduled_snapshots_config = optional(object({
          enabled                    = optional(bool)
          snapshot_location          = optional(string)
          snapshot_creation_schedule = optional(string)
          time_zone                  = optional(string)
        }))
      }))
      data_retention_config = optional(object({
        airflow_metadata_retention_config = optional(object({
          retention_mode = optional(string)
          retention_days = optional(number)
        }))
      }))
    }))
  }))

  validation {
    condition     = alltrue([for k, e in var.environments : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$", e.name))])
    error_message = "name must be up to 63 characters, start with a letter or digit and contain only letters, digits and hyphens."
  }

  validation {
    condition     = alltrue([for k, e in var.environments : can(regex("^[a-z]+-[a-z]+[0-9]+$", e.region))])
    error_message = "region must be a valid GCP region name (e.g. europe-west1). Requiring region here is deliberate; the provider default region is not scoped for a region-scoped module."
  }

  validation {
    condition     = alltrue([for k, e in var.environments : e.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", e.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, e in var.environments : e.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], e.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, e in var.environments : e.config == null || e.config.environment_size == null ||
      contains(["ENVIRONMENT_SIZE_SMALL", "ENVIRONMENT_SIZE_MEDIUM", "ENVIRONMENT_SIZE_LARGE"], e.config.environment_size)
    ])
    error_message = "config.environment_size must be one of ENVIRONMENT_SIZE_SMALL, ENVIRONMENT_SIZE_MEDIUM or ENVIRONMENT_SIZE_LARGE (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, e in var.environments : e.config == null || e.config.software_config == null || e.config.software_config.image_version == null ||
      can(regex("^composer-3-", e.config.software_config.image_version))
    ])
    error_message = "config.software_config.image_version must be a Composer 3 image version (composer-3-airflow-<version>); this module targets Managed Airflow Gen 3 only."
  }

  validation {
    condition = alltrue([
      for k, e in var.environments : e.config == null || e.config.software_config == null ||
      alltrue([for v in keys(e.config.software_config.env_variables) : !can(regex("^AIRFLOW__", v))])
    ])
    error_message = "config.software_config.env_variables keys must not be Airflow configuration overrides (AIRFLOW__<section>__<option>); use airflow_config_overrides instead."
  }

  validation {
    condition = alltrue([
      for k, e in var.environments : e.config == null || e.config.software_config == null ||
      alltrue([for v in keys(e.config.software_config.env_variables) : can(regex("^[a-zA-Z_][a-zA-Z0-9_]*$", v))])
    ])
    error_message = "config.software_config.env_variables keys must match [a-zA-Z_][a-zA-Z0-9_]*."
  }

  validation {
    condition = alltrue([
      for k, e in var.environments : e.config == null || e.config.maintenance_window == null ||
      can(regex("^FREQ=DAILY(;|$)|^FREQ=WEEKLY;BYDAY=", e.config.maintenance_window.recurrence))
    ])
    error_message = "config.maintenance_window.recurrence must be an RFC-5545 RRULE with FREQ=DAILY or FREQ=WEEKLY;BYDAY=... (e.g. FREQ=WEEKLY;BYDAY=TU,WE)."
  }

  validation {
    condition = alltrue([
      for k, e in var.environments : e.config == null || e.config.data_retention_config == null || e.config.data_retention_config.airflow_metadata_retention_config == null ||
      e.config.data_retention_config.airflow_metadata_retention_config.retention_mode == null ||
      contains(["RETENTION_MODE_ENABLED", "RETENTION_MODE_DISABLED"], e.config.data_retention_config.airflow_metadata_retention_config.retention_mode)
    ])
    error_message = "config.data_retention_config.airflow_metadata_retention_config.retention_mode must be RETENTION_MODE_ENABLED or RETENTION_MODE_DISABLED (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, e in var.environments : e.config == null || e.config.workloads_config == null || e.config.workloads_config.worker == null ||
      e.config.workloads_config.worker.min_count == null || e.config.workloads_config.worker.max_count == null ||
      e.config.workloads_config.worker.min_count <= e.config.workloads_config.worker.max_count
    ])
    error_message = "config.workloads_config.worker.min_count must not exceed max_count."
  }

  validation {
    condition = alltrue([
      for k, e in var.environments : e.config == null || e.config.software_config == null || e.config.software_config.web_server_plugins_mode == null ||
      contains(["ENABLED", "DISABLED"], e.config.software_config.web_server_plugins_mode)
    ])
    error_message = "config.software_config.web_server_plugins_mode must be ENABLED or DISABLED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k in keys(var.environments) : !can(regex("/", k))])
    error_message = "environment keys must not contain '/'; it is used as a separator convention for composite keys."
  }
}
