variable "managers" {
  description = "Map of zonal managed instance groups keyed by an arbitrary identifier. Each entry creates one google_compute_instance_group_manager plus an optional google_compute_autoscaler. Chain template self links from gcp/instance-template into versions.instance_template."
  type = map(object({
    name               = string
    base_instance_name = string
    zone               = string
    versions = list(object({
      instance_template = string
      name              = optional(string)
      target_size = optional(object({
        fixed   = optional(number)
        percent = optional(number)
      }))
    }))
    target_size                    = optional(number)
    project_id                     = optional(string)
    description                    = optional(string)
    deletion_policy                = optional(string)
    named_ports                    = optional(list(object({ name = string, port = number })), [])
    target_pools                   = optional(list(string))
    wait_for_instances             = optional(bool)
    wait_for_instances_status      = optional(string)
    list_managed_instances_results = optional(string)
    auto_healing_policies = optional(object({
      health_check      = string
      initial_delay_sec = number
    }))
    all_instances_config = optional(object({
      metadata = optional(map(string))
      labels   = optional(map(string))
    }))
    stateful_disks = optional(list(object({
      device_name = string
      delete_rule = optional(string)
    })), [])
    stateful_internal_ips = optional(list(object({
      interface_name = string
      delete_rule    = optional(string)
    })), [])
    stateful_external_ips = optional(list(object({
      interface_name = string
      delete_rule    = optional(string)
    })), [])
    update_policy = optional(object({
      type                           = string
      minimal_action                 = string
      most_disruptive_allowed_action = optional(string)
      max_surge_fixed                = optional(number)
      max_surge_percent              = optional(number)
      max_unavailable_fixed          = optional(number)
      max_unavailable_percent        = optional(number)
      replacement_method             = optional(string)
    }))
    instance_lifecycle_policy = optional(object({
      force_update_on_repair    = optional(string)
      default_action_on_failure = optional(string)
      on_failed_health_check    = optional(string)
      on_repair = optional(object({
        allow_changing_zone = optional(string)
      }))
    }))
    standby_policy = optional(object({
      initial_delay_sec = optional(number)
      mode              = optional(string)
    }))
    target_stopped_size   = optional(number)
    target_suspended_size = optional(number)
    autoscaler = optional(object({
      name        = optional(string)
      description = optional(string)
      autoscaling_policy = object({
        min_replicas         = number
        max_replicas         = number
        cooldown_period      = optional(number)
        stabilization_period = optional(number)
        mode                 = optional(string)
        cpu_utilization = optional(object({
          target            = number
          predictive_method = optional(string)
        }))
        metric = optional(list(object({
          name                       = string
          target                     = optional(number)
          single_instance_assignment = optional(number)
          type                       = optional(string)
          filter                     = optional(string)
        })), [])
        load_balancing_utilization = optional(object({
          target = number
        }))
        scaling_schedules = optional(list(object({
          name                  = string
          min_required_replicas = number
          schedule              = string
          duration_sec          = number
          time_zone             = optional(string)
          disabled              = optional(bool)
          description           = optional(string)
        })), [])
        scale_in_control = optional(object({
          time_window_sec = optional(number)
          max_scaled_in_replicas = optional(object({
            fixed   = optional(number)
            percent = optional(number)
          }))
        }))
      })
      deletion_policy = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for m in var.managers : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", m.name)) && can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", m.base_instance_name))])
    error_message = "name and base_instance_name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for m in var.managers : can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", m.zone))])
    error_message = "zone must look like a GCP zone name (e.g. us-central1-a); it is a shape check, not a list of valid zones."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", m.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for m in var.managers : length(m.versions) > 0 && alltrue([for v in m.versions : can(regex("instanceTemplates", v.instance_template))])])
    error_message = "versions must be non-empty and each versions[].instance_template must be an instance template self link or id (it must contain the substring 'instanceTemplates'); pass gcp/instance-template's template_self_link_uniques output."
  }

  validation {
    condition     = alltrue([for m in var.managers : length([for v in m.versions : v if v.target_size == null]) == 1])
    error_message = "exactly one version per manager must omit target_size; remaining instances are provisioned with that version."
  }

  validation {
    condition     = alltrue([for m in var.managers : alltrue([for v in m.versions : v.target_size == null || (v.target_size.fixed != null) != (v.target_size.percent != null)])])
    error_message = "versions[].target_size needs exactly one of fixed or percent (they conflict)."
  }

  validation {
    condition     = alltrue([for m in var.managers : alltrue([for v in m.versions : (v.target_size == null || v.target_size.percent == null || v.target_size.percent >= 0 && v.target_size.percent <= 100) && (v.target_size == null || v.target_size.fixed == null || v.target_size.fixed >= 0)])])
    error_message = "versions[].target_size.percent must be 0-100 inclusive; versions[].target_size.fixed must be >= 0."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.target_size == null || m.target_size >= 0])
    error_message = "target_size must be >= 0 when set."
  }

  validation {
    condition     = alltrue([for m in var.managers : alltrue([for p in m.named_ports : p.port >= 1 && p.port <= 65535])])
    error_message = "named_ports[].port must be between 1 and 65535."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.wait_for_instances_status == null || contains(["STABLE", "UPDATED"], m.wait_for_instances_status)])
    error_message = "wait_for_instances_status must be STABLE or UPDATED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.list_managed_instances_results == null || contains(["PAGELESS", "PAGINATED"], m.list_managed_instances_results)])
    error_message = "list_managed_instances_results must be PAGELESS or PAGINATED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.auto_healing_policies == null || m.auto_healing_policies.initial_delay_sec >= 0 && m.auto_healing_policies.initial_delay_sec <= 3600])
    error_message = "auto_healing_policies.initial_delay_sec must be between 0 and 3600 seconds."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.update_policy == null || alltrue([for u in [m.update_policy] : contains(["PROACTIVE", "OPPORTUNISTIC"], u.type) && contains(["NONE", "REFRESH", "RESTART", "REPLACE"], u.minimal_action) && (u.most_disruptive_allowed_action == null || contains(["NONE", "REFRESH", "RESTART", "REPLACE"], u.most_disruptive_allowed_action)) && (u.replacement_method == null || contains(["RECREATE", "SUBSTITUTE"], u.replacement_method)) && (u.replacement_method != "RECREATE" || coalesce(u.max_unavailable_fixed, 0) > 0 || coalesce(u.max_unavailable_percent, 0) > 0)])])
    error_message = "update_policy.type must be PROACTIVE or OPPORTUNISTIC; minimal_action and most_disruptive_allowed_action must be one of NONE, REFRESH, RESTART, REPLACE; replacement_method must be RECREATE or SUBSTITUTE; RECREATE requires max_unavailable_fixed or max_unavailable_percent > 0."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.update_policy == null || !(m.update_policy.max_surge_fixed != null && m.update_policy.max_surge_percent != null)])
    error_message = "update_policy.max_surge_fixed and max_surge_percent conflict; set at most one."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.update_policy == null || !(m.update_policy.max_unavailable_fixed != null && m.update_policy.max_unavailable_percent != null)])
    error_message = "update_policy.max_unavailable_fixed and max_unavailable_percent conflict; set at most one."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.update_policy == null || alltrue([for u in [m.update_policy] : (u.max_surge_percent == null || u.max_surge_percent >= 0 && u.max_surge_percent <= 100) && (u.max_unavailable_percent == null || u.max_unavailable_percent >= 0 && u.max_unavailable_percent <= 100) && (u.max_surge_fixed == null || u.max_surge_fixed >= 0) && (u.max_unavailable_fixed == null || u.max_unavailable_fixed >= 0)])])
    error_message = "update_policy max_surge/max_unavailable percents must be 0-100 inclusive and fixed values >= 0."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.instance_lifecycle_policy == null || alltrue([for p in [m.instance_lifecycle_policy] : (p.force_update_on_repair == null || contains(["YES", "NO"], p.force_update_on_repair)) && (p.default_action_on_failure == null || contains(["DO_NOTHING", "REPAIR"], p.default_action_on_failure)) && (p.on_failed_health_check == null || contains(["DEFAULT_ACTION", "DO_NOTHING", "REPAIR"], p.on_failed_health_check)) && (p.on_repair == null || p.on_repair.allow_changing_zone == null || contains(["YES", "NO"], p.on_repair.allow_changing_zone))])])
    error_message = "instance_lifecycle_policy.force_update_on_repair and on_repair.allow_changing_zone must be YES or NO; default_action_on_failure must be DO_NOTHING or REPAIR; on_failed_health_check must be DEFAULT_ACTION, DO_NOTHING or REPAIR (case-sensitive)."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], m.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.standby_policy == null || alltrue([for s in [m.standby_policy] : (s.mode == null || contains(["MANUAL", "SCALE_OUT_POOL"], s.mode)) && (s.initial_delay_sec == null || s.initial_delay_sec >= 0 && s.initial_delay_sec <= 3600)])])
    error_message = "standby_policy.mode must be MANUAL or SCALE_OUT_POOL; standby_policy.initial_delay_sec must be between 0 and 3600 seconds."
  }

  validation {
    condition     = alltrue([for m in var.managers : alltrue(concat([for d in m.stateful_disks : d.delete_rule == null || contains(["NEVER", "ON_PERMANENT_INSTANCE_DELETION"], d.delete_rule)], [for i in m.stateful_internal_ips : i.delete_rule == null || contains(["NEVER", "ON_PERMANENT_INSTANCE_DELETION"], i.delete_rule)], [for e in m.stateful_external_ips : e.delete_rule == null || contains(["NEVER", "ON_PERMANENT_INSTANCE_DELETION"], e.delete_rule)]))])
    error_message = "stateful delete_rule (disks, internal ips, external ips) must be NEVER or ON_PERMANENT_INSTANCE_DELETION (case-sensitive)."
  }

  validation {
    condition     = alltrue([for m in var.managers : (m.target_stopped_size == null || m.target_stopped_size >= 0) && (m.target_suspended_size == null || m.target_suspended_size >= 0)])
    error_message = "target_stopped_size and target_suspended_size must be >= 0 when set."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || m.autoscaler.name == null || can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", m.autoscaler.name))])
    error_message = "autoscaler.name must be a valid RFC1035 name when set (defaults to the manager's name)."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || m.autoscaler.autoscaling_policy.min_replicas >= 0 && m.autoscaler.autoscaling_policy.max_replicas >= m.autoscaler.autoscaling_policy.min_replicas])
    error_message = "autoscaler.autoscaling_policy.min_replicas must be >= 0 and max_replicas must be >= min_replicas."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || m.autoscaler.autoscaling_policy.mode == null || contains(["ON", "OFF", "ONLY_SCALE_OUT"], m.autoscaler.autoscaling_policy.mode)])
    error_message = "autoscaler.autoscaling_policy.mode must be ON, OFF or ONLY_SCALE_OUT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || m.autoscaler.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], m.autoscaler.deletion_policy)])
    error_message = "autoscaler.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || (m.autoscaler.autoscaling_policy.cpu_utilization != null || length(m.autoscaler.autoscaling_policy.metric) > 0 || m.autoscaler.autoscaling_policy.load_balancing_utilization != null || length(m.autoscaler.autoscaling_policy.scaling_schedules) > 0)])
    error_message = "autoscaler.autoscaling_policy needs at least one scaling signal: cpu_utilization, metric, load_balancing_utilization or scaling_schedules."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || m.autoscaler.autoscaling_policy.cpu_utilization == null || m.autoscaler.autoscaling_policy.cpu_utilization.target > 0 && m.autoscaler.autoscaling_policy.cpu_utilization.target <= 1 && (m.autoscaler.autoscaling_policy.cpu_utilization.predictive_method == null || contains(["NONE", "OPTIMIZE_AVAILABILITY"], m.autoscaler.autoscaling_policy.cpu_utilization.predictive_method))])
    error_message = "autoscaler cpu_utilization.target must be in the range (0, 1]; predictive_method must be NONE or OPTIMIZE_AVAILABILITY."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || alltrue([for g in m.autoscaler.autoscaling_policy.metric : (g.type == null || contains(["GAUGE", "DELTA_PER_SECOND", "DELTA_PER_MINUTE"], g.type)) && (g.target == null || g.target > 0)])])
    error_message = "autoscaler metric.type must be GAUGE, DELTA_PER_SECOND or DELTA_PER_MINUTE (case-sensitive); metric.target must be > 0 when set."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || m.autoscaler.autoscaling_policy.load_balancing_utilization == null || m.autoscaler.autoscaling_policy.load_balancing_utilization.target > 0])
    error_message = "autoscaler load_balancing_utilization.target must be > 0 when set."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || alltrue([for s in m.autoscaler.autoscaling_policy.scaling_schedules : s.duration_sec >= 300])])
    error_message = "autoscaler scaling_schedules.duration_sec must be at least 300 seconds."
  }

  validation {
    condition     = alltrue([for m in var.managers : m.autoscaler == null || m.autoscaler.autoscaling_policy.scale_in_control == null || m.autoscaler.autoscaling_policy.scale_in_control.max_scaled_in_replicas == null || ((m.autoscaler.autoscaling_policy.scale_in_control.max_scaled_in_replicas.percent == null || m.autoscaler.autoscaling_policy.scale_in_control.max_scaled_in_replicas.percent >= 0 && m.autoscaler.autoscaling_policy.scale_in_control.max_scaled_in_replicas.percent <= 100) && (m.autoscaler.autoscaling_policy.scale_in_control.max_scaled_in_replicas.fixed == null || m.autoscaler.autoscaling_policy.scale_in_control.max_scaled_in_replicas.fixed > 0))])
    error_message = "autoscaler scale_in_control.max_scaled_in_replicas.percent must be 0-100 inclusive and fixed a positive integer when set."
  }
}
