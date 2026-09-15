variable "instances" {
  description = "Map of Bigtable instances keyed by an arbitrary identifier. Each entry creates one google_bigtable_instance with nested clusters plus optional nested tables, app profiles, GC policies, and IAM bindings."
  type = map(object({
    name                = string
    project_id          = optional(string)
    display_name        = optional(string)
    labels              = optional(map(string), {})
    edition             = optional(string)
    deletion_protection = optional(bool, true)
    deletion_policy     = optional(string)
    force_destroy       = optional(bool)
    clusters = map(object({
      cluster_id          = string
      zone                = optional(string)
      num_nodes           = optional(number)
      storage_type        = optional(string)
      kms_key_name        = optional(string)
      node_scaling_factor = optional(string)
      autoscaling_config = optional(object({
        min_nodes      = number
        max_nodes      = number
        cpu_target     = number
        storage_target = optional(number)
      }))
    }))
    app_profiles = optional(map(object({
      app_profile_id                    = string
      description                       = optional(string)
      ignore_warnings                   = optional(bool)
      deletion_policy                   = optional(string)
      multi_cluster_routing_use_any     = optional(bool)
      multi_cluster_routing_cluster_ids = optional(list(string))
      single_cluster_routing = optional(object({
        cluster_id                 = string
        allow_transactional_writes = optional(bool)
      }))
      standard_isolation = optional(object({
        priority = string
      }))
      data_boost_isolation_read_only = optional(object({
        compute_billing_owner = string
      }))
    })), {})
    role_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })), {})
    tables = optional(map(object({
      name                    = string
      split_keys              = optional(list(string))
      deletion_protection     = optional(string)
      deletion_policy         = optional(string)
      change_stream_retention = optional(string)
      column_families = optional(map(object({
        type = optional(string)
      })), {})
      gc_policies = optional(map(object({
        mode            = optional(string)
        ignore_warnings = optional(bool)
        deletion_policy = optional(string)
        max_age = optional(object({
          duration = string
        }))
        max_version = optional(object({
          number = number
        }))
        gc_rules = optional(string)
      })), {})
      automated_backup_policy = optional(object({
        retention_period = string
        frequency        = string
        locations        = optional(list(string))
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
    condition     = alltrue([for k, i in var.instances : can(regex("^[a-z0-9-]{6,33}$", i.name))])
    error_message = "name must be 6-33 characters and contain only hyphens, lowercase letters and digits."
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
    condition     = alltrue([for k, i in var.instances : i.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], i.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for ck, c in i.clusters : can(regex("^[a-z0-9-]{6,30}$", c.cluster_id))])
    ])
    error_message = "clusters.cluster_id must be 6-30 characters and contain only hyphens, lowercase letters and digits."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for ck, c in i.clusters : (c.num_nodes != null) != (c.autoscaling_config != null)])
    ])
    error_message = "each cluster requires exactly one of num_nodes or autoscaling_config; this module deliberately enforces the unambiguous form (the API would ignore num_nodes when both are set)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for ck, c in i.clusters : c.storage_type == null || contains(["SSD", "HDD"], c.storage_type)])
    ])
    error_message = "clusters.storage_type must be SSD or HDD (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for ck, c in i.clusters : c.node_scaling_factor == null || contains(["NodeScalingFactor1X", "NodeScalingFactor2X"], c.node_scaling_factor)])
    ])
    error_message = "clusters.node_scaling_factor must be NodeScalingFactor1X or NodeScalingFactor2X (case-sensitive; API casing)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for ck, c in i.clusters : c.autoscaling_config == null || (c.autoscaling_config.cpu_target >= 10 && c.autoscaling_config.cpu_target <= 80)])
    ])
    error_message = "clusters.autoscaling_config.cpu_target must be between 10 and 80 percent."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for ck, c in i.clusters : c.autoscaling_config == null || c.autoscaling_config.min_nodes <= c.autoscaling_config.max_nodes])
    ])
    error_message = "clusters.autoscaling_config.min_nodes must not exceed max_nodes."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      length(distinct([for ck, c in i.clusters : c.zone if c.zone != null])) == length([for ck, c in i.clusters : c.zone if c.zone != null])
    ])
    error_message = "clusters with an explicit zone must use distinct zones within the same instance; unset zones fall back to the provider zone (plan time cannot check them — set zone explicitly on multi-cluster instances)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for ck, c in i.clusters : c.cluster_id == null || !can(regex("/", ck))])
    ])
    error_message = "clusters keys must not contain '/'; it is used as a composite-key separator in outputs (tables, GC policies)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk, t in i.tables : t.deletion_protection == null || contains(["UNPROTECTED", "PROTECTED"], t.deletion_protection)])
    ])
    error_message = "tables.deletion_protection must be UNPROTECTED or PROTECTED (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk, t in i.tables : t.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], t.deletion_policy)])
    ])
    error_message = "tables.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk, t in i.tables : can(regex("^[a-zA-Z0-9._-]{1,50}$", t.name))])
    ])
    error_message = "tables.name must be 1-50 characters and contain only hyphens, underscores, periods, letters and digits."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([
        for tk, t in i.tables :
        t.change_stream_retention == null ||
        t.change_stream_retention == "0s" ||
        (can(regex("^[0-9]+h[0-9]+m[0-9]+s$", t.change_stream_retention)) && anytrue([
          tonumber(regex("^([0-9]+)h", t.change_stream_retention)[0]) >= 1 && tonumber(regex("^([0-9]+)h", t.change_stream_retention)[0]) <= 167,
          t.change_stream_retention == "168h00m00s",
        ]))
      ])
    ])
    error_message = "tables.change_stream_retention must be a duration string between 1h and 167h59m59s (one second under 7 days), or 0s to disable."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk, t in i.tables :
        alltrue([for fk in keys(t.gc_policies) : !can(regex("/", fk))])
      ])
    ])
    error_message = "tables.gc_policies keys (column family names) must not contain '/'; it is used as a composite-key separator in outputs."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk, t in i.tables :
        alltrue([for fk, p in t.gc_policies :
          sum([for f in [p.max_age != null, p.max_version != null, p.gc_rules != null] : f ? 1 : 0]) == 1
        ])
      ])
    ])
    error_message = "each GC policy requires exactly one of max_age {duration}, max_version {number} or gc_rules (a JSON string; gc_rules conflicts with the other two)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk, t in i.tables :
        alltrue([for fk, p in t.gc_policies :
          p.mode == null || contains(["UNION", "INTERSECTION"], p.mode)
        ])
      ])
    ])
    error_message = "tables.gc_policies.mode must be UNION or INTERSECTION (case-sensitive; required when a second policy exists on the same column family)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk, t in i.tables :
        alltrue([for fk, p in t.gc_policies :
          p.deletion_policy == null || contains(["PREVENT", "ABANDON", "DELETE"], p.deletion_policy)
        ])
      ])
    ])
    error_message = "tables.gc_policies.deletion_policy must be one of PREVENT, ABANDON or DELETE (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for pk, p in i.app_profiles : (p.multi_cluster_routing_use_any == true) != (p.single_cluster_routing != null)])
    ])
    error_message = "app_profiles requires exactly one of multi_cluster_routing_use_any = true or single_cluster_routing."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for pk, p in i.app_profiles : p.standard_isolation == null || contains(["PRIORITY_LOW", "PRIORITY_MEDIUM", "PRIORITY_HIGH"], p.standard_isolation.priority)])
    ])
    error_message = "app_profiles.standard_isolation.priority must be one of PRIORITY_LOW, PRIORITY_MEDIUM or PRIORITY_HIGH (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for pk, p in i.app_profiles : p.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], p.deletion_policy)])
    ])
    error_message = "app_profiles.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
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
      alltrue([for tk, t in i.tables : length(distinct([for b in t.role_bindings : b.role])) == length(t.role_bindings)])
    ])
    error_message = "tables.role_bindings.role must be unique within each table; one IAM binding resource exists per role."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances : alltrue([for b in i.role_bindings : length(b.members) > 0])
    ])
    error_message = "role_bindings.members must contain at least one member."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk, t in i.tables : alltrue([for b in t.role_bindings : length(b.members) > 0])])
    ])
    error_message = "tables.role_bindings.members must contain at least one member."
  }

  validation {
    condition     = alltrue([for k in keys(var.instances) : !can(regex("/", k))])
    error_message = "instance keys must not contain '/'; it is used as a composite-key separator in outputs."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for tk in keys(i.tables) : !can(regex("/", tk))])
    ])
    error_message = "tables keys must not contain '/'; it is used as a composite-key separator in outputs."
  }

  validation {
    condition = alltrue([
      for k, i in var.instances :
      alltrue([for pk in keys(i.app_profiles) : !can(regex("/", pk))])
    ])
    error_message = "app_profiles keys must not contain '/'; it is used as a composite-key separator in outputs."
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
      alltrue([
        for tk, t in i.tables : alltrue([for bk in keys(t.role_bindings) : !can(regex("/", bk))])
      ])
    ])
    error_message = "tables.role_bindings keys must not contain '/'; it is used as a composite-key separator in outputs."
  }
}
