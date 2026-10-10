locals {
  sql_databases = merge([
    for account_key, account in var.cosmosdb_accounts : {
      for db_key, db in account.sql_databases : "${account_key}.${db_key}" => merge(db, {
        account_name        = account.name
        resource_group_name = account.resource_group_name
      })
    }
  ]...)

  sql_containers = merge(flatten([
    for account_key, account in var.cosmosdb_accounts : [
      for db_key, db in account.sql_databases : {
        for container_key, container in db.containers : "${account_key}.${db_key}.${container_key}" => merge(container, {
          database_name       = db.name
          account_name        = account.name
          resource_group_name = account.resource_group_name
        })
      }
    ]
  ])...)

  mongo_databases = merge([
    for account_key, account in var.cosmosdb_accounts : {
      for db_key, db in account.mongo_databases : "${account_key}.${db_key}" => merge(db, {
        account_name        = account.name
        resource_group_name = account.resource_group_name
      })
    }
  ]...)

  mongo_collections = merge(flatten([
    for account_key, account in var.cosmosdb_accounts : [
      for db_key, db in account.mongo_databases : {
        for collection_key, collection in db.collections : "${account_key}.${db_key}.${collection_key}" => merge(collection, {
          database_name       = db.name
          account_name        = account.name
          resource_group_name = account.resource_group_name
        })
      }
    ]
  ])...)
}

resource "azurerm_cosmosdb_account" "account" {
  for_each = var.cosmosdb_accounts

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  offer_type           = each.value.offer_type
  kind                 = each.value.kind
  mongo_server_version = each.value.mongo_server_version

  minimal_tls_version = each.value.minimal_tls_version

  free_tier_enabled                  = each.value.free_tier_enabled
  analytical_storage_enabled         = each.value.analytical_storage_enabled
  automatic_failover_enabled         = each.value.automatic_failover_enabled
  multiple_write_locations_enabled   = each.value.multiple_write_locations_enabled
  partition_merge_enabled            = each.value.partition_merge_enabled
  burst_capacity_enabled             = each.value.burst_capacity_enabled
  public_network_access_enabled      = each.value.public_network_access_enabled
  is_virtual_network_filter_enabled  = each.value.is_virtual_network_filter_enabled
  local_authentication_enabled       = each.value.local_authentication_enabled
  access_key_metadata_writes_enabled = each.value.access_key_metadata_writes_enabled

  network_acl_bypass_for_azure_services = each.value.network_acl_bypass_for_azure_services
  network_acl_bypass_ids                = each.value.network_acl_bypass_ids
  ip_range_filter                       = each.value.ip_range_filter
  default_identity_type                 = each.value.default_identity_type

  key_vault_key_id = each.value.key_vault_key_id

  dynamic "capabilities" {
    for_each = each.value.capabilities
    content {
      name = capabilities.value.name
    }
  }

  consistency_policy {
    consistency_level       = each.value.consistency_policy.consistency_level
    max_interval_in_seconds = each.value.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = each.value.consistency_policy.max_staleness_prefix
  }

  dynamic "geo_location" {
    for_each = each.value.geo_location
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  dynamic "virtual_network_rule" {
    for_each = each.value.virtual_network_rule
    content {
      id                                   = virtual_network_rule.value.id
      ignore_missing_vnet_service_endpoint = virtual_network_rule.value.ignore_missing_vnet_service_endpoint
    }
  }

  dynamic "analytical_storage" {
    for_each = each.value.analytical_storage != null ? [each.value.analytical_storage] : []
    content {
      schema_type = analytical_storage.value.schema_type
    }
  }

  dynamic "capacity" {
    for_each = each.value.capacity != null ? [each.value.capacity] : []
    content {
      total_throughput_limit = capacity.value.total_throughput_limit
    }
  }

  dynamic "backup" {
    for_each = each.value.backup != null ? [each.value.backup] : []
    content {
      type                = backup.value.type
      tier                = backup.value.tier
      interval_in_minutes = backup.value.interval_in_minutes
      retention_in_hours  = backup.value.retention_in_hours
      storage_redundancy  = backup.value.storage_redundancy
    }
  }

  dynamic "cors_rule" {
    for_each = each.value.cors_rule != null ? [each.value.cors_rule] : []
    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  create_mode = each.value.create_mode

  dynamic "restore" {
    for_each = each.value.restore != null ? [each.value.restore] : []
    content {
      source_cosmosdb_account_id = restore.value.source_cosmosdb_account_id
      restore_timestamp_in_utc   = restore.value.restore_timestamp_in_utc

      dynamic "database" {
        for_each = restore.value.database
        content {
          name             = database.value.name
          collection_names = database.value.collection_names
        }
      }
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

resource "azurerm_cosmosdb_sql_database" "sql_database" {
  for_each = local.sql_databases

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name

  throughput = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_settings != null ? [each.value.autoscale_settings] : []
    content {
      max_throughput = autoscale_settings.value.max_throughput
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "sql_container" {
  for_each = local.sql_containers

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  database_name       = each.value.database_name

  partition_key_paths   = each.value.partition_key_paths
  partition_key_kind    = each.value.partition_key_kind
  partition_key_version = each.value.partition_key_version

  throughput = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_settings != null ? [each.value.autoscale_settings] : []
    content {
      max_throughput = autoscale_settings.value.max_throughput
    }
  }

  default_ttl            = each.value.default_ttl
  analytical_storage_ttl = each.value.analytical_storage_ttl

  dynamic "unique_key" {
    for_each = each.value.unique_key
    content {
      paths = unique_key.value.paths
    }
  }

  dynamic "indexing_policy" {
    for_each = each.value.indexing_policy != null ? [each.value.indexing_policy] : []
    content {
      indexing_mode = indexing_policy.value.indexing_mode

      dynamic "included_path" {
        for_each = indexing_policy.value.included_path
        content {
          path = included_path.value.path
        }
      }

      dynamic "excluded_path" {
        for_each = indexing_policy.value.excluded_path
        content {
          path = excluded_path.value.path
        }
      }

      dynamic "composite_index" {
        for_each = indexing_policy.value.composite_index
        content {
          dynamic "index" {
            for_each = composite_index.value.index
            content {
              path  = index.value.path
              order = index.value.order
            }
          }
        }
      }

      dynamic "spatial_index" {
        for_each = indexing_policy.value.spatial_index
        content {
          path = spatial_index.value.path
        }
      }
    }
  }

  dynamic "conflict_resolution_policy" {
    for_each = each.value.conflict_resolution_policy != null ? [each.value.conflict_resolution_policy] : []
    content {
      mode                          = conflict_resolution_policy.value.mode
      conflict_resolution_path      = conflict_resolution_policy.value.conflict_resolution_path
      conflict_resolution_procedure = conflict_resolution_policy.value.conflict_resolution_procedure
    }
  }
}

resource "azurerm_cosmosdb_mongo_database" "mongo_database" {
  for_each = local.mongo_databases

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name

  throughput = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_settings != null ? [each.value.autoscale_settings] : []
    content {
      max_throughput = autoscale_settings.value.max_throughput
    }
  }
}

resource "azurerm_cosmosdb_mongo_collection" "mongo_collection" {
  for_each = local.mongo_collections

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  database_name       = each.value.database_name

  shard_key              = each.value.shard_key
  default_ttl_seconds    = each.value.default_ttl_seconds
  analytical_storage_ttl = each.value.analytical_storage_ttl

  throughput = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_settings != null ? [each.value.autoscale_settings] : []
    content {
      max_throughput = autoscale_settings.value.max_throughput
    }
  }

  dynamic "index" {
    for_each = each.value.index
    content {
      keys   = index.value.keys
      unique = index.value.unique
    }
  }
}
