variable "clusters" {
  description = "Map of AlloyDB clusters keyed by an arbitrary identifier. Each entry creates one google_alloydb_cluster plus optional nested instances and on-demand backups. Users are out of scope."
  type = map(object({
    cluster_id                       = string
    location                         = string
    project_id                       = optional(string)
    cluster_type                     = optional(string, "PRIMARY")
    database_version                 = optional(string)
    display_name                     = optional(string)
    labels                           = optional(map(string), {})
    annotations                      = optional(map(string), {})
    deletion_policy                  = optional(string)
    deletion_protection              = optional(bool, true)
    subscription_type                = optional(string)
    skip_await_major_version_upgrade = optional(bool)
    network_config = optional(object({
      network            = optional(string)
      allocated_ip_range = optional(string)
    }))
    encryption_config = optional(object({
      kms_key_name = string
    }))
    initial_user = optional(object({
      user     = optional(string)
      password = optional(string)
    }))
    continuous_backup_config = optional(object({
      enabled              = optional(bool)
      recovery_window_days = optional(number)
      encryption_config = optional(object({
        kms_key_name = string
      }))
    }))
    automated_backup_policy = optional(object({
      enabled       = optional(bool)
      location      = optional(string)
      backup_window = optional(string)
      labels        = optional(map(string), {})
      encryption_config = optional(object({
        kms_key_name = string
      }))
      weekly_schedule = optional(object({
        days_of_week = list(string)
        start_times = list(object({
          hours   = number
          minutes = optional(number, 0)
          seconds = optional(number, 0)
          nanos   = optional(number, 0)
        }))
      }))
      time_based_retention = optional(object({
        retention_period = string
      }))
      quantity_based_retention = optional(object({
        count = number
      }))
    }))
    secondary_config = optional(object({
      primary_cluster_name = string
    }))
    maintenance_update_policy = optional(object({
      maintenance_windows = list(object({
        day = string
        start_time = object({
          hours   = number
          minutes = optional(number, 0)
          seconds = optional(number, 0)
          nanos   = optional(number, 0)
        })
      }))
    }))
    psc_config = optional(object({
      psc_enabled = optional(bool)
    }))
    instances = optional(map(object({
      instance_id       = string
      instance_type     = string
      display_name      = optional(string)
      labels            = optional(map(string), {})
      annotations       = optional(map(string), {})
      gce_zone          = optional(string)
      database_flags    = optional(map(string), {})
      availability_type = optional(string)
      activation_policy = optional(string)
      deletion_policy   = optional(string)
      machine_config = optional(object({
        cpu_count    = optional(number)
        machine_type = optional(string)
      }))
      read_pool_config = optional(object({
        node_count = optional(number)
      }))
      query_insights_config = optional(object({
        query_string_length     = optional(number)
        record_application_tags = optional(bool)
        record_client_address   = optional(bool)
        query_plans_per_minute  = optional(number)
      }))
      client_connection_config = optional(object({
        require_connectors = optional(bool)
        ssl_config = optional(object({
          ssl_mode = string
        }))
      }))
      network_config = optional(object({
        enable_public_ip            = optional(bool)
        enable_outbound_public_ip   = optional(bool)
        allocated_ip_range_override = optional(string)
        authorized_external_networks = optional(list(object({
          cidr_range = string
        })), [])
      }))
    })), {})
    backups = optional(map(object({
      backup_id       = string
      location        = string
      display_name    = optional(string)
      labels          = optional(map(string), {})
      description     = optional(string)
      type            = optional(string)
      deletion_policy = optional(string)
      encryption_config = optional(object({
        kms_key_name = string
      }))
    })), {})
  }))

  validation {
    condition     = alltrue([for k, c in var.clusters : can(regex("^[a-z][a-z0-9-]{0,62}$", c.cluster_id))])
    error_message = "cluster_id must be up to 63 characters, start with a lowercase letter and contain only lowercase letters, digits and hyphens."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", c.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : contains(["PRIMARY", "SECONDARY"], c.cluster_type)])
    error_message = "cluster_type must be PRIMARY or SECONDARY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : (c.cluster_type == "SECONDARY") == (c.secondary_config != null)])
    error_message = "secondary_config must be set if and only if cluster_type is SECONDARY."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.database_version == null || can(regex("^POSTGRES_[0-9_]+$", c.database_version))])
    error_message = "database_version must be a POSTGRES_<n> version string (e.g. POSTGRES_15)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.deletion_policy == null || contains(["DEFAULT", "FORCE", "PREVENT", "ABANDON", "DELETE"], c.deletion_policy)])
    error_message = "deletion_policy must be one of DEFAULT, FORCE, PREVENT, ABANDON or DELETE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.subscription_type == null || contains(["TRIAL", "STANDARD"], c.subscription_type)])
    error_message = "subscription_type must be TRIAL or STANDARD (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : can(regex("^[a-z]+-[a-z]+[0-9]+$", c.location))])
    error_message = "location must be a valid GCP region name (e.g. europe-west4) or multi-region."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.continuous_backup_config == null || c.continuous_backup_config.recovery_window_days == null || c.continuous_backup_config.recovery_window_days >= 1])
    error_message = "continuous_backup_config.recovery_window_days must be at least 1 day."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.automated_backup_policy == null || (c.automated_backup_policy.time_based_retention != null) != (c.automated_backup_policy.quantity_based_retention != null)
    ])
    error_message = "automated_backup_policy requires exactly one of time_based_retention or quantity_based_retention when the policy is set."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.automated_backup_policy == null || c.automated_backup_policy.backup_window == null || can(regex("^[0-9]+(\\.[0-9]+)?s$", c.automated_backup_policy.backup_window))
    ])
    error_message = "automated_backup_policy.backup_window must be a duration string in seconds terminated by 's' (e.g. 1800s for the 5-minute minimum)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.automated_backup_policy == null || c.automated_backup_policy.backup_window == null || c.automated_backup_policy.backup_window == "300s" || (tonumber(regex("^[0-9]+", c.automated_backup_policy.backup_window)) >= 300)
    ])
    error_message = "automated_backup_policy.backup_window must be at least 5 minutes (300s)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.automated_backup_policy == null || c.automated_backup_policy.weekly_schedule == null ||
      alltrue([for d in c.automated_backup_policy.weekly_schedule.days_of_week : contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], d)])
    ])
    error_message = "automated_backup_policy.weekly_schedule.days_of_week values must be MONDAY through SUNDAY (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.maintenance_update_policy == null ||
      alltrue([
        for w in c.maintenance_update_policy.maintenance_windows : contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], w.day)
      ])
    ])
    error_message = "maintenance_update_policy.maintenance_windows.day must be MONDAY through SUNDAY (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.maintenance_update_policy == null ||
      alltrue([for w in c.maintenance_update_policy.maintenance_windows : w.start_time.hours >= 0 && w.start_time.hours <= 23 && w.start_time.minutes == 0 && w.start_time.seconds == 0 && w.start_time.nanos == 0])
    ])
    error_message = "maintenance_update_policy.maintenance_windows.start_time must be an exact hour: hours 0-23, minutes, seconds and nanos must be 0."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters : c.automated_backup_policy == null || c.automated_backup_policy.weekly_schedule == null ||
      (length(c.automated_backup_policy.weekly_schedule.days_of_week) > 0 && length(c.automated_backup_policy.weekly_schedule.start_times) > 0)
    ])
    error_message = "automated_backup_policy.weekly_schedule requires at least one day of week and one start time."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances : i.gce_zone == null || can(regex("^[a-z]+-[a-z]+[0-9]-[a-z]$", i.gce_zone))
      ])
    ])
    error_message = "instances.gce_zone must be a valid GCP zone name (e.g. europe-west4-a) or left unset."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances :
        i.instance_type == null || contains(["PRIMARY", "READ_POOL", "SECONDARY"], i.instance_type)
      ])
    ])
    error_message = "instances.instance_type must be one of PRIMARY, READ_POOL or SECONDARY (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances :
        (i.instance_type == "READ_POOL") == (i.read_pool_config != null)
      ])
    ])
    error_message = "read_pool_config is required for READ_POOL instances and must not be set for other instance types."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances : i.availability_type == null || contains(["AVAILABILITY_TYPE_UNSPECIFIED", "ZONAL", "REGIONAL"], i.availability_type)
      ])
    ])
    error_message = "instances.availability_type must be one of AVAILABILITY_TYPE_UNSPECIFIED, ZONAL or REGIONAL (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances : i.activation_policy == null || contains(["ACTIVATION_POLICY_UNSPECIFIED", "ALWAYS", "NEVER"], i.activation_policy)
      ])
    ])
    error_message = "instances.activation_policy must be one of ACTIVATION_POLICY_UNSPECIFIED, ALWAYS or NEVER (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances : i.machine_config == null || i.machine_config.cpu_count == null || i.machine_config.cpu_count >= 2
      ])
    ])
    error_message = "instances.machine_config.cpu_count must be at least 2 and must match the vCPUs of machine_type when both are set."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances :
        i.client_connection_config == null || i.client_connection_config.ssl_config == null ||
        contains(["ENCRYPTED_ONLY", "ALLOW_UNENCRYPTED_AND_ENCRYPTED"], i.client_connection_config.ssl_config.ssl_mode)
      ])
    ])
    error_message = "instances.client_connection_config.ssl_config.ssl_mode must be one of ENCRYPTED_ONLY or ALLOW_UNENCRYPTED_AND_ENCRYPTED (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances : i.deletion_policy == null || contains(["DEFAULT", "FORCE", "PREVENT", "ABANDON", "DELETE"], i.deletion_policy)
      ])
    ])
    error_message = "instances.deletion_policy must be one of DEFAULT, FORCE, PREVENT, ABANDON or DELETE (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([for bk, b in c.backups : can(regex("^[a-z][a-z0-9-]{0,62}$", b.backup_id))])
    ])
    error_message = "backups.backup_id must be up to 63 characters, start with a lowercase letter and contain only lowercase letters, digits and hyphens."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([for bk, b in c.backups : can(regex("^[a-z]+(-[a-z]+)*[0-9]?$", b.location))])
    ])
    error_message = "backups.location must be a valid GCP location (e.g. europe-west4)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([for bk, b in c.backups : b.type == null || contains(["TYPE_UNSPECIFIED", "ON_DEMAND", "AUTOMATED", "CONTINUOUS"], b.type)])
    ])
    error_message = "backups.type must be one of TYPE_UNSPECIFIED, ON_DEMAND, AUTOMATED or CONTINUOUS (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([for bk, b in c.backups : b.deletion_policy == null || contains(["DEFAULT", "FORCE", "PREVENT", "ABANDON", "DELETE"], b.deletion_policy)])
    ])
    error_message = "backups.deletion_policy must be one of DEFAULT, FORCE, PREVENT, ABANDON or DELETE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k in keys(var.clusters) : !can(regex("/", k))])
    error_message = "cluster keys must not contain '/'; it is used as the composite-key separator for instances and backups."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([for ik in keys(c.instances) : !can(regex("/", ik))])
    ])
    error_message = "instances keys must not contain '/'; it is used as the composite-key separator in outputs."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([for bk in keys(c.backups) : !can(regex("/", bk))])
    ])
    error_message = "backups keys must not contain '/'; it is used as the composite-key separator in outputs."
  }

  validation {
    condition = alltrue([
      for k, c in var.clusters :
      alltrue([
        for ik, i in c.instances : i.instance_id == null || can(regex("^[a-z][a-z0-9-]{0,62}$", i.instance_id))
      ])
    ])
    error_message = "instances.instance_id must be up to 63 characters, start with a lowercase letter and contain only lowercase letters, digits and hyphens."
  }
}
