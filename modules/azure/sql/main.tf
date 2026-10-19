locals {
  elastic_pools = merge([
    for server_key, server in var.sql_servers : {
      for pool_key, pool in server.elastic_pools : "${server_key}.${pool_key}" => merge(pool, {
        server_name         = azurerm_mssql_server.server[server_key].name
        resource_group_name = server.resource_group_name
        location            = server.location
      })
    }
  ]...)

  databases = merge([
    for server_key, server in var.sql_servers : {
      for db_key, db in server.databases : "${server_key}.${db_key}" => merge(db, {
        server_id       = azurerm_mssql_server.server[server_key].id
        elastic_pool_id = db.elastic_pool_key == null ? null : azurerm_mssql_elasticpool.pool["${server_key}.${db.elastic_pool_key}"].id
      })
    }
  ]...)

  firewall_rules = merge([
    for server_key, server in var.sql_servers : {
      for rule_key, rule in server.firewall_rules : "${server_key}.${rule_key}" => merge(rule, {
        server_id = azurerm_mssql_server.server[server_key].id
      })
    }
  ]...)

  failover_groups = merge([
    for server_key, server in var.sql_servers : {
      for group_key, group in server.failover_groups : "${server_key}.${group_key}" => merge(group, {
        server_id = azurerm_mssql_server.server[server_key].id
        databases = [for db_key in group.database_keys : azurerm_mssql_database.database["${server_key}.${db_key}"].id]
      })
    }
  ]...)
}

resource "azurerm_mssql_server" "server" {
  for_each = var.sql_servers

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  version             = each.value.version

  administrator_login                     = each.value.administrator_login
  administrator_login_password            = each.value.administrator_login_password
  administrator_login_password_wo         = each.value.administrator_login_password_wo
  administrator_login_password_wo_version = each.value.administrator_login_password_wo_version

  minimum_tls_version                      = each.value.minimum_tls_version
  connection_policy                        = each.value.connection_policy
  public_network_access_enabled            = each.value.public_network_access_enabled
  outbound_network_restriction_enabled     = each.value.outbound_network_restriction_enabled
  express_vulnerability_assessment_enabled = each.value.express_vulnerability_assessment_enabled

  primary_user_assigned_identity_id            = each.value.primary_user_assigned_identity_id
  transparent_data_encryption_key_vault_key_id = each.value.transparent_data_encryption_key_vault_key_id

  dynamic "azuread_administrator" {
    for_each = each.value.azuread_administrator != null ? [each.value.azuread_administrator] : []

    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      tenant_id                   = azuread_administrator.value.tenant_id
      azuread_authentication_only = azuread_administrator.value.azuread_authentication_only
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

resource "azurerm_mssql_elasticpool" "pool" {
  for_each = local.elastic_pools

  name                = each.value.name
  server_name         = each.value.server_name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  max_size_gb    = each.value.max_size_gb
  max_size_bytes = each.value.max_size_bytes

  license_type                    = each.value.license_type
  zone_redundant                  = each.value.zone_redundant
  high_availability_replica_count = each.value.high_availability_replica_count
  maintenance_configuration_name  = each.value.maintenance_configuration_name
  enclave_type                    = each.value.enclave_type

  sku {
    name     = each.value.sku.name
    tier     = each.value.sku.tier
    capacity = each.value.sku.capacity
    family   = each.value.sku.family
  }

  per_database_settings {
    min_capacity = each.value.per_database_settings.min_capacity
    max_capacity = each.value.per_database_settings.max_capacity
  }

  tags = each.value.tags
}

resource "azurerm_mssql_database" "database" {
  for_each = local.databases

  name      = each.value.name
  server_id = each.value.server_id

  collation    = each.value.collation
  sku_name     = each.value.sku_name
  license_type = each.value.license_type
  max_size_gb  = each.value.max_size_gb

  create_mode                           = each.value.create_mode
  creation_source_database_id           = each.value.creation_source_database_id
  restore_point_in_time                 = each.value.restore_point_in_time
  recover_database_id                   = each.value.recover_database_id
  recovery_point_id                     = each.value.recovery_point_id
  restore_dropped_database_id           = each.value.restore_dropped_database_id
  restore_long_term_retention_backup_id = each.value.restore_long_term_retention_backup_id

  elastic_pool_id = each.value.elastic_pool_id

  zone_redundant       = each.value.zone_redundant
  read_scale           = each.value.read_scale
  read_replica_count   = each.value.read_replica_count
  storage_account_type = each.value.storage_account_type

  min_capacity                = each.value.min_capacity
  auto_pause_delay_in_minutes = each.value.auto_pause_delay_in_minutes

  ledger_enabled = each.value.ledger_enabled
  enclave_type   = each.value.enclave_type

  geo_backup_enabled                  = each.value.geo_backup_enabled
  maintenance_configuration_name      = each.value.maintenance_configuration_name
  transparent_data_encryption_enabled = each.value.transparent_data_encryption_enabled

  dynamic "short_term_retention_policy" {
    for_each = each.value.short_term_retention_policy != null ? [each.value.short_term_retention_policy] : []

    content {
      retention_days           = short_term_retention_policy.value.retention_days
      backup_interval_in_hours = short_term_retention_policy.value.backup_interval_in_hours
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = each.value.long_term_retention_policy != null ? [each.value.long_term_retention_policy] : []

    content {
      weekly_retention  = long_term_retention_policy.value.weekly_retention
      monthly_retention = long_term_retention_policy.value.monthly_retention
      yearly_retention  = long_term_retention_policy.value.yearly_retention
      week_of_year      = long_term_retention_policy.value.week_of_year
    }
  }

  tags = each.value.tags
}

resource "azurerm_mssql_firewall_rule" "rule" {
  for_each = local.firewall_rules

  name      = each.value.name
  server_id = each.value.server_id

  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_failover_group" "failover_group" {
  for_each = local.failover_groups

  name      = each.value.name
  server_id = each.value.server_id

  databases = each.value.databases

  partner_server {
    id = each.value.partner_server_id
  }

  read_write_endpoint_failover_policy {
    mode          = each.value.read_write_endpoint_failover_policy.mode
    grace_minutes = each.value.read_write_endpoint_failover_policy.grace_minutes
  }

  readonly_endpoint_failover_policy_enabled = each.value.readonly_endpoint_failover_policy_enabled

  tags = each.value.tags
}
