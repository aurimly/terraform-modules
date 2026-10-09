variable "public_ips" {
  description = "Map of in-module Azure public IPs for firewall IP configurations, keyed by an arbitrary identifier. Firewall public IPs are Standard SKU, Static, IPv4 — the trimmed azurerm_public_ip shape below reflects that. Entries are optional; IP configurations may instead reference existing public IPs by full ARM resource ID."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    availability_zone   = optional(string)
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.public_ips) : !can(regex("\\.", key))
    ])
    error_message = "public_ips map keys must not contain \".\" — keys are referenced by ip_configurations public_ip_key and a dot would make output keys ambiguous."
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

variable "firewall_policies" {
  description = "Map of Azure Firewall Policies keyed by an arbitrary identifier. Elements referenced by firewalls via firewall_policy_key. Policies and their rule collection groups are independent resources, so one policy can serve multiple firewalls or chain from an external base policy."
  type = map(object({
    name                              = string
    resource_group_name               = string
    location                          = string
    sku                               = optional(string, "Standard")
    base_policy_id                    = optional(string)
    dns                               = optional(object({ proxy_enabled = optional(bool, false), servers = optional(list(string), []) }))
    threat_intelligence_mode          = optional(string, "Alert")
    threat_intelligence_allowlist     = optional(object({ ip_addresses = optional(list(string), []), fqdns = optional(list(string), []) }))
    private_ip_ranges                 = optional(list(string))
    auto_learn_private_ranges_enabled = optional(bool)
    sql_redirect_allowed              = optional(bool)
    tags                              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.firewall_policies) : !can(regex("\\.", key))
    ])
    error_message = "firewall_policies map keys must not contain \".\" — keys are composed into rule collection group identifiers of the form \"<policy_key>.<group_key>\"."
  }

  validation {
    condition = alltrue(flatten([
      for key, p in var.firewall_policies : [
        for other_key, q in var.firewall_policies :
        key == other_key || lower(p.name) != lower(q.name) || lower(p.resource_group_name) != lower(q.resource_group_name)
      ]
    ]))
    error_message = "firewall policy names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for p in var.firewall_policies : length(trimspace(p.name)) > 0 && length(trimspace(p.resource_group_name)) > 0 && length(trimspace(p.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue([
      for p in var.firewall_policies : contains(["Standard", "Premium", "Basic"], p.sku)
    ])
    error_message = "sku must be one of Standard, Premium or Basic (case-sensitive). The SKU is immutable — changing it forces replacement."
  }

  validation {
    condition = alltrue([
      for p in var.firewall_policies : p.base_policy_id == null || can(regex("^/", p.base_policy_id))
    ])
    error_message = "base_policy_id, when set, must be a full ARM resource ID (starts with \"/\") of the parent policy policy inherits rules from."
  }

  validation {
    condition = alltrue([
      for p in var.firewall_policies : contains(["Alert", "Deny", "Off"], p.threat_intelligence_mode)
    ])
    error_message = "threat_intelligence_mode must be one of Alert, Deny or Off (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.firewall_policies : [
        for server in p.dns != null ? p.dns.servers : [] : can(cidrnetmask(format("%s/32", server)))
      ]
    ]))
    error_message = "dns.servers entries must be bare IPv4 addresses (e.g. 10.0.0.10) — DNS names, ranges and IPv6 are rejected by the API."
  }

  validation {
    condition = alltrue([
      for p in var.firewall_policies : p.threat_intelligence_allowlist == null || length(p.threat_intelligence_allowlist.ip_addresses) > 0 || length(p.threat_intelligence_allowlist.fqdns) > 0
    ])
    error_message = "threat_intelligence_allowlist, when set, must carry at least one entry — fill ip_addresses and/or fqdns; an allowlist block with neither is rejected."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.firewall_policies : [
        for address in p.threat_intelligence_allowlist != null ? p.threat_intelligence_allowlist.ip_addresses : [] : can(cidrhost(address, 0)) || can(cidrnetmask(format("%s/32", address)))
      ]
    ]))
    error_message = "threat_intelligence_allowlist.ip_addresses entries must be IPv4 addresses or CIDR ranges (e.g. 203.0.113.10 or 203.0.113.0/24)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.firewall_policies : [
        for fqdn in p.threat_intelligence_allowlist != null ? p.threat_intelligence_allowlist.fqdns : [] : length(trimspace(fqdn)) > 0
      ]
    ]))
    error_message = "threat_intelligence_allowlist.fqdns entries must be non-empty fully qualified domain names."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.firewall_policies : [
        for range in p.private_ip_ranges != null ? p.private_ip_ranges : [] : range == "IANAPrivateRanges" || can(cidrhost(range, 0))
      ]
    ]))
    error_message = "private_ip_ranges entries must be CIDR ranges (e.g. 192.168.1.0/24) or the literal IANAPrivateRanges to cover the reserved private ranges set."
  }

  validation {
    condition = alltrue([
      for p in var.firewall_policies : length(p.private_ip_ranges != null ? p.private_ip_ranges : []) == 0 || p.auto_learn_private_ranges_enabled != true
    ])
    error_message = "auto_learn_private_ranges_enabled cannot be true when private_ip_ranges is set — Azure takes the learned or the explicitly listed set, not both."
  }

  validation {
    condition = alltrue([
      for p in var.firewall_policies : length(p.tags) <= 50 && alltrue([for k, v in p.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "firewall_policy_rule_collection_groups" {
  description = "Map of rule collection groups attached to firewall_policies entries, keyed by an arbitrary identifier; group output keys compose as \"<policy_key>.<group_key>\". Rule collections nest inside a group: application, network and NAT collections each with their own priority, action and rules."
  type = map(object({
    firewall_policy_key = string
    name                = string
    priority            = number
    application_rule_collections = optional(map(object({
      name     = string
      priority = number
      action   = string
      rules = map(object({
        name                  = string
        description           = optional(string)
        protocols             = optional(map(object({ type = string, port = number })), {})
        source_addresses      = optional(list(string), [])
        source_ip_groups      = optional(list(string), [])
        destination_addresses = optional(list(string), [])
        destination_fqdns     = optional(list(string), [])
        destination_fqdn_tags = optional(list(string), [])
        destination_urls      = optional(list(string), [])
        web_categories        = optional(list(string), [])
        terminate_tls         = optional(bool)
        http_headers          = optional(map(object({ name = string, value = string })), {})
      }))
    })), {})
    network_rule_collections = optional(map(object({
      name     = string
      priority = number
      action   = string
      rules = map(object({
        name                  = string
        description           = optional(string)
        protocols             = list(string)
        destination_ports     = optional(list(string), [])
        source_addresses      = optional(list(string), [])
        source_ip_groups      = optional(list(string), [])
        destination_addresses = optional(list(string), [])
        destination_ip_groups = optional(list(string), [])
        destination_fqdns     = optional(list(string), [])
      }))
    })), {})
    nat_rule_collections = optional(map(object({
      name     = string
      priority = number
      action   = string
      rules = map(object({
        name                = string
        description         = optional(string)
        protocols           = list(string)
        source_addresses    = optional(list(string), [])
        source_ip_groups    = optional(list(string), [])
        destination_address = string
        destination_ports   = optional(list(string), [])
        translated_address  = optional(string)
        translated_fqdn     = optional(string)
        translated_port     = number
      }))
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.firewall_policy_rule_collection_groups) : !can(regex("\\.", key))
    ])
    error_message = "firewall_policy_rule_collection_groups map keys must not contain \".\" — keys are composed into resource identifiers of the form \"<policy_key>.<group_key>\"."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection_key in concat(keys(group.application_rule_collections), keys(group.network_rule_collections), keys(group.nat_rule_collections)) : !can(regex("\\.", collection_key))
      ]
    ]))
    error_message = "rule collection map keys must not contain \".\"."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for rule_collection in concat([for rc in group.application_rule_collections : rc], [for rc in group.network_rule_collections : rc], [for rc in group.nat_rule_collections : rc]) : [
          for rule_key in keys(rule_collection.rules) : !can(regex("\\.", rule_key))
        ]
      ]
    ]))
    error_message = "rule map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for group in var.firewall_policy_rule_collection_groups : contains(keys(var.firewall_policies), group.firewall_policy_key)
    ])
    error_message = "rule collection group firewall_policy_key must reference an existing firewall_policies map key — groups attach to azurerm_firewall_policy resources by key."
  }

  validation {
    condition = alltrue([
      for group in var.firewall_policy_rule_collection_groups : group.priority >= 100 && group.priority <= 65000
    ])
    error_message = "rule collection group priority must be between 100 and 65000 inclusive."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collections in [concat([for rc in group.application_rule_collections : { name = rc.name, priority = rc.priority }], [for rc in group.network_rule_collections : { name = rc.name, priority = rc.priority }], [for rc in group.nat_rule_collections : { name = rc.name, priority = rc.priority }])] : [
          for i in range(length(collections)) : alltrue([
            for j in range(length(collections)) : i == j || collections[i].name != collections[j].name
        ])]
      ]
    ]))
    error_message = "rule collection names must be unique within their collection group across all three collection types — the API rejects duplicate collection names."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collections in [concat([for rc in group.application_rule_collections : { name = rc.name, priority = rc.priority }], [for rc in group.network_rule_collections : { name = rc.name, priority = rc.priority }], [for rc in group.nat_rule_collections : { name = rc.name, priority = rc.priority }])] : [
          for i in range(length(collections)) : alltrue([
            for j in range(length(collections)) : i == j || collections[i].priority != collections[j].priority
        ])]
      ]
    ]))
    error_message = "rule collection priorities must be unique within their collection group across all three collection types — priorities also form the API-side ordering."
  }

  validation {
    condition = alltrue(flatten([
      for policy_key in keys(var.firewall_policies) : [
        for names in [[for group in var.firewall_policy_rule_collection_groups : group.name if group.firewall_policy_key == policy_key]] : [
          for a in range(length(names)) : alltrue([
            for b in range(length(names)) : a == b || lower(names[a]) != lower(names[b])
          ])
        ]
      ]
    ]))
    error_message = "rule collection group names must be unique within the referenced firewall policy — a policy cannot carry two groups sharing a name."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in concat([for rc in group.application_rule_collections : rc], [for rc in group.network_rule_collections : rc], [for rc in group.nat_rule_collections : rc]) : [
          for rule_names in [[for key, rule in collection.rules : rule.name]] : [
            for a in range(length(rule_names)) : alltrue([
              for b in range(length(rule_names)) : a == b || rule_names[a] != rule_names[b]
            ])
          ]
        ]
      ]
    ]))
    error_message = "rule names must be unique within their collection — duplicate names are rejected by the API."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in concat([for rc in group.application_rule_collections : rc], [for rc in group.network_rule_collections : rc], [for rc in group.nat_rule_collections : rc]) : [
          collection.priority >= 100 && collection.priority <= 65000
        ]
      ]
    ]))
    error_message = "rule collection priority must be between 100 and 65000 inclusive."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in group.application_rule_collections : [
          contains(["Allow", "Deny"], collection.action)
        ]
      ]
    ]))
    error_message = "application rule collection action must be Allow or Deny (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in group.application_rule_collections : flatten([
          for rule in collection.rules : [
            for protocol in rule.protocols : contains(["Http", "Https", "Mssql"], protocol.type) && protocol.port >= 0 && protocol.port <= 64000
          ]
        ])
      ]
    ]))
    error_message = "application rule protocol type must be one of Http, Https or Mssql (case-sensitive) with the port between 0 and 64000."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in group.application_rule_collections : flatten([
          for rule in collection.rules : [
            length(rule.destination_urls) == 0 || rule.terminate_tls == true,
            length(rule.destination_urls) == 0 || length(rule.destination_fqdns) == 0
          ]
        ])
      ]
    ]))
    error_message = "application rules with destination_urls must set terminate_tls (URL inspection reads only encrypted traffic that terminates TLS at the firewall — a Premium-scope feature, noting the API does not verify the SKU at plan time) and cannot combine destination_urls with destination_fqdns."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in group.network_rule_collections : [
          contains(["Allow", "Deny"], collection.action)
        ]
      ]
    ]))
    error_message = "network rule collection action must be Allow or Deny (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in group.network_rule_collections : flatten([
          for rule in collection.rules : [
            length(rule.protocols) > 0 && alltrue([for protocol in rule.protocols : contains(["Any", "TCP", "UDP", "ICMP"], protocol)])
          ]
        ])
      ]
    ]))
    error_message = "network rule protocols must be a non-empty list of Any, TCP, UDP or ICMP entries (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in group.nat_rule_collections : [
          collection.action == "Dnat"
        ]
      ]
    ]))
    error_message = "NAT rule collection action must be Dnat (case-sensitive) — destination NAT is the only collection action the group API accepts."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.firewall_policy_rule_collection_groups : [
        for collection in group.nat_rule_collections : flatten([
          for rule in collection.rules : [
            length(rule.protocols) > 0 && alltrue([for protocol in rule.protocols : contains(["TCP", "UDP"], protocol)]),
            length(rule.destination_ports) <= 1,
            (rule.translated_address != null) != (rule.translated_fqdn != null),
            rule.translated_port >= 0 && rule.translated_port <= 64000
          ]
        ])
      ]
    ]))
    error_message = "NAT rules: protocols must be a non-empty list of TCP and/or UDP entries (case-sensitive), destination_ports accepts at most one port or port range, exactly one of translated_address or translated_fqdn must be set, and translated_port must be between 0 and 64000."
  }
}

variable "firewalls" {
  description = "Map of Azure Firewalls keyed by an arbitrary identifier. VNet firewalls require ip_configurations referencing a subnet per configuration (name it AzureFirewallSubnet); hub firewalls reference a Virtual Hub instead. Policies bind via firewall_policy_key or an external firewall_policy_id. Public IPs per configuration come from public_ips by key or by full ARM resource ID."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku_name            = optional(string, "AZFW_VNet")
    sku_tier            = optional(string, "Standard")
    firewall_policy_key = optional(string)
    firewall_policy_id  = optional(string)
    threat_intel_mode   = optional(string, "Alert")
    dns_servers         = optional(list(string), [])
    dns_proxy_enabled   = optional(bool)
    private_ip_ranges   = optional(list(string))
    zones               = optional(list(string), [])
    tags                = optional(map(string), {})
    ip_configurations = optional(map(object({
      name                 = string
      subnet_id            = optional(string)
      public_ip_key        = optional(string)
      public_ip_address_id = optional(string)
    })), {})
    management_ip_configuration = optional(object({
      name                 = string
      subnet_id            = string
      public_ip_key        = optional(string)
      public_ip_address_id = optional(string)
    }))
    virtual_hub = optional(object({
      virtual_hub_id  = string
      public_ip_count = optional(number, 1)
    }))
  }))

  validation {
    condition = alltrue([
      for key in keys(var.firewalls) : !can(regex("\\.", key))
    ])
    error_message = "firewalls map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, f in var.firewalls : alltrue([
        for ipc_key in keys(f.ip_configurations) : !can(regex("\\.", ipc_key))
      ])
    ])
    error_message = "ip_configurations map keys must not contain \".\"."
  }

  validation {
    condition = alltrue(flatten([
      for key, f in var.firewalls : [
        for other_key, g in var.firewalls :
        key == other_key || lower(f.name) != lower(g.name) || lower(f.resource_group_name) != lower(g.resource_group_name)
      ]
    ]))
    error_message = "firewall names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : can(regex("^[0-9a-zA-Z]([0-9a-zA-Z._-]{0,}[0-9a-zA-Z_])?$", f.name))
    ])
    error_message = "firewall name must follow the provider's FirewallName pattern: starts with a letter or digit, then letters, digits, dots, underscores and hyphens within, ending in the underscore-preferring set — the format the Azure Firewall API accepts."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : f.sku_name != "AZFW_Hub" || f.firewall_policy_key != null || f.firewall_policy_id != null
    ])
    error_message = "hub firewalls (AZFW_Hub) require a firewall policy — attach one via firewall_policy_key or firewall_policy_id; the secure-hub deployment is managed through policies only."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : length(trimspace(f.name)) > 0 && length(trimspace(f.resource_group_name)) > 0 && length(trimspace(f.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : contains(["AZFW_VNet", "AZFW_Hub"], f.sku_name)
    ])
    error_message = "sku_name must be AZFW_VNet (virtual network firewall, requires ip_configurations) or AZFW_Hub (secure hub firewall, requires virtual_hub) — case-sensitive and immutable."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : contains(["Basic", "Standard", "Premium"], f.sku_tier)
    ])
    error_message = "sku_tier must be Basic, Standard or Premium (case-sensitive). Upgrading the tier is allowed in place for supported tiers; changing anything else about the SKU topology forces replacement."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : f.sku_name != "AZFW_Hub" || (f.virtual_hub != null && length(f.ip_configurations) == 0 && f.management_ip_configuration == null)
    ])
    error_message = "hub firewalls (AZFW_Hub) must set virtual_hub and omit ip_configurations and management_ip_configuration — a hub firewall draws its address space from the Virtual Hub."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : f.sku_name != "AZFW_VNet" || (f.virtual_hub == null && length(f.ip_configurations) > 0)
    ])
    error_message = "VNet firewalls (AZFW_VNet) must omit virtual_hub and set at least one ip_configuration — a firewall subnet is mandatory for the VNet deployment shape."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : f.sku_name != "AZFW_VNet" || length([for ipc in f.ip_configurations : true if ipc.subnet_id != null]) == 1
    ])
    error_message = "exactly one ip_configuration may reference the dedicated subnet — Azure Firewall takes a single (reusable) subnet: it is shared across configurations or reserved by one and must be named AzureFirewallSubnet."
  }

  validation {
    condition = alltrue(flatten([
      for f in var.firewalls : [
        for ipc in f.ip_configurations : can(regex("/subnets/AzureFirewallSubnet$", ipc.subnet_id))
        if ipc.subnet_id != null
      ]
    ]))
    error_message = "ip_configuration subnet_id must reference the dedicated firewall subnet (the ID must end in \"/subnets/AzureFirewallSubnet\") — the API validates the subnet name and accepts a /26 or larger."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : f.management_ip_configuration == null || can(regex("/subnets/AzureFirewallManagementSubnet$", f.management_ip_configuration.subnet_id))
    ])
    error_message = "management_ip_configuration.subnet_id must reference the dedicated management subnet (the ID must end in \"/subnets/AzureFirewallManagementSubnet\") for forced tunnelling — a /26 or larger in the same virtual network."
  }

  validation {
    condition = alltrue(flatten([
      for f in var.firewalls : [
        for ipc_key, ipc in f.ip_configurations : [
          (ipc.public_ip_key != null) != (ipc.public_ip_address_id != null),
          ipc.public_ip_key == null || contains(keys(var.public_ips), ipc.public_ip_key),
          ipc.public_ip_address_id == null || can(regex("^/", ipc.public_ip_address_id))
        ]
      ]
    ]))
    error_message = "each ip_configuration needs exactly one public IP — set public_ip_key (an existing public_ips map key for an in-module IP) or public_ip_address_id (a full ARM resource ID), never both."
  }

  validation {
    condition = alltrue(flatten([
      for f in var.firewalls : [
        f.management_ip_configuration == null ? true : (f.management_ip_configuration.public_ip_key != null) != (f.management_ip_configuration.public_ip_address_id != null),
        f.management_ip_configuration == null ? true : f.management_ip_configuration.public_ip_key == null || contains(keys(var.public_ips), f.management_ip_configuration.public_ip_key),
        f.management_ip_configuration == null ? true : f.management_ip_configuration.public_ip_address_id == null || can(regex("^/", f.management_ip_configuration.public_ip_address_id))
      ]
    ]))
    error_message = "management_ip_configuration requires exactly one public IP — set public_ip_key (an existing public_ips map key) or public_ip_address_id (a full ARM resource ID), never both."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : f.management_ip_configuration == null || !anytrue([
        for ipc in f.ip_configurations : ipc.name == f.management_ip_configuration.name
      ])
    ])
    error_message = "management_ip_configuration.name must differ from every ip_configuration name — the API rejects a firewall whose management and data IP configurations share a name."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : !(f.dns_proxy_enabled == true) || length(f.dns_servers) > 0
    ])
    error_message = "dns_proxy_enabled requires at least one dns_servers entry — the proxy needs explicit servers to resolve through; set dns_servers when enabling the DNS proxy."
  }

  validation {
    condition = alltrue(flatten([
      for f in var.firewalls : [
        for server in f.dns_servers : can(cidrnetmask(format("%s/32", server)))
      ]
    ]))
    error_message = "dns_servers entries must be bare IPv4 addresses (e.g. 10.0.0.10)."
  }

  validation {
    condition = alltrue(flatten([
      for f in var.firewalls : [
        for range_entry in f.private_ip_ranges != null ? f.private_ip_ranges : [] : range_entry == "IANAPrivateRanges" || can(cidrhost(range_entry, 0))
      ]
    ]))
    error_message = "private_ip_ranges entries must be CIDR ranges (e.g. 192.168.1.0/24) or the literal IANAPrivateRanges."
  }

  validation {
    condition = alltrue(flatten([
      for f in var.firewalls : [
        for zone in f.zones : contains(["1", "2", "3"], zone)
      ]
    ]))
    error_message = "zones entries must be \"1\", \"2\" or \"3\" — availability zone numbers."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : !(f.firewall_policy_key != null && f.firewall_policy_id != null)
    ])
    error_message = "a firewall takes at most one policy pass-through: set firewall_policy_key (an existing firewall_policies map key for an in-module policy) or firewall_policy_id (a full ARM resource ID), never both."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : f.firewall_policy_id == null || can(regex("^/", f.firewall_policy_id))
    ])
    error_message = "firewall_policy_id, when set, must be a full ARM resource ID (starts with \"/\") — the id output of an external firewall policy."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : f.firewall_policy_key == null || contains(keys(var.firewall_policies), f.firewall_policy_key)
    ])
    error_message = "firewall_policy_key must reference an existing firewall_policies map key — firewalls attach to azurerm_firewall_policy resources by key."
  }

  validation {
    condition = alltrue([
      for f in var.firewalls : length(f.tags) <= 50 && alltrue([for k, v in f.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
