locals {
  databases = merge([
    for server_key, server in var.mysql_servers : {
      for database_key, database in server.databases : "${server_key}.${database_key}" => merge(database, {
        server_name         = azurerm_mysql_flexible_server.server[server_key].name
        resource_group_name = server.resource_group_name
      })
    }
  ]...)

  firewall_rules = merge([
    for server_key, server in var.mysql_servers : {
      for rule_key, rule in server.firewall_rules : "${server_key}.${rule_key}" => merge(rule, {
        server_name         = azurerm_mysql_flexible_server.server[server_key].name
        resource_group_name = server.resource_group_name
      })
    }
  ]...)
}

resource "azurerm_mysql_flexible_server" "server" {
  for_each = var.mysql_servers

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku_name            = each.value.sku_name
  version             = each.value.version

  create_mode                       = each.value.create_mode
  source_server_id                  = each.value.source_server_id
  administrator_login               = each.value.administrator_login
  administrator_password            = each.value.administrator_password
  administrator_password_wo         = each.value.administrator_password_wo
  administrator_password_wo_version = each.value.administrator_password_wo_version
  point_in_time_restore_time_in_utc = each.value.point_in_time_restore_time_in_utc

  backup_retention_days        = each.value.backup_retention_days
  geo_redundant_backup_enabled = each.value.geo_redundant_backup_enabled
  zone                         = each.value.zone

  delegated_subnet_id   = each.value.delegated_subnet_id
  private_dns_zone_id   = each.value.private_dns_zone_id
  public_network_access = each.value.public_network_access

  dynamic "storage" {
    for_each = each.value.storage != null ? [each.value.storage] : []
    content {
      size_gb             = storage.value.size_gb
      iops                = storage.value.iops
      auto_grow_enabled   = storage.value.auto_grow_enabled
      io_scaling_enabled  = storage.value.io_scaling_enabled
      log_on_disk_enabled = storage.value.log_on_disk_enabled
    }
  }

  dynamic "high_availability" {
    for_each = each.value.high_availability != null ? [each.value.high_availability] : []
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  dynamic "maintenance_window" {
    for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  tags = each.value.tags
}

resource "azurerm_mysql_flexible_database" "database" {
  for_each = local.databases

  name                = each.value.name
  server_name         = each.value.server_name
  resource_group_name = each.value.resource_group_name
  charset             = each.value.charset
  collation           = each.value.collation
}

resource "azurerm_mysql_flexible_server_firewall_rule" "rule" {
  for_each = local.firewall_rules

  name                = each.value.name
  server_name         = each.value.server_name
  resource_group_name = each.value.resource_group_name
  start_ip_address    = each.value.start_ip_address
  end_ip_address      = each.value.end_ip_address
}
