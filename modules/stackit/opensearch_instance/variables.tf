variable "instances" {
  description = "Map of STACKIT OpenSearch instances keyed by an arbitrary identifier. Each entry creates one instance in the given project and region."
  type = map(object({
    project_id = string
    name       = string
    version    = string
    plan_name  = string
    region     = optional(string)
    parameters = optional(object({
      sgw_acl                = optional(string)
      enable_monitoring      = optional(bool)
      graphite               = optional(string)
      java_garbage_collector = optional(string)
      java_heapspace         = optional(number)
      java_maxmetaspace      = optional(number)
      max_disk_threshold     = optional(number)
      metrics_frequency      = optional(number)
      metrics_prefix         = optional(string)
      monitoring_instance_id = optional(string)
      plugins                = optional(list(string))
      syslog                 = optional(list(string))
      tls_ciphers            = optional(list(string))
      tls_protocols          = optional(list(string))
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
