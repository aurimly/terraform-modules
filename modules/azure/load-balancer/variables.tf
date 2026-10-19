variable "public_ips" {
  description = "Map of in-module Azure public IPs for load balancer frontends, keyed by an arbitrary identifier. Load balancer public IPs are Standard SKU, Static, IPv4 — the trimmed azurerm_public_ip shape below reflects that. Entries are optional; frontends may instead reference existing public IPs by full ARM resource ID."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    availability_zone   = optional(string)
    domain_name_label   = optional(string)
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.public_ips) : !can(regex("\\.", key))
    ])
    error_message = "public_ips map keys must not contain \".\" — keys are referenced by frontend_ip_configurations public_ip_key and a dot would make output keys ambiguous."
  }

  validation {
    condition = alltrue(flatten([
      for key, p in var.public_ips : [
        for other_key, q in var.public_ips :
        key == other_key || lower(p.name) != lower(q.name) || lower(p.resource_group_name) != lower(q.resource_group_name)
      ]
    ]))
    error_message = "public IP names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : length(trimspace(p.name)) > 0 && length(trimspace(p.resource_group_name)) > 0 && length(trimspace(p.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : p.availability_zone == null || contains(["1", "2", "3"], p.availability_zone)
    ])
    error_message = "availability_zone must be \"1\", \"2\" or \"3\" (case-sensitive), or left unset for no zone pinning."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : length(p.tags) <= 50 && alltrue([for k, v in p.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "load_balancers" {
  description = "Map of Azure Standard load balancers keyed by an arbitrary identifier. Each entry creates one azurerm_lb in the named resource group; backend address pools, pool addresses, NIC associations, probes, rules, NAT rules, NAT pools and outbound rules are separate resources the module flattens from nested maps. The Basic SKU is retired upstream — sku is pinned Standard and only the tier varies."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku_tier            = optional(string, "Regional")
    edge_zone           = optional(string)

    frontend_ip_configurations = map(object({
      name = string
      # public frontend: exactly one of public_ip_key (an in-module public_ips
      # key) or public_ip_address_id (an existing ARM ID)
      public_ip_key        = optional(string)
      public_ip_address_id = optional(string)
      public_ip_prefix_id  = optional(string)
      # private frontend
      subnet_id                     = optional(string)
      private_ip_address            = optional(string)
      private_ip_address_allocation = optional(string, "Dynamic")
      private_ip_address_version    = optional(string, "IPv4")
      zones                         = optional(list(string), [])
    }))

    backend_address_pools = map(object({
      name               = string
      virtual_network_id = optional(string)
      synchronous_mode   = optional(string)
      addresses = optional(map(object({
        name                                = string
        ip_address                          = optional(string)
        virtual_network_id                  = optional(string)
        backend_address_ip_configuration_id = optional(string)
      })), {})
      nic_associations = optional(map(object({
        network_interface_id  = string
        ip_configuration_name = string
      })), {})
    }))

    probes = optional(map(object({
      name                         = string
      protocol                     = string
      port                         = number
      request_path                 = optional(string)
      interval_in_seconds          = optional(number)
      number_of_probes             = optional(number)
      probe_threshold              = optional(number)
      no_healthy_backends_behavior = optional(string)
    })), {})

    rules = optional(map(object({
      name                          = string
      frontend_ip_configuration_key = string
      backend_address_pool_key      = string
      probe_key                     = optional(string)
      protocol                      = string
      frontend_port                 = number
      backend_port                  = number
      load_distribution             = optional(string, "Default")
      floating_ip_enabled           = optional(bool)
      disable_outbound_snat         = optional(bool)
      tcp_reset_enabled             = optional(bool)
      idle_timeout_in_minutes       = optional(number)
    })), {})

    nat_rules = optional(map(object({
      name                          = string
      frontend_ip_configuration_key = string
      protocol                      = string
      backend_port                  = number
      frontend_port                 = optional(number)
      frontend_port_start           = optional(number)
      frontend_port_end             = optional(number)
      backend_address_pool_key      = optional(string)
      floating_ip_enabled           = optional(bool)
      tcp_reset_enabled             = optional(bool)
      idle_timeout_in_minutes       = optional(number)
    })), {})

    nat_pools = optional(map(object({
      name                          = string
      frontend_ip_configuration_key = string
      protocol                      = string
      frontend_port_start           = number
      frontend_port_end             = number
      backend_port                  = number
      floating_ip_enabled           = optional(bool)
      tcp_reset_enabled             = optional(bool)
      idle_timeout_in_minutes       = optional(number)
    })), {})

    outbound_rules = optional(map(object({
      name                           = string
      backend_address_pool_key       = string
      frontend_ip_configuration_keys = list(string)
      protocol                       = string
      allocated_outbound_ports       = optional(number)
      idle_timeout_in_minutes        = optional(number)
      tcp_reset_enabled              = optional(bool)
    })), {})

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue(concat(
      [for key in keys(var.load_balancers) : !can(regex("\\.", key))],
      flatten([
        for lb in var.load_balancers : [
          for child_key in concat(
            keys(lb.frontend_ip_configurations),
            keys(lb.backend_address_pools),
            keys(lb.probes),
            keys(lb.rules),
            keys(lb.nat_rules),
            keys(lb.nat_pools),
            keys(lb.outbound_rules)
          ) : !can(regex("\\.", child_key))
        ]
      ]),
      flatten([
        for lb in var.load_balancers : [
          for pool in lb.backend_address_pools : [
            for nested_key in concat(keys(pool.addresses), keys(pool.nic_associations)) : !can(regex("\\.", nested_key))
          ]
        ]
      ])
    ))
    error_message = "map keys of load_balancers and its nested maps (frontend_ip_configurations, backend_address_pools, addresses, nic_associations, probes, rules, nat_rules, nat_pools, outbound_rules) must not contain \".\" — keys are composed into child identifiers of the form \"<lb_key>.<child_key>\" (\"<lb_key>.<pool_key>.<address_key>\" for pool-level maps); dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for key, lb in var.load_balancers : [
        for other_key, other in var.load_balancers :
        key == other_key || lower(lb.name) != lower(other.name) || lower(lb.resource_group_name) != lower(other.resource_group_name)
      ]
    ]))
    error_message = "load balancer names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for lb in var.load_balancers : length(trimspace(lb.name)) > 0 && length(trimspace(lb.resource_group_name)) > 0 && length(trimspace(lb.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue([
      for lb in var.load_balancers : contains(["Regional", "Global"], lb.sku_tier)
    ])
    error_message = "sku_tier must be Regional or Global (case-sensitive) — Global is the cross-region tier and requires the public IP frontends to be Global-tier too; the load balancer must live in a supported home region (see Notes). Changing the tier forces replacement."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for fe in lb.frontend_ip_configurations : [
          for zone in fe.zones : contains(["1", "2", "3"], zone)
        ]
      ]
    ]))
    error_message = "frontend_ip_configurations zones entries must be \"1\", \"2\" or \"3\" — availability zone numbers; zones are only supported on the Standard SKU and in select regions. Removing the zones from an existing frontend forces replacement (keep them explicit once set)."
  }

  validation {
    condition = alltrue([
      for lb in var.load_balancers : length(lb.frontend_ip_configurations) >= 1
    ])
    error_message = "each load balancer requires at least one frontend_ip_configuration — Azure does not allow the complete removal of all previously attached frontend configurations; removing them all forces a replacement (destroy/create) of the load balancer."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for fe in lb.frontend_ip_configurations : [
          (fe.public_ip_key != null || fe.public_ip_address_id != null) != (fe.subnet_id != null),
          fe.public_ip_key == null || fe.public_ip_address_id == null,
          fe.public_ip_key == null || contains(keys(var.public_ips), fe.public_ip_key),
          fe.public_ip_address_id == null || can(regex("^/", fe.public_ip_address_id)),
          fe.public_ip_prefix_id == null || (fe.public_ip_key != null || fe.public_ip_address_id != null),
          fe.private_ip_address_allocation != "Static" || fe.private_ip_address != null
        ]
      ]
    ]))
    error_message = "each frontend_ip_configuration is either public or private — public frontends set exactly one of public_ip_key (an existing public_ips map key for an in-module IP) or public_ip_address_id (a full ARM resource ID), never both; private frontends set subnet_id and cannot carry a public IP reference. public_ip_prefix_id only rides along on a public frontend (Azure takes public IP prefixes on outbound-rule frontends), and a Static private_ip_address_allocation requires private_ip_address."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for pool in lb.backend_address_pools : [
          pool.virtual_network_id == null || (pool.synchronous_mode != null && contains(["Automatic", "Manual"], pool.synchronous_mode)),
          pool.synchronous_mode == null || pool.virtual_network_id != null
        ]
      ]
    ]))
    error_message = "backend_address_pools synchronous_mode must be Automatic or Manual (case-sensitive) and is required when virtual_network_id is set — the synchronous mode only applies to cross-region backends attached by virtual network; it has nothing to configure without one."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for pool in lb.backend_address_pools : [
          for addr in pool.addresses : [
            (addr.backend_address_ip_configuration_id != null) != (addr.ip_address != null || addr.virtual_network_id != null),
            addr.backend_address_ip_configuration_id != null || addr.ip_address != null && addr.virtual_network_id != null,
            addr.backend_address_ip_configuration_id == null || can(regex("^/", addr.backend_address_ip_configuration_id))
          ]
        ]
      ]
    ]))
    error_message = "backend_address_pools addresses take exactly one form — regional backends set both ip_address and virtual_network_id (the NIC's private IP in that virtual network), cross-region backends set backend_address_ip_configuration_id (a full ARM resource ID of the regional frontend's IP configuration) and neither of the other two."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for probe in lb.probes : [
          contains(["Http", "Https", "Tcp"], probe.protocol),
          probe.port >= 1 && probe.port <= 65535,
          contains(["Http", "Https"], probe.protocol) ? probe.request_path != null : probe.request_path == null,
          probe.request_path == null || startswith(probe.request_path, "/"),
          probe.interval_in_seconds == null || probe.interval_in_seconds >= 5,
          coalesce(probe.number_of_probes, 2) * coalesce(probe.interval_in_seconds, 15) >= 10,
          probe.probe_threshold == null || (probe.probe_threshold >= 1 && probe.probe_threshold <= 100),
          probe.no_healthy_backends_behavior == null || contains(["AllProbedDown", "AllProbedUp"], probe.no_healthy_backends_behavior)
        ]
      ]
    ]))
    error_message = "probes: protocol must be Http, Https or Tcp (case-sensitive); port 1–65535; request_path is required for Http/Https (starting with \"/\") and not allowed for Tcp; interval_in_seconds at least 5 (default 15); number_of_probes (default 2) times the interval must be at least 10 seconds; probe_threshold 1–100; no_healthy_backends_behavior AllProbedDown or AllProbedUp (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for rule in lb.rules : [
          contains(keys(lb.frontend_ip_configurations), rule.frontend_ip_configuration_key),
          contains(keys(lb.backend_address_pools), rule.backend_address_pool_key),
          rule.probe_key == null || contains(keys(lb.probes), rule.probe_key),
          contains(["Tcp", "Udp", "All"], rule.protocol),
          rule.frontend_port >= 0 && rule.frontend_port <= 65534,
          rule.backend_port >= 0 && rule.backend_port <= 65535,
          contains(["Default", "SourceIP", "SourceIPProtocol"], rule.load_distribution),
          rule.idle_timeout_in_minutes == null || (rule.idle_timeout_in_minutes >= 4 && rule.idle_timeout_in_minutes <= 100)
        ]
      ]
    ]))
    error_message = "rules: frontend_ip_configuration_key, backend_address_pool_key and probe_key (when set) must reference sibling map keys of the same load balancer entry; protocol must be Tcp, Udp or All (case-sensitive); frontend_port 0–65534 and backend_port 0–65535; load_distribution one of Default, SourceIP or SourceIPProtocol (case-sensitive); idle_timeout_in_minutes 4–100 when set."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for rule in lb.nat_rules : [
          (rule.frontend_port != null) != (rule.frontend_port_start != null || rule.frontend_port_end != null || rule.backend_address_pool_key != null),
          rule.frontend_port_start == null && rule.frontend_port_end == null && rule.backend_address_pool_key == null || (rule.frontend_port_start != null && rule.frontend_port_end != null && rule.backend_address_pool_key != null),
          contains(keys(lb.frontend_ip_configurations), rule.frontend_ip_configuration_key),
          rule.backend_address_pool_key == null || contains(keys(lb.backend_address_pools), rule.backend_address_pool_key),
          contains(["Tcp", "Udp", "All"], rule.protocol),
          rule.backend_port >= 1 && rule.backend_port <= 65535,
          rule.frontend_port == null || (rule.frontend_port >= 1 && rule.frontend_port <= 65534),
          rule.frontend_port_start == null || (rule.frontend_port_start >= 1 && rule.frontend_port_start <= 65534 && rule.frontend_port_end != null && rule.frontend_port_end >= rule.frontend_port_start && rule.frontend_port_end <= 65534),
          rule.idle_timeout_in_minutes == null || (rule.idle_timeout_in_minutes >= 4 && rule.idle_timeout_in_minutes <= 30)
        ]
      ]
    ]))
    error_message = "nat_rules take exactly one form — the single-port form for VM/NIC backends (frontend_port only) or the NAT-rule-v2 form for VMSS backends (frontend_port_start and frontend_port_end plus backend_address_pool_key together); never both and never a partial range trio. frontend_ip_configuration_key and backend_address_pool_key (when set) must reference sibling map keys of the same load balancer entry; protocol must be Tcp, Udp or All (case-sensitive); frontend ports 1–65534 with start ≤ end, backend_port 1–65535; idle_timeout_in_minutes 4–30 when set."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for pool in lb.nat_pools : [
          contains(keys(lb.frontend_ip_configurations), pool.frontend_ip_configuration_key),
          contains(["Tcp", "Udp", "All"], pool.protocol),
          pool.frontend_port_start >= 1 && pool.frontend_port_start <= 65534,
          pool.frontend_port_end >= 1 && pool.frontend_port_end <= 65534,
          pool.frontend_port_start <= pool.frontend_port_end,
          pool.backend_port >= 1 && pool.backend_port <= 65535,
          pool.idle_timeout_in_minutes == null || (pool.idle_timeout_in_minutes >= 4 && pool.idle_timeout_in_minutes <= 30)
        ]
      ]
    ]))
    error_message = "nat_pools: frontend_ip_configuration_key must reference a sibling frontend_ip_configurations key of the same load balancer entry; protocol must be Tcp, Udp or All (case-sensitive); frontend ports 1–65534 with start ≤ end; backend_port 1–65535; idle_timeout_in_minutes 4–30 when set. Inbound NAT pools target VMSS backends — see Notes."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for rule in lb.outbound_rules : [
          contains(keys(lb.backend_address_pools), rule.backend_address_pool_key),
          length(rule.frontend_ip_configuration_keys) >= 1,
          alltrue([for fe_key in rule.frontend_ip_configuration_keys : contains(keys(lb.frontend_ip_configurations), fe_key)]),
          contains(["Tcp", "Udp", "All"], rule.protocol)
        ]
      ]
    ]))
    error_message = "outbound_rules: backend_address_pool_key must reference a sibling backend_address_pools key and frontend_ip_configuration_keys a non-empty list of sibling frontend_ip_configurations keys of the same load balancer entry; protocol must be Tcp, Udp or All (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for names in [[for fe in lb.frontend_ip_configurations : lower(fe.name)], [for pool in lb.backend_address_pools : lower(pool.name)], [for probe in lb.probes : lower(probe.name)], [for rule in lb.rules : lower(rule.name)], [for rule in lb.nat_rules : lower(rule.name)], [for pool in lb.nat_pools : lower(pool.name)], [for rule in lb.outbound_rules : lower(rule.name)]] : [
          for a in range(length(names)) : alltrue([
            for b in range(length(names)) : a == b || names[a] != names[b]
          ])
        ]
      ]
    ]))
    error_message = "names must be unique within their family per load balancer (frontend IP configurations, backend address pools, probes, rules, NAT rules, NAT pools, outbound rules — case-insensitively) — the API rejects duplicates."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for pool in lb.backend_address_pools : [
          for names in [[for addr in pool.addresses : lower(addr.name)]] : [
            for a in range(length(names)) : alltrue([
              for b in range(length(names)) : a == b || names[a] != names[b]
            ])
          ]
        ]
      ]
    ]))
    error_message = "backend pool address names must be unique within their pool, case-insensitively — the API rejects duplicates."
  }

  validation {
    condition = alltrue([
      for lb in var.load_balancers : length(lb.tags) <= 50 && alltrue([for k, v in lb.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits) — checked on the load balancer."
  }
}
