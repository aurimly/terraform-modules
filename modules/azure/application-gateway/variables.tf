variable "application_gateways" {
  description = "Map of Application Gateways (v2 SKUs) keyed by an arbitrary identifier. Each entry creates one azurerm_application_gateway in the named resource group; nested IP configurations, frontends, listeners, routings and backends wire into the gateway resource this module creates itself. v1 SKUs are pinned out — they are deprecated upstream."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    sku_name = optional(string, "Standard_v2")
    capacity = optional(number)
    autoscale_configuration = optional(object({
      min_capacity = number
      max_capacity = optional(number)
    }))

    zones         = optional(list(string), [])
    http2_enabled = optional(bool)
    fips_enabled  = optional(bool)

    firewall_policy_id                = optional(string)
    force_firewall_policy_association = optional(bool)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    gateway_ip_configurations = map(object({
      name      = string
      subnet_id = string
    }))

    frontend_ip_configurations = map(object({
      name                          = string
      subnet_id                     = optional(string)
      private_ip_address            = optional(string)
      private_ip_address_allocation = optional(string, "Dynamic")
      public_ip_address_id          = optional(string)
    }))

    frontend_ports = map(object({
      name = string
      port = number
    }))

    ssl_certificates = optional(map(object({
      name                = string
      data                = optional(string)
      password            = optional(string)
      key_vault_secret_id = optional(string)
    })), {})

    trusted_root_certificates = optional(map(object({
      name                = string
      data                = optional(string)
      key_vault_secret_id = optional(string)
    })), {})

    probes = optional(map(object({
      name                                      = string
      protocol                                  = string
      interval                                  = number
      timeout                                   = number
      unhealthy_threshold                       = number
      host                                      = optional(string)
      pick_host_name_from_backend_http_settings = optional(bool)
      path                                      = optional(string)
      port                                      = optional(number)
      minimum_servers                           = optional(number)
      match = optional(object({
        status_code = list(string)
        body        = optional(string)
      }))
    })), {})

    backend_address_pools = map(object({
      name         = string
      fqdns        = optional(list(string), [])
      ip_addresses = optional(list(string), [])
    }))

    backend_http_settings = map(object({
      name                                = string
      port                                = number
      protocol                            = string
      cookie_based_affinity               = optional(string, "Disabled")
      request_timeout                     = optional(number)
      path                                = optional(string)
      host_name                           = optional(string)
      pick_host_name_from_backend_address = optional(bool)
      affinity_cookie_name                = optional(string)
      probe_key                           = optional(string)
      trusted_root_certificate_keys       = optional(list(string), [])
      connection_draining = optional(object({
        enabled           = bool
        drain_timeout_sec = number
      }))
    }))

    http_listeners = map(object({
      name                          = string
      frontend_ip_configuration_key = string
      frontend_port_key             = string
      protocol                      = string
      host_name                     = optional(string)
      host_names                    = optional(list(string))
      require_sni                   = optional(bool)
      ssl_certificate_key           = optional(string)
      firewall_policy_id            = optional(string)
    }))

    request_routing_rules = map(object({
      name                      = string
      priority                  = number
      rule_type                 = string
      http_listener_key         = string
      backend_address_pool_key  = optional(string)
      backend_http_settings_key = optional(string)
      url_path_map_key          = optional(string)
    }))

    url_path_maps = optional(map(object({
      name                              = string
      default_backend_address_pool_key  = string
      default_backend_http_settings_key = string
      path_rules = map(object({
        name                      = string
        paths                     = list(string)
        backend_address_pool_key  = optional(string)
        backend_http_settings_key = optional(string)
      }))
    })), {})

    ssl_policy = optional(object({
      disabled_protocols   = optional(list(string))
      policy_type          = optional(string)
      policy_name          = optional(string)
      cipher_suites        = optional(list(string))
      min_protocol_version = optional(string)
    }))

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for gateway in var.application_gateways : contains(["Standard_v2", "WAF_v2"], gateway.sku_name)
    ])
    error_message = "sku_name must be Standard_v2 or WAF_v2 — the v1 SKUs (Basic, Standard_*, WAF_*) are deprecated upstream (V1 retirement) and new deployments go v2."
  }

  validation {
    condition = alltrue([
      for gateway in var.application_gateways :
      gateway.capacity != null ? (gateway.autoscale_configuration == null && gateway.capacity >= 1 && gateway.capacity <= 125) : gateway.autoscale_configuration != null
    ])
    error_message = "exactly one of capacity (1–125 instances) or autoscale_configuration — the static way or the scaled way, not both, and never neither."
  }

  validation {
    condition = alltrue([
      for gateway in var.application_gateways :
      gateway.autoscale_configuration == null || (
        gateway.autoscale_configuration.min_capacity >= 0 && gateway.autoscale_configuration.min_capacity <= 100
        && (gateway.autoscale_configuration.max_capacity == null || (gateway.autoscale_configuration.max_capacity >= 2 && gateway.autoscale_configuration.max_capacity <= 125))
        && (gateway.autoscale_configuration.max_capacity == null || gateway.autoscale_configuration.max_capacity > gateway.autoscale_configuration.min_capacity)
      )
    ])
    error_message = "autoscale_configuration: min_capacity 0–100, max_capacity 2–125 (optional) and max greater than min."
  }

  validation {
    condition = alltrue([
      for gateway in var.application_gateways : alltrue([for zone in gateway.zones : contains(["1", "2", "3"], zone)])
    ])
    error_message = "zones entries must be \"1\", \"2\" or \"3\" — zone support is v2-only and region-dependent; changing zones forces replacement."
  }

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways : length(gateway.gateway_ip_configurations) >= 1
    ])
    error_message = "gateway_ip_configurations needs at least one entry — the subnet the gateway attaches itself to (dedicated subnet recommended, see Notes)."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for frontend in gateway.frontend_ip_configurations :
        (frontend.public_ip_address_id != null) != (frontend.subnet_id != null)
        && ((frontend.private_ip_address_allocation == "Static" ? frontend.private_ip_address != null : true))
      ]
    ]))
    error_message = "frontend_ip_configurations need exactly one of public_ip_address_id (public frontend, ARM ID of a Standard/Static public IP) or subnet_id (private frontend); static allocation additionally requires private_ip_address."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for frontend_key, frontend in gateway.frontend_ip_configurations :
        frontend.public_ip_address_id == null || can(regex("^/", frontend.public_ip_address_id))
      ]
    ]))
    error_message = "frontend_ip_configurations.public_ip_address_id must be a full ARM public-IP resource ID (starting with \"/\") — a Standard, static public IP produced by the azure/public-ip module typically."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for cert in gateway.ssl_certificates :
        (cert.data != null) != (cert.key_vault_secret_id != null)
        && (cert.data == null || cert.password != null)
      ]
    ]))
    error_message = "ssl_certificates need exactly one of data (base64 PFX) or key_vault_secret_id, and data requires the PFX password."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for cert in gateway.trusted_root_certificates :
        (cert.data != null) != (cert.key_vault_secret_id != null)
      ]
    ]))
    error_message = "trusted_root_certificates need exactly one of data or key_vault_secret_id."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for cert_key, cert in gateway.ssl_certificates :
        cert.key_vault_secret_id == null || gateway.identity != null
      ]
    ]))
    error_message = "Key Vault ssl_certificates require an identity block — the gateway unlocks TLS termination secrets through a user-assigned identity with Key Vault get access (see Notes)."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for listener in gateway.http_listeners :
        (listener.protocol != "Https" || listener.ssl_certificate_key != null)
        && (listener.host_name == null || listener.host_names == null)
        && (listener.protocol != "Https" || can(gateway.ssl_certificates[listener.ssl_certificate_key].name))
      ]
    ]))
    error_message = "http_listeners: protocol Https requires ssl_certificate_key resolving to an existing ssl_certificates key of the same entry, and host_name conflicts with host_names — set one, not both."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for probe in gateway.probes : [
          contains(["Http", "Https"], probe.protocol),
          probe.interval >= 1 && probe.interval <= 86400,
          probe.timeout >= 1 && probe.timeout <= 86400,
          probe.timeout <= probe.interval,
          probe.unhealthy_threshold >= 1 && probe.unhealthy_threshold <= 20,
          (probe.host != null) != (probe.pick_host_name_from_backend_http_settings == true),
          probe.path != null && can(regex("^/", probe.path)),
          (probe.port == null || (probe.port >= 1 && probe.port <= 65535))
        ]
      ]
    ]))
    error_message = "probes: protocol Http or Https only (Tcp/Tls probes belong with L4 listeners, out of this module), interval/timeout in 1–86400 with timeout ≤ interval, unhealthy_threshold 1–20, exactly one of host or pick_host_name_from_backend_http_settings, a path starting with \"/\", an optional probe port 1–65535."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for pool in gateway.backend_address_pools :
        length(pool.fqdns) >= 1 || length(pool.ip_addresses) >= 1
      ]
    ]))
    error_message = "backend_address_pools need at least one fqdns or ip_addresses entry — an empty pool targets nothing."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for setting in gateway.backend_http_settings : [
          contains(["Http", "Https"], setting.protocol),
          (setting.port >= 1 && setting.port <= 65535),
          contains(["Enabled", "Disabled"], setting.cookie_based_affinity),
          (setting.request_timeout == null || (setting.request_timeout >= 1 && setting.request_timeout <= 86400)),
          (setting.host_name == null || setting.pick_host_name_from_backend_address != true),
          (setting.connection_draining == null || (setting.connection_draining.drain_timeout_sec >= 1 && setting.connection_draining.drain_timeout_sec <= 3600))
        ]
      ]
    ]))
    error_message = "backend_http_settings: protocol Http/Https, port 1–65535, cookie_based_affinity Enabled/Disabled, request_timeout 1–86400, host_name conflicts with pick_host_name_from_backend_address, connection_draining.drain_timeout_sec 1–3600."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for setting_key, setting in gateway.backend_http_settings : [
          setting.probe_key == null || can(gateway.probes[setting.probe_key].name),
          alltrue([for trusted_key in setting.trusted_root_certificate_keys : can(gateway.trusted_root_certificates[trusted_key].name)])
        ]
      ]
    ]))
    error_message = "backend_http_settings probe_key and trusted_root_certificate_keys must resolve to probes and trusted_root_certificates keys of the same gateway entry."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for listener_key, listener in gateway.http_listeners : [
          can(gateway.frontend_ip_configurations[listener.frontend_ip_configuration_key].name),
          can(gateway.frontend_ports[listener.frontend_port_key].name)
        ]
      ]
    ]))
    error_message = "http_listeners frontend_ip_configuration_key and frontend_port_key must resolve to existing sibling keys of the same gateway entry."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        for rule in gateway.request_routing_rules : [
          can(gateway.http_listeners[rule.http_listener_key].name),
          rule.priority >= 1 && rule.priority <= 20000,
          (rule.rule_type != "Basic" || (rule.backend_address_pool_key != null && rule.backend_http_settings_key != null && rule.url_path_map_key == null)),
          (rule.rule_type != "PathBasedRouting" || (rule.url_path_map_key != null && rule.backend_address_pool_key == null && rule.backend_http_settings_key == null)),
          (rule.backend_address_pool_key == null || can(gateway.backend_address_pools[rule.backend_address_pool_key].name)),
          (rule.backend_http_settings_key == null || can(gateway.backend_http_settings[rule.backend_http_settings_key].name))
        ]
      ]
    ]))
    error_message = "request_routing_rules: priority 1–20000 (validated, unique per gateway), http_listener_key must resolve, Basic routes carry the backend pool+settings pair, PathBasedRouting carries url_path_map_key — redirect targets are out of this module."
  }

  validation {
    condition = alltrue(flatten([
      for gateway_key, gateway in var.application_gateways : [
        length(distinct([for rule in gateway.request_routing_rules : rule.priority])) == length(gateway.request_routing_rules)
      ]
    ]))
    error_message = "request_routing_rules priorities must be unique per gateway — the Azure API evaluates them by distinct priority."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : flatten([
        for map_key, url_map in gateway.url_path_maps : concat([
          can(gateway.backend_address_pools[url_map.default_backend_address_pool_key].name),
          can(gateway.backend_http_settings[url_map.default_backend_http_settings_key].name)
          ], flatten([
            for rule in url_map.path_rules : [
              length(rule.paths) >= 1,
              (rule.backend_address_pool_key != null) == (rule.backend_http_settings_key != null),
              (rule.backend_address_pool_key == null || can(gateway.backend_address_pools[rule.backend_address_pool_key].name)),
              (rule.backend_http_settings_key == null || can(gateway.backend_http_settings[rule.backend_http_settings_key].name))
            ]
        ]))
      ])
    ]))
    error_message = "url_path_maps: default targets resolve to existing pool+settings keys, path rules carry at least one path and either both or neither of pool/settings keys that also resolve."
  }

  validation {
    condition = alltrue([
      for gateway in var.application_gateways :
      gateway.ssl_policy == null || (
        !(gateway.ssl_policy.disabled_protocols != null && (gateway.ssl_policy.policy_name != null || gateway.ssl_policy.policy_type != null))
        && (gateway.ssl_policy.policy_name == null || gateway.ssl_policy.policy_type != null)
        && (gateway.ssl_policy.policy_type == null || contains(["Predefined", "Custom", "CustomV2"], gateway.ssl_policy.policy_type))
      )
    ])
    error_message = "ssl_policy: disabled_protocols conflicts with policy_name/policy_type at the API, policy_name requires policy_type (Predefined/Custom/CustomV2) — Custom and CustomV2 take cipher_suites and min_protocol_version instead."
  }

  validation {
    condition = alltrue([
      for gateway in var.application_gateways :
      gateway.identity == null || !contains(["UserAssigned", "SystemAssigned, UserAssigned"], gateway.identity.type) || alltrue([for id in coalesce(gateway.identity.identity_ids, []) : can(regex("^/", id))])
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — full ARM resource IDs of user-assigned managed identities (Key Vault TLS termination needs a user-assigned one)."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : [
        length(gateway.tags) <= 50 && alltrue([for tag_key, tag_value in gateway.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
      ]
    ]))
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }

  validation {
    condition = alltrue(concat(
      [for gateway_key in keys(var.application_gateways) : !can(regex("\\.", gateway_key))],
      flatten([
        for gateway in var.application_gateways : [
          for child_key in concat(
            keys(gateway.gateway_ip_configurations),
            keys(gateway.frontend_ip_configurations),
            keys(gateway.frontend_ports),
            keys(gateway.ssl_certificates),
            keys(gateway.trusted_root_certificates),
            keys(gateway.probes),
            keys(gateway.backend_address_pools),
            keys(gateway.backend_http_settings),
            keys(gateway.http_listeners),
            keys(gateway.request_routing_rules),
            keys(gateway.url_path_maps)
          ) : !can(regex("\\.", child_key))
        ]
      ])
    ))
    error_message = "map keys of application_gateways and its nested block-family maps must not contain \".\" — gateway keys are composed into output identifiers of the form \"<gateway_key>:<family>:<name>\" (block families are wired by name at the Azure API); dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.application_gateways : concat(flatten([
        for family_name, blocks in {
          gateway_ip_configurations  = gateway.gateway_ip_configurations,
          frontend_ip_configurations = gateway.frontend_ip_configurations,
          frontend_ports             = gateway.frontend_ports,
          ssl_certificates           = gateway.ssl_certificates,
          trusted_root_certificates  = gateway.trusted_root_certificates,
          probes                     = gateway.probes,
          backend_address_pools      = gateway.backend_address_pools,
          backend_http_settings      = gateway.backend_http_settings,
          http_listeners             = gateway.http_listeners,
          request_routing_rules      = gateway.request_routing_rules,
          url_path_maps              = gateway.url_path_maps
          } : [
          length(distinct([for child in blocks : child.name])) == length(blocks)
        ]
      ]), [[for rule in gateway.request_routing_rules : true]])
    ]))
    error_message = "within one gateway entry every block family carries unique names — the Azure API references blocks by name (ssl_certificate_name, probe_name, backend_address_pool_name), so duplicates collide."
  }
}
