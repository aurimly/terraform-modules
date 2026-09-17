variable "instances" {
  description = "Map of STACKIT LogMe instances keyed by an arbitrary identifier. Each entry creates one instance in the given project and region."
  type = map(object({
    project_id = string
    name       = string
    version    = string
    plan_name  = string
    region     = optional(string)
    parameters = optional(object({
      sgw_acl                  = optional(string)
      enable_monitoring        = optional(bool)
      graphite                 = optional(string)
      max_disk_threshold       = optional(number)
      metrics_frequency        = optional(number)
      metrics_prefix           = optional(string)
      monitoring_instance_id   = optional(string)
      java_heapspace           = optional(number)
      java_maxmetaspace        = optional(number)
      ism_deletion_after       = optional(string)
      ism_jitter               = optional(number)
      ism_job_interval         = optional(number)
      fluentd_tcp              = optional(number)
      fluentd_udp              = optional(number)
      fluentd_tls              = optional(number)
      fluentd_tls_ciphers      = optional(string)
      fluentd_tls_min_version  = optional(string)
      fluentd_tls_max_version  = optional(string)
      fluentd_tls_version      = optional(string)
      opensearch_tls_ciphers   = optional(list(string))
      opensearch_tls_protocols = optional(list(string))
      syslog                   = optional(list(string))
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

  validation {
    condition     = alltrue([for i in var.instances : i.parameters == null || i.parameters.ism_deletion_after == null || can(regex("^[0-9]+[smhd]$", i.parameters.ism_deletion_after))])
    error_message = "parameters.ism_deletion_after must be an integer followed by a unit of s, m, h or d (e.g. \"14d\")."
  }
}
