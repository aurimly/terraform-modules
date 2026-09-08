variable "load_balancers" {
  description = "Map of STACKIT load balancers keyed by an arbitrary identifier. Each entry creates one load balancer with listeners and target pools."
  type = map(object({
    name                              = string
    project_id                        = string
    region                            = optional(string)
    plan_id                           = optional(string)
    external_address                  = optional(string)
    disable_security_group_assignment = optional(bool)
    options = optional(object({
      private_network_only = optional(bool)
      acl                  = optional(set(string))
      observability = optional(object({
        logs = optional(object({
          credentials_ref = optional(string)
          push_url        = optional(string)
        }))
        metrics = optional(object({
          credentials_ref = optional(string)
          push_url        = optional(string)
        }))
      }))
    }))
    network = object({
      network_id = string
      role       = string
    })
    listeners = map(object({
      port         = number
      protocol     = string
      target_pool  = string
      display_name = optional(string)
      tcp = optional(object({
        idle_timeout = optional(string)
      }))
      udp = optional(object({
        idle_timeout = optional(string)
      }))
    }))
    target_pools = map(object({
      name        = string
      target_port = number
      targets = map(object({
        display_name = string
        ip           = string
      }))
      active_health_check = optional(object({
        healthy_threshold   = optional(number)
        interval            = optional(string)
        interval_jitter     = optional(string)
        timeout             = optional(string)
        unhealthy_threshold = optional(number)
      }))
      session_persistence = optional(object({
        use_source_ip_address = optional(bool)
      }))
    }))
  }))

  validation {
    condition     = alltrue([for lb in var.load_balancers : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", lb.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : length(lb.name) >= 1 && length(lb.name) <= 63 && !can(regex(",", lb.name))])
    error_message = "name must be 1 to 63 characters and must not contain a comma (the import ID is comma-joined)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.plan_id == null || contains(["p10", "p50", "p250", "p750"], lb.plan_id)])
    error_message = "plan_id must be one of p10, p50, p250 or p750."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", lb.network.network_id))])
    error_message = "network.network_id must be a UUID."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : contains(["PROTOCOL_TCP", "PROTOCOL_UDP", "PROTOCOL_TCP_PROXY", "PROTOCOL_TLS_PASSTHROUGH", "PROTOCOL_UNSPECIFIED"], l.protocol)])])
    error_message = "listeners protocol must be one of PROTOCOL_TCP, PROTOCOL_UDP, PROTOCOL_TCP_PROXY, PROTOCOL_TLS_PASSTHROUGH or PROTOCOL_UNSPECIFIED."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : (lb.external_address != null) != (lb.options != null && lb.options.private_network_only == true)])
    error_message = "exactly one of external_address or options.private_network_only = true must be set (mirrors the provider rule)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.options == null || lb.options.acl == null || alltrue([for cidr in lb.options.acl : can(cidrhost(cidr, 0))])])
    error_message = "options.acl entries must be valid CIDRs in IPv4 or IPv6 notation."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : length(lb.listeners) >= 1 && length(lb.listeners) <= 20])
    error_message = "each load balancer must have between 1 and 20 listeners (provider rule)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : length(lb.target_pools) >= 1 && length(lb.target_pools) <= 20])
    error_message = "each load balancer must have between 1 and 20 target pools (provider rule)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for p in lb.target_pools : length(p.targets) >= 1 && length(p.targets) <= 1000])])
    error_message = "each target pool must have between 1 and 1000 targets (provider rule)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : length(distinct([for p in lb.target_pools : p.name])) == length(lb.target_pools)])
    error_message = "target_pools names must be unique within a load balancer (listeners reference pools by name)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : anytrue([for p in lb.target_pools : p.name == l.target_pool])])])
    error_message = "listeners target_pool must reference the name of a target_pools entry in the same load balancer."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for p in lb.target_pools : alltrue([for t in p.targets : can(cidrhost("${t.ip}/32", 0)) || can(cidrhost("${t.ip}/128", 0))])])])
    error_message = "targets ip must be a valid IPv4 or IPv6 address."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : l.tcp == null || l.tcp.idle_timeout == null || can(regex("^(\\d{1,3}|[1-2]\\d{3}|3[0-5]\\d{2}|3600)s$", l.tcp.idle_timeout))])])
    error_message = "listeners tcp.idle_timeout must be a duration in seconds (e.g. \"90s\") of at most 3600."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : l.udp == null || l.udp.idle_timeout == null || can(regex("^(\\d{1,2}|1[0-1]\\d|120)s$", l.udp.idle_timeout))])])
    error_message = "listeners udp.idle_timeout must be a duration in seconds (e.g. \"30s\") of at most 120."
  }
}
