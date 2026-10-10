locals {
  gateways = { for gateway_key, gateway in var.application_gateways : gateway_key => {
    name                = gateway.name
    resource_group_name = gateway.resource_group_name
    location            = gateway.location

    sku_name                = gateway.sku_name
    capacity                = gateway.capacity
    autoscale_configuration = gateway.autoscale_configuration

    zones         = gateway.zones
    http2_enabled = gateway.http2_enabled
    fips_enabled  = gateway.fips_enabled

    firewall_policy_id                = gateway.firewall_policy_id
    force_firewall_policy_association = gateway.force_firewall_policy_association

    identity = gateway.identity

    gateway_ip_configurations  = gateway.gateway_ip_configurations
    frontend_ip_configurations = gateway.frontend_ip_configurations
    frontend_ports             = gateway.frontend_ports
    ssl_certificates           = gateway.ssl_certificates
    trusted_root_certificates  = gateway.trusted_root_certificates
    probes                     = gateway.probes
    backend_address_pools      = gateway.backend_address_pools

    backend_http_settings = { for setting_key, setting in gateway.backend_http_settings : setting_key => merge(setting, {
      probe_name = setting.probe_key == null ? null : gateway.probes[setting.probe_key].name
      trusted_root_certificate_names = [
        for trusted_key in setting.trusted_root_certificate_keys : gateway.trusted_root_certificates[trusted_key].name
      ]
    }) }

    http_listeners = { for listener_key, listener in gateway.http_listeners : listener_key => merge(listener, {
      frontend_ip_configuration_name = gateway.frontend_ip_configurations[listener.frontend_ip_configuration_key].name
      frontend_port_name             = gateway.frontend_ports[listener.frontend_port_key].name
      ssl_certificate_name           = listener.ssl_certificate_key == null ? null : gateway.ssl_certificates[listener.ssl_certificate_key].name
    }) }

    request_routing_rules = { for rule_key, rule in gateway.request_routing_rules : rule_key => merge(rule, {
      http_listener_name         = gateway.http_listeners[rule.http_listener_key].name
      backend_address_pool_name  = rule.backend_address_pool_key == null ? null : gateway.backend_address_pools[rule.backend_address_pool_key].name
      backend_http_settings_name = rule.backend_http_settings_key == null ? null : gateway.backend_http_settings[rule.backend_http_settings_key].name
      url_path_map_name          = rule.url_path_map_key == null ? null : gateway.url_path_maps[rule.url_path_map_key].name
    }) }

    url_path_maps = { for map_key, url_map in gateway.url_path_maps : map_key => {
      name                               = url_map.name
      default_backend_address_pool_name  = gateway.backend_address_pools[url_map.default_backend_address_pool_key].name
      default_backend_http_settings_name = gateway.backend_http_settings[url_map.default_backend_http_settings_key].name
      path_rules = {
        for rule_key, rule in url_map.path_rules : rule_key => {
          name                       = rule.name
          paths                      = rule.paths
          backend_address_pool_name  = rule.backend_address_pool_key == null ? null : gateway.backend_address_pools[rule.backend_address_pool_key].name
          backend_http_settings_name = rule.backend_http_settings_key == null ? null : gateway.backend_http_settings[rule.backend_http_settings_key].name
        }
      }
    } }

    ssl_policy = gateway.ssl_policy
    tags       = gateway.tags
  } }
}

# name/tier must be emitted explicitly — the provider's sku block requires
# both; tier carries the same value as sku_name for the v2-only set
resource "azurerm_application_gateway" "gateway" {
  for_each = local.gateways

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  sku {
    name     = each.value.sku_name
    tier     = each.value.sku_name
    capacity = each.value.capacity
  }

  dynamic "autoscale_configuration" {
    for_each = each.value.autoscale_configuration != null ? [each.value.autoscale_configuration] : []
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  zones         = each.value.zones
  http2_enabled = each.value.http2_enabled
  fips_enabled  = each.value.fips_enabled

  firewall_policy_id                = each.value.firewall_policy_id
  force_firewall_policy_association = each.value.force_firewall_policy_association

  dynamic "gateway_ip_configuration" {
    for_each = each.value.gateway_ip_configurations
    content {
      name      = gateway_ip_configuration.value.name
      subnet_id = gateway_ip_configuration.value.subnet_id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configurations
    content {
      name                          = frontend_ip_configuration.value.name
      subnet_id                     = frontend_ip_configuration.value.subnet_id
      private_ip_address            = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
      public_ip_address_id          = frontend_ip_configuration.value.public_ip_address_id
    }
  }

  dynamic "frontend_port" {
    for_each = each.value.frontend_ports
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  dynamic "ssl_certificate" {
    for_each = each.value.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = each.value.trusted_root_certificates
    content {
      name                = trusted_root_certificate.value.name
      data                = trusted_root_certificate.value.data
      key_vault_secret_id = trusted_root_certificate.value.key_vault_secret_id
    }
  }

  dynamic "probe" {
    for_each = each.value.probes
    content {
      name                = probe.value.name
      protocol            = probe.value.protocol
      interval            = probe.value.interval
      timeout             = probe.value.timeout
      unhealthy_threshold = probe.value.unhealthy_threshold

      host                                      = probe.value.host
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      path                                      = probe.value.path
      port                                      = probe.value.port
      minimum_servers                           = probe.value.minimum_servers

      dynamic "match" {
        for_each = probe.value.match != null ? [probe.value.match] : []
        content {
          status_code = match.value.status_code
          body        = match.value.body
        }
      }
    }
  }

  dynamic "backend_address_pool" {
    for_each = each.value.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = each.value.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      request_timeout                     = backend_http_settings.value.request_timeout
      path                                = backend_http_settings.value.path
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      probe_name                          = backend_http_settings.value.probe_name
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining != null ? [backend_http_settings.value.connection_draining] : []
        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  dynamic "http_listener" {
    for_each = each.value.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      firewall_policy_id             = http_listener.value.firewall_policy_id
    }
  }

  dynamic "request_routing_rule" {
    for_each = each.value.request_routing_rules
    content {
      name                       = request_routing_rule.value.name
      priority                   = request_routing_rule.value.priority
      rule_type                  = request_routing_rule.value.rule_type
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      url_path_map_name          = request_routing_rule.value.url_path_map_name
    }
  }

  dynamic "url_path_map" {
    for_each = each.value.url_path_maps
    content {
      name                               = url_path_map.value.name
      default_backend_address_pool_name  = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name = url_path_map.value.default_backend_http_settings_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                       = path_rule.value.name
          paths                      = path_rule.value.paths
          backend_address_pool_name  = path_rule.value.backend_address_pool_name
          backend_http_settings_name = path_rule.value.backend_http_settings_name
        }
      }
    }
  }

  dynamic "ssl_policy" {
    for_each = each.value.ssl_policy != null ? [each.value.ssl_policy] : []
    content {
      disabled_protocols   = ssl_policy.value.disabled_protocols
      policy_type          = ssl_policy.value.policy_type
      policy_name          = ssl_policy.value.policy_name
      cipher_suites        = ssl_policy.value.cipher_suites
      min_protocol_version = ssl_policy.value.min_protocol_version
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = each.value.tags
}
