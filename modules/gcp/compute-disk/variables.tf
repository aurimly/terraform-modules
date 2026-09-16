variable "disks" {
  description = "Map of persistent disks keyed by an arbitrary identifier. Each entry creates one google_compute_disk."
  default     = {}
  type = map(object({
    name                                  = string
    zone                                  = string
    project_id                            = optional(string)
    type                                  = optional(string)
    size                                  = optional(number)
    description                           = optional(string)
    labels                                = optional(map(string), {})
    architecture                          = optional(string)
    access_mode                           = optional(string)
    physical_block_size_bytes             = optional(number)
    provisioned_iops                      = optional(number)
    provisioned_throughput                = optional(number)
    storage_pool                          = optional(string)
    enable_confidential_compute           = optional(bool)
    deletion_policy                       = optional(string)
    create_snapshot_before_destroy        = optional(bool)
    create_snapshot_before_destroy_prefix = optional(string)
    guest_os_features = optional(list(object({
      type = string
    })), [])
    image                   = optional(string)
    snapshot                = optional(string)
    source_instant_snapshot = optional(string)
    source_disk             = optional(string)
    source_storage_object   = optional(string)
    disk_encryption_key = optional(object({
      kms_key_self_link       = optional(string)
      kms_key_service_account = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for d in var.disks : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", d.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for d in var.disks : can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", d.zone))])
    error_message = "zone must look like a GCP zone name (e.g. us-central1-a); it is a shape check, not a list of valid zones."
  }

  validation {
    condition     = alltrue([for d in var.disks : d.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", d.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for d in var.disks : d.size == null || d.size > 0])
    error_message = "size must be greater than 0 when set."
  }

  validation {
    condition = alltrue([
      for d in var.disks : length([
        for k in ["image", "snapshot", "source_instant_snapshot", "source_disk", "source_storage_object"] : k
        if try(d[k], null) != null
      ]) <= 1
    ])
    error_message = "set at most one of image, snapshot, source_instant_snapshot, source_disk or source_storage_object; a disk is restored from one source. An empty disk has no source."
  }

  validation {
    condition     = alltrue([for d in var.disks : anytrue([d.size != null, d.image != null, d.snapshot != null, d.source_instant_snapshot != null, d.source_disk != null, d.source_storage_object != null])])
    error_message = "a disk with no image, snapshot, source_instant_snapshot, source_disk or source_storage_object must set size (an empty disk needs its initial size)."
  }

  validation {
    condition     = alltrue([for d in var.disks : d.access_mode == null || contains(["READ_WRITE_SINGLE", "READ_WRITE_MANY", "READ_ONLY_SINGLE"], d.access_mode)])
    error_message = "access_mode must be one of READ_WRITE_SINGLE, READ_WRITE_MANY or READ_ONLY_SINGLE."
  }

  validation {
    condition     = alltrue([for d in var.disks : d.architecture == null || contains(["X86_64", "ARM64"], d.architecture)])
    error_message = "architecture must be X86_64 or ARM64."
  }

  validation {
    condition     = alltrue([for d in var.disks : d.physical_block_size_bytes == null || contains([4096, 16384], d.physical_block_size_bytes)])
    error_message = "physical_block_size_bytes must be 4096 or 16384."
  }

  validation {
    condition     = alltrue([for d in var.disks : d.deletion_policy == null || contains(["DELETE", "ABANDON", "PREVENT"], d.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT. Defaults to DELETE when unset."
  }

  validation {
    condition = alltrue([
      for d in var.disks : d.disk_encryption_key == null || d.disk_encryption_key.kms_key_service_account == null || d.disk_encryption_key.kms_key_self_link != null
    ])
    error_message = "disk_encryption_key.kms_key_service_account requires kms_key_self_link."
  }

  validation {
    condition = alltrue([
      for d in var.disks : d.enable_confidential_compute != true || d.disk_encryption_key != null
    ])
    error_message = "enable_confidential_compute requires disk_encryption_key (confidential disks need a customer-managed encryption key)."
  }
}

variable "snapshots" {
  description = "Map of disk snapshots keyed by an arbitrary identifier. Each entry creates one google_compute_snapshot."
  default     = {}
  type = map(object({
    name                    = string
    source_disk             = optional(string)
    source_instant_snapshot = optional(string)
    zone                    = string
    project_id              = optional(string)
    description             = optional(string)
    labels                  = optional(map(string), {})
    storage_locations       = optional(list(string))
    snapshot_type           = optional(string)
    chain_name              = optional(string)
    deletion_policy         = optional(string)
  }))

  validation {
    condition     = alltrue([for s in var.snapshots : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", s.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition = alltrue([
      for s in var.snapshots : (s.source_disk != null) != (s.source_instant_snapshot != null)
    ])
    error_message = "set exactly one of source_disk or source_instant_snapshot; a snapshot is taken from one source."
  }

  validation {
    condition     = alltrue([for s in var.snapshots : s.snapshot_type == null || contains(["STANDARD", "ARCHIVE"], s.snapshot_type)])
    error_message = "snapshot_type must be STANDARD or ARCHIVE."
  }

  validation {
    condition     = alltrue([for s in var.snapshots : s.deletion_policy == null || contains(["DELETE", "ABANDON", "PREVENT"], s.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT. Defaults to DELETE when unset."
  }
}

variable "snapshot_schedule_policies" {
  description = "Map of snapshot schedule resource policies keyed by an arbitrary identifier. Each entry creates one google_compute_resource_policy scoped to snapshot_schedule_policy."
  default     = {}
  type = map(object({
    name            = string
    region          = string
    project_id      = optional(string)
    description     = optional(string)
    deletion_policy = optional(string)
    snapshot_schedule_policy = object({
      hourly_schedule = optional(object({
        hours_in_cycle = number
        start_time     = optional(string)
      }))
      daily_schedule = optional(object({
        days_in_cycle = number
        start_time    = optional(string)
      }))
      weekly_schedule = optional(object({
        day_of_weeks = list(object({
          day        = string
          start_time = optional(string)
        }))
      }))
      retention_policy = optional(object({
        max_retention_days    = number
        on_source_disk_delete = optional(string)
      }))
      snapshot_properties = optional(object({
        labels            = optional(map(string))
        storage_locations = optional(list(string))
        guest_flush       = optional(bool)
        chain_name        = optional(string)
      }))
    })
  }))

  validation {
    condition     = alltrue([for p in var.snapshot_schedule_policies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for p in var.snapshot_schedule_policies : can(regex("^[a-z]+-[a-z]+[0-9]+$", p.region))])
    error_message = "region must look like a GCP region (e.g. us-central1); it is a shape check, not a list of valid regions."
  }

  validation {
    condition = alltrue([
      for p in var.snapshot_schedule_policies : length([
        for s in [p.snapshot_schedule_policy.hourly_schedule, p.snapshot_schedule_policy.daily_schedule, p.snapshot_schedule_policy.weekly_schedule] : s
        if s != null
      ]) == 1
    ])
    error_message = "set exactly one of hourly_schedule, daily_schedule or weekly_schedule."
  }

  validation {
    condition     = alltrue([for p in var.snapshot_schedule_policies : p.snapshot_schedule_policy.daily_schedule == null || p.snapshot_schedule_policy.daily_schedule.days_in_cycle == 1])
    error_message = "daily_schedule.days_in_cycle must be 1 for snapshot schedules (the API maps it to a daily cadence with a repeat interval of 1 day)."
  }

  validation {
    condition     = alltrue([for p in var.snapshot_schedule_policies : p.snapshot_schedule_policy.retention_policy == null || p.snapshot_schedule_policy.retention_policy.max_retention_days >= 1])
    error_message = "retention_policy.max_retention_days must be at least 1."
  }

  validation {
    condition     = alltrue([for p in var.snapshot_schedule_policies : p.snapshot_schedule_policy.retention_policy == null || p.snapshot_schedule_policy.retention_policy.on_source_disk_delete == null || contains(["KEEP_AUTO_SNAPSHOTS", "APPLY_RETENTION_POLICY"], p.snapshot_schedule_policy.retention_policy.on_source_disk_delete)])
    error_message = "retention_policy.on_source_disk_delete must be KEEP_AUTO_SNAPSHOTS or APPLY_RETENTION_POLICY."
  }
}

variable "snapshot_schedule_attachments" {
  description = "Map of snapshot schedule attachments keyed by an arbitrary identifier. Each entry attaches one disks entry (disk_key) to one snapshot_schedule_policies entry (policy_key)."
  default     = {}
  type = map(object({
    disk_key   = string
    policy_key = string
  }))
}
