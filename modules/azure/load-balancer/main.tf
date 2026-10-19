locals {
  public_ip_ids = { for key, pip in azurerm_public_ip.pip : key => pip.id }

  backend_address_pools = merge([
    for lb_key, lb in var.load_balancers : {
      for pool_key, pool in lb.backend_address_pools : "${lb_key}.${pool_key}" => merge(pool, {
        loadbalancer_id = azurerm_lb.lb[lb_key].id
      })
    }
  ]...)

  pool_addresses = merge([
    for lb_key, lb in var.load_balancers : merge([
      for pool_key, pool in lb.backend_address_pools : {
        for addr_key, addr in pool.addresses : "${lb_key}.${pool_key}.${addr_key}" => merge(addr, {
          backend_address_pool_id = azurerm_lb_backend_address_pool.pool["${lb_key}.${pool_key}"].id
        })
      }
    ]...)
  ]...)

  nic_associations = merge([
    for lb_key, lb in var.load_balancers : merge([
      for pool_key, pool in lb.backend_address_pools : {
        for assoc_key, assoc in pool.nic_associations : "${lb_key}.${pool_key}.${assoc_key}" => merge(assoc, {
          backend_address_pool_id = azurerm_lb_backend_address_pool.pool["${lb_key}.${pool_key}"].id
        })
      }
    ]...)
  ]...)

  probes = merge([
    for lb_key, lb in var.load_balancers : {
      for probe_key, probe in lb.probes : "${lb_key}.${probe_key}" => merge(probe, {
        loadbalancer_id = azurerm_lb.lb[lb_key].id
      })
    }
  ]...)

  rules = merge([
    for lb_key, lb in var.load_balancers : {
      for rule_key, rule in lb.rules : "${lb_key}.${rule_key}" => {
        name                           = rule.name
        loadbalancer_id                = azurerm_lb.lb[lb_key].id
        frontend_ip_configuration_name = lb.frontend_ip_configurations[rule.frontend_ip_configuration_key].name
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.pool["${lb_key}.${rule.backend_address_pool_key}"].id]
        probe_id                       = rule.probe_key != null ? azurerm_lb_probe.probe["${lb_key}.${rule.probe_key}"].id : null
        protocol                       = rule.protocol
        frontend_port                  = rule.frontend_port
        backend_port                   = rule.backend_port
        load_distribution              = rule.load_distribution
        floating_ip_enabled            = rule.floating_ip_enabled
        disable_outbound_snat          = rule.disable_outbound_snat
        tcp_reset_enabled              = rule.tcp_reset_enabled
        idle_timeout_in_minutes        = rule.idle_timeout_in_minutes
      }
    }
  ]...)

  nat_rules = merge([
    for lb_key, lb in var.load_balancers : {
      for rule_key, rule in lb.nat_rules : "${lb_key}.${rule_key}" => {
        name                           = rule.name
        resource_group_name            = lb.resource_group_name
        loadbalancer_id                = azurerm_lb.lb[lb_key].id
        frontend_ip_configuration_name = lb.frontend_ip_configurations[rule.frontend_ip_configuration_key].name
        protocol                       = rule.protocol
        frontend_port                  = rule.frontend_port
        backend_port                   = rule.backend_port
        frontend_port_start            = rule.frontend_port_start
        frontend_port_end              = rule.frontend_port_end
        backend_address_pool_id        = rule.backend_address_pool_key != null ? azurerm_lb_backend_address_pool.pool["${lb_key}.${rule.backend_address_pool_key}"].id : null
        floating_ip_enabled            = rule.floating_ip_enabled
        tcp_reset_enabled              = rule.tcp_reset_enabled
        idle_timeout_in_minutes        = rule.idle_timeout_in_minutes
      }
    }
  ]...)

  nat_pools = merge([
    for lb_key, lb in var.load_balancers : {
      for pool_key, pool in lb.nat_pools : "${lb_key}.${pool_key}" => {
        name                           = pool.name
        resource_group_name            = lb.resource_group_name
        loadbalancer_id                = azurerm_lb.lb[lb_key].id
        frontend_ip_configuration_name = lb.frontend_ip_configurations[pool.frontend_ip_configuration_key].name
        protocol                       = pool.protocol
        frontend_port_start            = pool.frontend_port_start
        frontend_port_end              = pool.frontend_port_end
        backend_port                   = pool.backend_port
        floating_ip_enabled            = pool.floating_ip_enabled
        tcp_reset_enabled              = pool.tcp_reset_enabled
        idle_timeout_in_minutes        = pool.idle_timeout_in_minutes
      }
    }
  ]...)

  outbound_rules = merge([
    for lb_key, lb in var.load_balancers : {
      for rule_key, rule in lb.outbound_rules : "${lb_key}.${rule_key}" => {
        name                       = rule.name
        loadbalancer_id            = azurerm_lb.lb[lb_key].id
        backend_address_pool_id    = azurerm_lb_backend_address_pool.pool["${lb_key}.${rule.backend_address_pool_key}"].id
        protocol                   = rule.protocol
        allocated_outbound_ports   = rule.allocated_outbound_ports
        idle_timeout_in_minutes    = rule.idle_timeout_in_minutes
        tcp_reset_enabled          = rule.tcp_reset_enabled
        frontend_ip_configurations = [for fe_key in rule.frontend_ip_configuration_keys : lb.frontend_ip_configurations[fe_key].name]
      }
    }
  ]...)
}

resource "azurerm_public_ip" "pip" {
  for_each = var.public_ips

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  allocation_method = "Static"
  sku               = "Standard"
  ip_version        = "IPv4"

  domain_name_label = each.value.domain_name_label

  zones = each.value.availability_zone != null ? [each.value.availability_zone] : null

  tags = each.value.tags
}

resource "azurerm_lb" "lb" {
  for_each = var.load_balancers

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  sku       = "Standard"
  sku_tier  = each.value.sku_tier
  edge_zone = each.value.edge_zone

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configurations

    content {
      name                 = frontend_ip_configuration.value.name
      public_ip_address_id = frontend_ip_configuration.value.public_ip_key != null ? local.public_ip_ids[frontend_ip_configuration.value.public_ip_key] : frontend_ip_configuration.value.public_ip_address_id
      public_ip_prefix_id  = frontend_ip_configuration.value.public_ip_prefix_id
      subnet_id            = frontend_ip_configuration.value.subnet_id
      private_ip_address   = frontend_ip_configuration.value.private_ip_address

      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
      private_ip_address_version    = frontend_ip_configuration.value.private_ip_address_version
      zones                         = frontend_ip_configuration.value.zones
    }
  }

  tags = each.value.tags
}

resource "azurerm_lb_backend_address_pool" "pool" {
  for_each = local.backend_address_pools

  name            = each.value.name
  loadbalancer_id = each.value.loadbalancer_id

  virtual_network_id = each.value.virtual_network_id
  synchronous_mode   = each.value.synchronous_mode
}

resource "azurerm_lb_backend_address_pool_address" "address" {
  for_each = local.pool_addresses

  name                    = each.value.name
  backend_address_pool_id = each.value.backend_address_pool_id

  ip_address                          = each.value.ip_address
  virtual_network_id                  = each.value.virtual_network_id
  backend_address_ip_configuration_id = each.value.backend_address_ip_configuration_id
}

resource "azurerm_network_interface_backend_address_pool_association" "nic" {
  for_each = local.nic_associations

  network_interface_id    = each.value.network_interface_id
  ip_configuration_name   = each.value.ip_configuration_name
  backend_address_pool_id = each.value.backend_address_pool_id
}

resource "azurerm_lb_probe" "probe" {
  for_each = local.probes

  name            = each.value.name
  loadbalancer_id = each.value.loadbalancer_id

  protocol                     = each.value.protocol
  port                         = each.value.port
  request_path                 = each.value.request_path
  interval_in_seconds          = each.value.interval_in_seconds
  number_of_probes             = each.value.number_of_probes
  probe_threshold              = each.value.probe_threshold
  no_healthy_backends_behavior = each.value.no_healthy_backends_behavior
}

resource "azurerm_lb_rule" "rule" {
  for_each = local.rules

  name                           = each.value.name
  loadbalancer_id                = each.value.loadbalancer_id
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name

  backend_address_pool_ids = each.value.backend_address_pool_ids
  probe_id                 = each.value.probe_id

  protocol                = each.value.protocol
  frontend_port           = each.value.frontend_port
  backend_port            = each.value.backend_port
  load_distribution       = each.value.load_distribution
  floating_ip_enabled     = each.value.floating_ip_enabled
  disable_outbound_snat   = each.value.disable_outbound_snat
  tcp_reset_enabled       = each.value.tcp_reset_enabled
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
}

resource "azurerm_lb_nat_rule" "nat_rule" {
  for_each = local.nat_rules

  name                           = each.value.name
  resource_group_name            = each.value.resource_group_name
  loadbalancer_id                = each.value.loadbalancer_id
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name

  protocol                = each.value.protocol
  frontend_port           = each.value.frontend_port
  backend_port            = each.value.backend_port
  frontend_port_start     = each.value.frontend_port_start
  frontend_port_end       = each.value.frontend_port_end
  backend_address_pool_id = each.value.backend_address_pool_id

  floating_ip_enabled     = each.value.floating_ip_enabled
  tcp_reset_enabled       = each.value.tcp_reset_enabled
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
}

resource "azurerm_lb_nat_pool" "nat_pool" {
  for_each = local.nat_pools

  name                           = each.value.name
  resource_group_name            = each.value.resource_group_name
  loadbalancer_id                = each.value.loadbalancer_id
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name

  protocol            = each.value.protocol
  frontend_port_start = each.value.frontend_port_start
  frontend_port_end   = each.value.frontend_port_end
  backend_port        = each.value.backend_port

  floating_ip_enabled     = each.value.floating_ip_enabled
  tcp_reset_enabled       = each.value.tcp_reset_enabled
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
}

resource "azurerm_lb_outbound_rule" "outbound_rule" {
  for_each = local.outbound_rules

  name            = each.value.name
  loadbalancer_id = each.value.loadbalancer_id

  backend_address_pool_id = each.value.backend_address_pool_id

  protocol                 = each.value.protocol
  allocated_outbound_ports = each.value.allocated_outbound_ports
  idle_timeout_in_minutes  = each.value.idle_timeout_in_minutes
  tcp_reset_enabled        = each.value.tcp_reset_enabled

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configurations

    content {
      name = frontend_ip_configuration.value
    }
  }
}
