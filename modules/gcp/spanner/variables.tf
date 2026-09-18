variable "instances" {
  description = "Map of Spanner instances keyed by an arbitrary identifier. Each entry creates one google_spanner_instance with optional nested databases and instance/database IAM bindings."
  type = map(object({
    name                         = string
    display_name                 = string
    config                       = string
    project_id                   = optional(string)
    labels                       = optional(map(string), {})
    edition                      = optional(string)
    instance_type                = optional(string)
    num_nodes                    = optional(number)
    processing_units             = optional(number)
    default_backup_schedule_type = optional(string)
    deletion_policy              = optional(string)
    force_destroy                = optional(bool)
    autoscaling_config = optional(object({
      autoscaling_limits = optional(object({
        min_nodes            = optional(number)
        max_nodes            = optional(number)
        min_processing_units = optional(number)
        max_processing_units = optional(number)
      }))
      autoscaling_targets = optional(object({
        high_priority_cpu_utilization_percent = optional(number)
        storage_utilization_percent           = optional(number)
        total_cpu_utilization_percent         = optional(number)
      }))
      asymmetric_autoscaling_options = optional(map(object({
        replica_selection = object({
          location = string
        })
        overrides = object({
          autoscaling_limits = optional(object({
            min_nodes            = optional(number)
            max_nodes            = optional(number)
            min_processing_units = optional(number)
            max_processing_units = optional(number)
          }))
          autoscaling_target_high_priority_cpu_utilization_percent = optional(number)
          autoscaling_target_total_cpu_utilization_percent         = optional(number)
          disable_high_priority_cpu_autoscaling                    = optional(bool)
          disable_total_cpu_autoscaling                            = optional(bool)
        })
      })))
    }))
    role_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })), {})
    databases = optional(map(object({
      name                     = string
      ddl                      = optional(list(string))
      version_retention_period = optional(string)
      default_time_zone        = optional(string)
      database_dialect         = optional(string)
      enable_drop_protection   = optional(bool)
      deletion_protection      = optional(bool, true)
      deletion_policy          = optional(string)
      encryption_config = optional(object({
        kms_key_name  = optional(string)
        kms_key_names = optional(list(string))
      }))
      role_bindings = optional(map(object({
        role    = string
        members = list(string)
        condition = optional(object({
          title       = string
          description = optional(string)
          expression  = string
        }))
      })), {})
    })), {})
  }))

  validation {
    condition     = alltrue([for k, i in var.instances : can(regex("^[a-z][-a-z0-9]{4,28}[a-z0-9]$", i.name))])
    error_message = "name must be 6-30 characters, start with a lowercase letter, end with a lowercase letter or digit, and contain only hyphens, lowercase letters and digits."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : length(i.display_name) >= 4 && length(i.display_name) <= 30])
    error_message = "display_name must be 4-30 characters (it must also be unique per project; not checked at plan time)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", i.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.edition == null || contains(["EDITION_UNSPECIFIED", "STANDARD", "ENTERPRISE", "ENTERPRISE_PLUS"], i.edition)])
    error_message = "edition must be one of EDITION_UNSPECIFIED, STANDARD, ENTERPRISE or ENTERPRISE_PLUS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.instance_type == null || contains(["PROVISIONED", "FREE_INSTANCE"], i.instance_type)])
    error_message = "instance_type must be PROVISIONED or FREE_INSTANCE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.default_backup_schedule_type == null || contains(["NONE", "AUTOMATIC"], i.default_backup_schedule_type)])
    error_message = "default_backup_schedule_type must be NONE or AUTOMATIC (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      i.instance_type == "FREE_INSTANCE" ||
      sum([for f in [i.num_nodes != null, i.processing_units != null, i.autoscaling_config != null] : f ? 1 : 0]) == 1
    ])
    error_message = "each instance requires exactly one of num_nodes, processing_units or autoscaling_config (exempt for instance_type = FREE_INSTANCE)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.instance_type != "FREE_INSTANCE" || i.edition == null])
    error_message = "edition must not be configured for instance_type = FREE_INSTANCE."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.instance_type != "FREE_INSTANCE" || i.default_backup_schedule_type != "AUTOMATIC"])
    error_message = "default_backup_schedule_type = AUTOMATIC is not permitted for instance_type = FREE_INSTANCE (backups and backup schedules are not allowed for free instances)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      i.autoscaling_config == null || i.autoscaling_config.autoscaling_limits == null || alltrue([
        for l in [i.autoscaling_config.autoscaling_limits] :
        (l.min_nodes != null) == (l.max_nodes != null) &&
        (l.min_processing_units != null) == (l.max_processing_units != null) &&
        ((l.min_nodes != null) != (l.min_processing_units != null)) &&
        (l.min_nodes == null || (l.min_nodes >= 1 && l.min_nodes <= l.max_nodes)) &&
        (l.min_processing_units == null || (l.min_processing_units % 1000 == 0 && l.min_processing_units <= l.max_processing_units))
      ])
    ])
    error_message = "autoscaling_config.autoscaling_limits requires exactly one unit pair: both min_nodes and max_nodes (min_nodes >= 1), or both min_processing_units and max_processing_units (multiples of 1000); min must not exceed max."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      i.autoscaling_config == null || i.autoscaling_config.autoscaling_targets == null || alltrue([
        for t in [i.autoscaling_config.autoscaling_targets] :
        (t.total_cpu_utilization_percent == null || (t.total_cpu_utilization_percent >= 10 && t.total_cpu_utilization_percent <= 90)) &&
        (t.total_cpu_utilization_percent == null || t.high_priority_cpu_utilization_percent == null || t.total_cpu_utilization_percent > t.high_priority_cpu_utilization_percent)
      ])
    ])
    error_message = "autoscaling_config.autoscaling_targets.total_cpu_utilization_percent must be between 10 and 90 when set, and higher than high_priority_cpu_utilization_percent when both are set."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      i.autoscaling_config == null || i.autoscaling_config.asymmetric_autoscaling_options == null || alltrue([
        for ak, a in i.autoscaling_config.asymmetric_autoscaling_options :
        a.overrides.autoscaling_limits == null || alltrue([
          for l in [a.overrides.autoscaling_limits] :
          (l.min_nodes != null) == (l.max_nodes != null) &&
          (l.min_processing_units != null) == (l.max_processing_units != null) &&
          ((l.min_nodes != null) || (l.min_processing_units != null)) &&
          (l.min_nodes == null || (l.min_nodes >= 1 && l.min_nodes <= l.max_nodes)) &&
          (l.min_processing_units == null || (l.min_processing_units % 1000 == 0 && l.min_processing_units <= l.max_processing_units))
        ])
      ])
    ])
    error_message = "asymmetric_autoscaling_options.overrides.autoscaling_limits requires one unit pair: both min_nodes and max_nodes (min_nodes >= 1), or both min_processing_units and max_processing_units (multiples of 1000); min must not exceed max."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], i.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for dk, d in i.databases : can(regex("^[a-z][-_a-z0-9]*[a-z0-9]$", d.name))])
    ])
    error_message = "databases.name must match ^[a-z][-_a-z0-9]*[a-z0-9]$ (start with a lowercase letter, end with a lowercase letter or digit)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for dk, d in i.databases : d.database_dialect == null || contains(["GOOGLE_STANDARD_SQL", "POSTGRESQL"], d.database_dialect)])
    ])
    error_message = "databases.database_dialect must be GOOGLE_STANDARD_SQL or POSTGRESQL (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for dk, d in i.databases : d.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], d.deletion_policy)])
    ])
    error_message = "databases.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for dk, d in i.databases :
        d.encryption_config == null ||
        ((d.encryption_config.kms_key_name != null) != (length(d.encryption_config.kms_key_names == null ? [] : d.encryption_config.kms_key_names) > 0))
      ])
    ])
    error_message = "databases.encryption_config requires exactly one of kms_key_name or kms_key_names; this module deliberately enforces the unambiguous form."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances : length(distinct([for b in i.role_bindings : b.role])) == length(i.role_bindings)
    ])
    error_message = "role_bindings.role must be unique within each instance; one IAM binding resource exists per role."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for dk, d in i.databases : length(distinct([for b in d.role_bindings : b.role])) == length(d.role_bindings)])
    ])
    error_message = "databases.role_bindings.role must be unique within each database; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : alltrue([for b in i.role_bindings : length(b.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for dk, d in i.databases : alltrue([for b in d.role_bindings : length(b.members) > 0])])
    ])
    error_message = "databases.role_bindings.members must contain at least one member."
  }

  validation {
    condition     = alltrue([for k in keys(var.instances) : !can(regex("/", k))])
    error_message = "instance keys must not contain '/'; it is used as a composite-key separator in outputs."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for dk in keys(i.databases) : !can(regex("/", dk))])
    ])
    error_message = "databases keys must not contain '/'; it is used as a composite-key separator in outputs."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for bk in keys(i.role_bindings) : !can(regex("/", bk))])
    ])
    error_message = "role_bindings keys must not contain '/'; it is used as a composite-key separator in outputs."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for dk, d in i.databases : alltrue([for bk in keys(d.role_bindings) : !can(regex("/", bk))])])
    ])
    error_message = "databases.role_bindings keys must not contain '/'; it is used as a composite-key separator in outputs."
  }
}
