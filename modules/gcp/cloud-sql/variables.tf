variable "instances" {
  description = "Map of Cloud SQL instances keyed by an arbitrary identifier. Each entry creates one primary google_sql_database_instance plus optional read replicas. Databases and users are out of scope."
  type = map(object({
    name                  = string
    database_version      = string
    region                = string
    tier                  = string
    project_id            = optional(string)
    edition               = optional(string)
    deletion_protection   = optional(bool, true)
    deletion_policy       = optional(string)
    availability_type     = optional(string)
    disk_type             = optional(string)
    disk_size             = optional(number)
    disk_autoresize       = optional(bool)
    disk_autoresize_limit = optional(number)
    root_password         = optional(string)
    database_flags        = optional(list(object({ name = string, value = string })), [])
    labels                = optional(map(string), {})
    backup_configuration = optional(object({
      enabled                        = optional(bool)
      start_time                     = optional(string)
      point_in_time_recovery_enabled = optional(bool)
      binary_log_enabled             = optional(bool)
      retained_backups               = optional(number)
      location                       = optional(string)
    }))
    ip_configuration = optional(object({
      ipv4_enabled       = optional(bool)
      private_network    = optional(string)
      ssl_mode           = optional(string)
      allocated_ip_range = optional(string)
      authorized_networks = optional(list(object({
        name  = optional(string)
        value = string
      })), [])
    }))
    maintenance_window = optional(object({
      day          = number
      hour         = number
      update_track = optional(string)
    }))
    insights_config = optional(object({
      query_insights_enabled  = optional(bool)
      query_string_length     = optional(number)
      record_application_tags = optional(bool)
      record_client_address   = optional(bool)
    }))
    replicas = optional(map(object({
      name                  = string
      region                = string
      tier                  = string
      availability_type     = optional(string)
      disk_type             = optional(string)
      disk_size             = optional(number)
      disk_autoresize       = optional(bool)
      disk_autoresize_limit = optional(number)
      database_flags        = optional(list(object({ name = string, value = string })), [])
      ip_configuration = optional(object({
        ipv4_enabled       = optional(bool)
        private_network    = optional(string)
        ssl_mode           = optional(string)
        allocated_ip_range = optional(string)
        authorized_networks = optional(list(object({
          name  = optional(string)
          value = string
        })), [])
      }))
      deletion_protection = optional(bool, true)
    })), {})
  }))

  validation {
    condition     = alltrue([for k, i in var.instances : can(regex("^[a-z][a-z0-9-]{0,97}[a-z0-9]$", i.name))])
    error_message = "name must be up to 98 lowercase letters, digits or hyphens, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : can(regex("^(POSTGRES|MYSQL)_[0-9_]+$", i.database_version))])
    error_message = "database_version must be a POSTGRES_<n> or MYSQL_<n[_n]> version string (e.g. POSTGRES_16 or MYSQL_8_0). SQL Server is out of scope."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.tier != null && can(regex("^db-[a-z0-9-]+$", i.tier))])
    error_message = "tier must look like a Cloud SQL machine type (e.g. db-custom-2-7680, db-f1-micro)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : can(regex("^[a-z]+-[a-z]+[0-9]+$", i.region))])
    error_message = "region must be a valid GCP region name (e.g. europe-west1)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", i.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.edition == null || contains(["ENTERPRISE", "ENTERPRISE_PLUS"], i.edition)])
    error_message = "edition must be ENTERPRISE or ENTERPRISE_PLUS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.availability_type == null || contains(["ZONAL", "REGIONAL"], i.availability_type)])
    error_message = "availability_type must be ZONAL or REGIONAL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.disk_type == null || contains(["PD_SSD", "PD_HDD", "HYPERDISK_BALANCED"], i.disk_type)])
    error_message = "disk_type must be one of PD_SSD, PD_HDD or HYPERDISK_BALANCED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.root_password == null || can(regex("^MYSQL", i.database_version))])
    error_message = "root_password is valid for MySQL instances only; it must not be set for POSTGRES_*."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.maintenance_window == null || (i.maintenance_window.day >= 1 && i.maintenance_window.day <= 7 && i.maintenance_window.hour >= 0 && i.maintenance_window.hour <= 23)])
    error_message = "maintenance_window.day must be 1-7 (Monday-Sunday) and hour must be 0-23."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.maintenance_window == null || i.maintenance_window.update_track == null || contains(["canary", "week5", "stable"], i.maintenance_window.update_track)])
    error_message = "maintenance_window.update_track must be canary, week5 or stable (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.backup_configuration == null || i.backup_configuration.start_time == null || can(regex("^[0-9]{2}:[0-9]{2}$", i.backup_configuration.start_time))])
    error_message = "backup_configuration.start_time must be an HH:mm 24-hour time (e.g. 01:00)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.backup_configuration == null || i.backup_configuration.retained_backups == null || i.backup_configuration.retained_backups > 0])
    error_message = "backup_configuration.retained_backups must be a positive number of backups to retain."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.ip_configuration == null || i.ip_configuration.allocated_ip_range == null || i.ip_configuration.private_network != null])
    error_message = "ip_configuration.allocated_ip_range can only be set when ip_configuration.private_network is also set."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.ip_configuration == null || i.ip_configuration.ssl_mode == null || contains(["ALLOW_UNENCRYPTED_AND_ENCRYPTED", "ENCRYPTED_ONLY", "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"], i.ip_configuration.ssl_mode)])
    error_message = "ip_configuration.ssl_mode must be one of ALLOW_UNENCRYPTED_AND_ENCRYPTED, ENCRYPTED_ONLY or TRUSTED_CLIENT_CERTIFICATE_REQUIRED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], i.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : alltrue([for rn, r in i.replicas : can(regex("^[a-z][a-z0-9-]{0,97}[a-z0-9]$", r.name))])])
    error_message = "replicas.name must be up to 98 lowercase letters, digits or hyphens, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : alltrue([for rn, r in i.replicas : can(regex("^[a-z]+-[a-z]+[0-9]+$", r.region))])])
    error_message = "replicas.region must be a valid GCP region name (e.g. europe-west1)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : alltrue([for rn, r in i.replicas : r.tier != null && can(regex("^db-[a-z0-9-]+$", r.tier))])])
    error_message = "replicas.tier must look like a Cloud SQL machine type (e.g. db-custom-2-7680)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : alltrue([for rn, r in i.replicas : r.ip_configuration == null || r.ip_configuration.allocated_ip_range == null || r.ip_configuration.private_network != null])])
    error_message = "replicas ip_configuration.allocated_ip_range can only be set when the replica's ip_configuration.private_network is also set."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : alltrue([for rn, r in i.replicas : r.ip_configuration == null || r.ip_configuration.ssl_mode == null || contains(["ALLOW_UNENCRYPTED_AND_ENCRYPTED", "ENCRYPTED_ONLY", "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"], r.ip_configuration.ssl_mode)])])
    error_message = "replicas ip_configuration.ssl_mode must be one of ALLOW_UNENCRYPTED_AND_ENCRYPTED, ENCRYPTED_ONLY or TRUSTED_CLIENT_CERTIFICATE_REQUIRED (case-sensitive)."
  }
}
