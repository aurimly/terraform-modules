variable "instances" {
  description = "Map of Memorystore for Redis Cluster instances keyed by an arbitrary identifier. Each entry creates one google_memorystore_instance."
  type = map(object({
    name                    = string
    location                = string
    shard_count             = number
    node_type               = string
    project_id              = optional(string)
    engine_version          = optional(string)
    engine_configs          = optional(map(string), {})
    labels                  = optional(map(string), {})
    replica_count           = optional(number)
    authorization_mode      = optional(string)
    transit_encryption_mode = optional(string)
    deletion_protection     = optional(bool, true)
    zone_distribution_config = optional(object({
      mode = optional(string)
      zone = optional(string)
    }))
    maintenance_policy = optional(object({
      day = string
      start_time = object({
        hours   = number
        minutes = optional(number)
      })
    }))
    desired_auto_created_endpoints = optional(list(object({
      network    = string
      project_id = string
    })))
  }))

  validation {
    condition     = alltrue([for k, i in var.instances : can(regex("^[a-z0-9]([-a-z0-9]{2,61}[a-z0-9])$", i.name))])
    error_message = "name must be 4 to 63 characters: lowercase letters, digits or hyphens, starting and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : can(regex("^[a-z]+-[a-z]+[0-9]+$", i.location))])
    error_message = "location must be a valid GCP region name (e.g. europe-west1)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.shard_count >= 1])
    error_message = "shard_count must be at least 1; the API-side maximum depends on node type and region."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : contains(["SHARED_CORE_NANO", "CUSTOM_PICO", "CUSTOM_MICRO", "CUSTOM_MINI", "HIGHMEM_MEDIUM", "HIGHCPU_MEDIUM", "HIGHMEM_XLARGE", "STANDARD_SMALL", "STANDARD_LARGE", "HIGHMEM_2XLARGE"], i.node_type)])
    error_message = "node_type must be one of SHARED_CORE_NANO, CUSTOM_PICO, CUSTOM_MICRO, CUSTOM_MINI, HIGHMEM_MEDIUM, HIGHCPU_MEDIUM, HIGHMEM_XLARGE, STANDARD_SMALL, STANDARD_LARGE or HIGHMEM_2XLARGE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", i.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.authorization_mode == null || contains(["AUTH_DISABLED", "IAM_AUTH"], i.authorization_mode)])
    error_message = "authorization_mode must be AUTH_DISABLED or IAM_AUTH (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.transit_encryption_mode == null || contains(["TRANSIT_ENCRYPTION_DISABLED", "SERVER_AUTHENTICATION"], i.transit_encryption_mode)])
    error_message = "transit_encryption_mode must be TRANSIT_ENCRYPTION_DISABLED or SERVER_AUTHENTICATION (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.zone_distribution_config == null || i.zone_distribution_config.mode == null || contains(["MULTI_ZONE", "SINGLE_ZONE"], i.zone_distribution_config.mode)])
    error_message = "zone_distribution_config.mode must be MULTI_ZONE or SINGLE_ZONE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.zone_distribution_config == null || i.zone_distribution_config.mode != "SINGLE_ZONE" || i.zone_distribution_config.zone != null])
    error_message = "zone_distribution_config.zone is required when zone_distribution_config.mode is SINGLE_ZONE."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.maintenance_policy == null || contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], i.maintenance_policy.day)])
    error_message = "maintenance_policy.day must be one of MONDAY through SUNDAY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.maintenance_policy == null || (i.maintenance_policy.start_time.hours >= 0 && i.maintenance_policy.start_time.hours <= 23 && (i.maintenance_policy.start_time.minutes == null || (i.maintenance_policy.start_time.minutes >= 0 && i.maintenance_policy.start_time.minutes <= 59)))])
    error_message = "maintenance_policy.start_time.hours must be 0-23 and minutes 0-59 (UTC)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.desired_auto_created_endpoints == null || alltrue([for e in i.desired_auto_created_endpoints : e.network != null && e.network != ""])])
    error_message = "desired_auto_created_endpoints.network must be a non-empty VPC network self link."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.desired_auto_created_endpoints == null || alltrue([for e in i.desired_auto_created_endpoints : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", e.project_id))])])
    error_message = "desired_auto_created_endpoints.project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}
