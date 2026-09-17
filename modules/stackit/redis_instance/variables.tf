variable "instances" {
  description = "Map of STACKIT Redis instances keyed by an arbitrary identifier. Each entry creates one instance in the given project and region."
  type = map(object({
    project_id = string
    name       = string
    version    = string
    plan_name  = string
    region     = optional(string)
    parameters = optional(object({
      sgw_acl                 = optional(string)
      enable_monitoring       = optional(bool)
      down_after_milliseconds = optional(number)
      failover_timeout        = optional(number)
      graphite                = optional(string)
      lazyfree_lazy_eviction  = optional(string)
      lazyfree_lazy_expire    = optional(string)
      lua_time_limit          = optional(number)
      max_disk_threshold      = optional(number)
      maxclients              = optional(number)
      maxmemory_policy        = optional(string)
      maxmemory_samples       = optional(number)
      metrics_frequency       = optional(number)
      metrics_prefix          = optional(string)
      min_replicas_max_lag    = optional(number)
      monitoring_instance_id  = optional(string)
      notify_keyspace_events  = optional(string)
      snapshot                = optional(string)
      syslog                  = optional(list(string))
      tls_ciphers             = optional(list(string))
      tls_ciphersuites        = optional(string)
      tls_protocols           = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.name) >= 1])
    error_message = "name must be at least 1 character."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.plan_name) >= 1])
    error_message = "plan_name must be at least 1 character."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.parameters == null || i.parameters.sgw_acl == null || alltrue([for cidr in split(",", i.parameters.sgw_acl) : can(cidrhost(trimspace(cidr), 0)) && can(regex("\\.", trimspace(cidr)))])])
    error_message = "parameters.sgw_acl must be a comma-separated list of valid IPv4 CIDRs."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.parameters == null || i.parameters.monitoring_instance_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.parameters.monitoring_instance_id))])
    error_message = "parameters.monitoring_instance_id must be a UUID."
  }
}
