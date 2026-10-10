locals {
  firewall_rules = merge([
    for cache_key, cache in var.redis_caches : {
      for rule_key, rule in cache.firewall_rules : "${cache_key}.${rule_key}" => merge(rule, {
        redis_cache_name    = cache.name
        resource_group_name = cache.resource_group_name
      })
    }
  ]...)

  linked_servers = {
    for link_key, entry in var.linked_servers : link_key => {
      target_redis_cache_name     = var.redis_caches[entry.target_cache_key].name
      resource_group_name         = var.redis_caches[entry.target_cache_key].resource_group_name
      linked_redis_cache_id       = azurerm_redis_cache.cache[entry.linked_cache_key].id
      linked_redis_cache_location = var.redis_caches[entry.linked_cache_key].location
      server_role                 = entry.server_role
    }
  }
}

resource "azurerm_redis_cache" "cache" {
  for_each = var.redis_caches

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  capacity            = each.value.capacity
  family              = each.value.family
  sku_name            = each.value.sku_name

  redis_version                 = each.value.redis_version
  non_ssl_port_enabled          = each.value.non_ssl_port_enabled
  minimum_tls_version           = each.value.minimum_tls_version
  public_network_access_enabled = each.value.public_network_access_enabled

  access_keys_authentication_enabled = each.value.access_keys_authentication_enabled

  subnet_id                 = each.value.subnet_id
  private_static_ip_address = each.value.private_static_ip_address
  shard_count               = each.value.shard_count
  replicas_per_master       = each.value.replicas_per_master
  replicas_per_primary      = each.value.replicas_per_primary

  tenant_settings = each.value.tenant_settings
  zones           = each.value.zones

  dynamic "redis_configuration" {
    for_each = each.value.redis_configuration != null ? [each.value.redis_configuration] : []
    content {
      aof_backup_enabled              = redis_configuration.value.aof_backup_enabled
      aof_storage_connection_string_0 = redis_configuration.value.aof_storage_connection_string_0
      aof_storage_connection_string_1 = redis_configuration.value.aof_storage_connection_string_1

      rdb_backup_enabled              = redis_configuration.value.rdb_backup_enabled
      rdb_backup_frequency            = redis_configuration.value.rdb_backup_frequency
      rdb_backup_max_snapshot_count   = redis_configuration.value.rdb_backup_max_snapshot_count
      rdb_storage_connection_string   = redis_configuration.value.rdb_storage_connection_string
      storage_account_subscription_id = redis_configuration.value.storage_account_subscription_id

      data_persistence_authentication_method = redis_configuration.value.data_persistence_authentication_method

      authentication_enabled                  = redis_configuration.value.authentication_enabled
      active_directory_authentication_enabled = redis_configuration.value.active_directory_authentication_enabled

      maxmemory_reserved              = redis_configuration.value.maxmemory_reserved
      maxmemory_delta                 = redis_configuration.value.maxmemory_delta
      maxmemory_policy                = redis_configuration.value.maxmemory_policy
      maxfragmentationmemory_reserved = redis_configuration.value.maxfragmentationmemory_reserved
      notify_keyspace_events          = redis_configuration.value.notify_keyspace_events
    }
  }

  dynamic "patch_schedule" {
    for_each = each.value.patch_schedule
    content {
      day_of_week        = patch_schedule.value.day_of_week
      start_hour_utc     = patch_schedule.value.start_hour_utc
      maintenance_window = patch_schedule.value.maintenance_window
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

resource "azurerm_redis_firewall_rule" "rule" {
  for_each = local.firewall_rules

  name                = each.value.name
  redis_cache_name    = each.value.redis_cache_name
  resource_group_name = each.value.resource_group_name
  start_ip            = each.value.start_ip
  end_ip              = each.value.end_ip
}

resource "azurerm_redis_linked_server" "linked_server" {
  for_each = local.linked_servers

  target_redis_cache_name     = each.value.target_redis_cache_name
  resource_group_name         = each.value.resource_group_name
  linked_redis_cache_id       = each.value.linked_redis_cache_id
  linked_redis_cache_location = each.value.linked_redis_cache_location
  server_role                 = each.value.server_role
}
