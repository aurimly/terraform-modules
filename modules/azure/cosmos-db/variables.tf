variable "cosmosdb_accounts" {
  description = "Map of Cosmos DB accounts keyed by an arbitrary identifier. Each entry creates one azurerm_cosmosdb_account in the named resource group; account names host the <name>.documents.azure.com endpoint and are globally unique across all of Azure. Nested SQL databases and containers, and Mongo databases and collections, wire into the account resources this module creates itself."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    offer_type           = optional(string, "Standard")
    kind                 = optional(string, "GlobalDocumentDB")
    mongo_server_version = optional(string)

    minimal_tls_version = optional(string, "Tls12")

    free_tier_enabled                  = optional(bool, false)
    analytical_storage_enabled         = optional(bool, false)
    automatic_failover_enabled         = optional(bool)
    multiple_write_locations_enabled   = optional(bool)
    partition_merge_enabled            = optional(bool)
    burst_capacity_enabled             = optional(bool)
    public_network_access_enabled      = optional(bool, true)
    is_virtual_network_filter_enabled  = optional(bool)
    local_authentication_enabled       = optional(bool, true)
    access_key_metadata_writes_enabled = optional(bool, true)

    network_acl_bypass_for_azure_services = optional(bool)
    network_acl_bypass_ids                = optional(list(string))
    ip_range_filter                       = optional(list(string))
    default_identity_type                 = optional(string)

    key_vault_key_id = optional(string)

    capabilities = optional(map(object({
      name = string
    })), {})

    consistency_policy = object({
      consistency_level       = string
      max_interval_in_seconds = optional(number)
      max_staleness_prefix    = optional(number)
    })

    geo_location = map(object({
      location          = string
      failover_priority = number
      zone_redundant    = optional(bool)
    }))

    virtual_network_rule = optional(map(object({
      id                                   = string
      ignore_missing_vnet_service_endpoint = optional(bool)
    })), {})

    analytical_storage = optional(object({
      schema_type = string
    }))

    capacity = optional(object({
      total_throughput_limit = number
    }))

    backup = optional(object({
      type                = optional(string, "Periodic")
      tier                = optional(string)
      interval_in_minutes = optional(number)
      retention_in_hours  = optional(number)
      storage_redundancy  = optional(string)
    }))

    cors_rule = optional(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = optional(number)
    }))

    create_mode = optional(string, "Default")

    restore = optional(object({
      source_cosmosdb_account_id = string
      restore_timestamp_in_utc   = string
      database = optional(map(object({
        name             = string
        collection_names = optional(list(string))
      })), {})
    }))

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    sql_databases = optional(map(object({
      name       = string
      throughput = optional(number)
      autoscale_settings = optional(object({
        max_throughput = number
      }))
      containers = optional(map(object({
        name                  = string
        partition_key_paths   = list(string)
        partition_key_kind    = optional(string, "Hash")
        partition_key_version = optional(number)
        throughput            = optional(number)
        autoscale_settings = optional(object({
          max_throughput = number
        }))
        default_ttl            = optional(number)
        analytical_storage_ttl = optional(number)
        unique_key = optional(map(object({
          paths = list(string)
        })), {})
        indexing_policy = optional(object({
          indexing_mode = optional(string, "consistent")
          included_path = optional(map(object({
            path = string
          })), {})
          excluded_path = optional(map(object({
            path = string
          })), {})
          composite_index = optional(map(object({
            index = optional(map(object({
              path  = string
              order = string
            })), {})
          })), {})
          spatial_index = optional(map(object({
            path = string
          })), {})
        }))
        conflict_resolution_policy = optional(object({
          mode                          = string
          conflict_resolution_path      = optional(string)
          conflict_resolution_procedure = optional(string)
        }))
      })), {})
    })), {})

    mongo_databases = optional(map(object({
      name       = string
      throughput = optional(number)
      autoscale_settings = optional(object({
        max_throughput = number
      }))
      collections = optional(map(object({
        name                   = string
        shard_key              = optional(string)
        default_ttl_seconds    = optional(number)
        analytical_storage_ttl = optional(number)
        throughput             = optional(number)
        autoscale_settings = optional(object({
          max_throughput = number
        }))
        index = optional(map(object({
          keys   = list(string)
          unique = optional(bool)
        })), {})
      })), {})
    })), {})

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts : can(regex("^[a-z0-9][a-z0-9-]{1,42}[a-z0-9]$", account.name))
    ])
    error_message = "name must be 3–44 characters, lowercase alphanumerics and hyphens only, starting and ending alphanumeric — the account name doubles as the endpoint host (<name>.documents.azure.com) and is globally unique across all of Azure, which the module cannot check: a claimed name fails at apply."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts : account.offer_type == "Standard"
    ])
    error_message = "offer_type must be \"Standard\" — the only offer type the Azure API accepts today (kept as an input for parity with future offer types)."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts : contains(["GlobalDocumentDB", "MongoDB", "Parse"], account.kind)
    ])
    error_message = "kind must be GlobalDocumentDB, MongoDB or Parse (case-sensitive) — changing it forces replacement."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts :
      account.mongo_server_version == null || account.kind == "MongoDB"
    ])
    error_message = "mongo_server_version requires kind = \"MongoDB\" — versions 7.0, 6.0, 5.0, 4.2, 4.0, 3.6 and 3.2 apply to Mongo accounts only."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts : account.minimal_tls_version == "Tls12"
    ])
    error_message = "minimal_tls_version must be \"Tls12\" — the only value the Azure API accepts anymore (TLS 1.0/1.1 are retired)."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        length([for geo_key, geo in account.geo_location : geo if geo.failover_priority == 0]) == 1
      ]
    ]))
    error_message = "exactly one geo_location entry must carry failover_priority = 0 — the write region; the Azure API rejects accounts with a missing or duplicated primary priority."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        length(distinct([for geo_key, geo in account.geo_location : geo.failover_priority])) == length(account.geo_location)
        && alltrue([for geo_key, geo in account.geo_location : geo.failover_priority >= 0 && geo.failover_priority < length(account.geo_location)])
      ]
    ]))
    error_message = "geo_location failover priorities must be unique and contiguous from 0 up to (number of regions - 1) — the Azure API rejects priorities above that range or with gaps."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts : contains(["BoundedStaleness", "Eventual", "Session", "Strong", "ConsistentPrefix"], account.consistency_policy.consistency_level)
    ])
    error_message = "consistency_policy.consistency_level must be BoundedStaleness, Eventual, Session, Strong or ConsistentPrefix."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts :
      (account.consistency_policy.consistency_level == "BoundedStaleness"
        ? account.consistency_policy.max_interval_in_seconds != null && account.consistency_policy.max_interval_in_seconds >= 5 && account.consistency_policy.max_interval_in_seconds <= 86400
        && account.consistency_policy.max_staleness_prefix != null && account.consistency_policy.max_staleness_prefix >= 10 && account.consistency_policy.max_staleness_prefix <= 2147483647
      : account.consistency_policy.max_interval_in_seconds == null && account.consistency_policy.max_staleness_prefix == null)
    ])
    error_message = "consistency_policy: BoundedStaleness requires max_interval_in_seconds (5–86400) and max_staleness_prefix (10–2147483647); every other consistency level takes neither."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        for capability_key, capability in account.capabilities :
        capability.name != "MongoDBv3.4" || contains([for cap_key, cap in account.capabilities : cap.name], "EnableMongo")
      ]
    ]))
    error_message = "the MongoDBv3.4 capability requires EnableMongo alongside it — the API rejects Mongo 3.4 protocol support on accounts without the Mongo capability."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts :
      contains([for cap_key, cap in account.capabilities : cap.name], "EnableServerless") ? flatten([
        for db_key, db in account.sql_databases : flatten([
          [db.throughput == null && db.autoscale_settings == null],
          [for container_key, container in db.containers : container.throughput == null && container.autoscale_settings == null]
        ])
      ]) : [true]
    ]))
    error_message = "serverless accounts (the EnableServerless capability) reject throughput and autoscale_settings on every SQL database and container — serverless scales on the account, not per collection."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts :
      contains([for cap_key, cap in account.capabilities : cap.name], "EnableServerless") ? flatten([
        for db_key, db in account.mongo_databases : flatten([
          [db.throughput == null && db.autoscale_settings == null],
          [for collection_key, collection in db.collections : collection.throughput == null && collection.autoscale_settings == null]
        ])
      ]) : [true]
    ]))
    error_message = "serverless accounts (the EnableServerless capability) reject throughput and autoscale_settings on every Mongo database and collection — serverless scales on the account, not per collection."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : flatten([
        for db_key, db in merge(account.sql_databases, account.mongo_databases) : [
          db.throughput == null || (db.throughput % 100 == 0 && db.throughput >= 400 && db.throughput <= 1000000),
          db.autoscale_settings == null || (db.autoscale_settings.max_throughput >= 1000 && db.autoscale_settings.max_throughput <= 1000000 && db.autoscale_settings.max_throughput % 1000 == 0),
          db.throughput == null || db.autoscale_settings == null
        ]
      ])
    ]))
    error_message = "databases: throughput must be a multiple of 100 within 400–1,000,000 RU/s, autoscale max_throughput a multiple of 1000 within 1,000–1,000,000 RU/s, and throughput and autoscale_settings are mutually exclusive."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : flatten([
        for db_key, db in account.sql_databases : [
          for container_key, container in db.containers : [
            container.throughput == null || (container.throughput % 100 == 0 && container.throughput >= 400 && container.throughput <= 1000000),
            container.autoscale_settings == null || (container.autoscale_settings.max_throughput >= 1000 && container.autoscale_settings.max_throughput <= 1000000 && container.autoscale_settings.max_throughput % 1000 == 0),
            container.throughput == null || container.autoscale_settings == null
          ]
        ]
      ])
    ]))
    error_message = "containers: throughput must be a multiple of 100 within 400–1,000,000 RU/s, autoscale max_throughput a multiple of 1000 within 1,000–1,000,000 RU/s, and throughput and autoscale_settings are mutually exclusive."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : flatten([
        for db_key, db in account.mongo_databases : [
          for collection_key, collection in db.collections : [
            collection.throughput == null || (collection.throughput % 100 == 0 && collection.throughput >= 400 && collection.throughput <= 1000000),
            collection.autoscale_settings == null || (collection.autoscale_settings.max_throughput >= 1000 && collection.autoscale_settings.max_throughput <= 1000000 && collection.autoscale_settings.max_throughput % 1000 == 0),
            collection.throughput == null || collection.autoscale_settings == null
          ]
        ]
      ])
    ]))
    error_message = "collections: throughput must be a multiple of 100 within 400–1,000,000 RU/s, autoscale max_throughput a multiple of 1000 within 1,000–1,000,000 RU/s, and throughput and autoscale_settings are mutually exclusive."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        account.create_mode == "Default" || (account.create_mode == "Restore" && account.restore != null && (account.backup == null || account.backup.type == "Continuous"))
      ]
    ]))
    error_message = "create_mode = \"Restore\" requires the restore block and a Continuous backup posture; restores pull from restorableDatabaseAccounts, never from periodic backups."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        account.restore == null || account.create_mode == "Restore"
      ]
    ]))
    error_message = "the restore block only pairs with create_mode = \"Restore\" — set create_mode accordingly or drop the restore block."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        account.backup == null || (
          contains(["Periodic", "Continuous"], account.backup.type)
          && (account.backup.type == "Continuous"
            ? account.backup.interval_in_minutes == null && account.backup.retention_in_hours == null && account.backup.storage_redundancy == null
          : account.backup.tier == null)
        )
      ]
    ]))
    error_message = "backup: Continuous takes only tier (Continuous7Days/Continuous30Days) and no interval/retention/storage_redundancy; Periodic takes no tier. Periodic→Continuous is one-way — see Notes."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        account.backup == null || account.backup.type == "Continuous" || (
          (account.backup.interval_in_minutes == null || (account.backup.interval_in_minutes >= 60 && account.backup.interval_in_minutes <= 1440))
          && (account.backup.retention_in_hours == null || (account.backup.retention_in_hours >= 8 && account.backup.retention_in_hours <= 720))
          && (account.backup.storage_redundancy == null || contains(["Geo", "Local", "Zone"], account.backup.storage_redundancy))
        )
      ]
    ]))
    error_message = "Periodic backup: interval_in_minutes 60–1440 (default 240), retention_in_hours 8–720 (default 8), storage_redundancy Geo/Local/Zone (default Geo)."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts : account.key_vault_key_id == null || account.identity != null
    ])
    error_message = "key_vault_key_id (customer-managed keys) requires an identity block — the account unlocks its CMK through a managed identity; the Key Vault access policy itself is consumer-side."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts :
      account.capacity == null || (account.capacity.total_throughput_limit >= -1 && account.capacity.total_throughput_limit <= 1000000)
    ])
    error_message = "capacity.total_throughput_limit must be -1 (no limit, the API default) or a cap in 0–1,000,000 RU/s."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts :
      account.analytical_storage == null || contains(["FullFidelity", "WellDefined"], account.analytical_storage.schema_type)
    ])
    error_message = "analytical_storage.schema_type must be FullFidelity or WellDefined."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        for db_key, db in account.sql_databases : [
          for container_key, container in db.containers :
          container.indexing_policy == null || (
            length(container.indexing_policy.included_path) == 0 && length(container.indexing_policy.excluded_path) == 0
            || contains([for path_key, path in container.indexing_policy.included_path : path.path], "/*")
            || contains([for path_key, path in container.indexing_policy.excluded_path : path.path], "/*")
          )
        ]
      ]
    ]))
    error_message = "indexing_policy: either included_path or excluded_path must contain the path \"/*\" — the Azure API rejects index policies without the catch-all star path."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        for db_key, db in account.sql_databases : [
          for container_key, container in db.containers :
          container.indexing_policy == null || alltrue(flatten([
            for composite_key, composite in container.indexing_policy.composite_index : [
              for index_key, index_element in composite.index : contains(["Ascending", "Descending"], index_element.order)
            ]
          ]))
        ]
      ]
    ]))
    error_message = "indexing_policy composite index entries take an order of Ascending or Descending per path."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        for db_key, db in account.sql_databases : [
          for container_key, container in db.containers :
          container.conflict_resolution_policy == null || (
            (container.conflict_resolution_policy.mode == "LastWriterWins" && container.conflict_resolution_policy.conflict_resolution_path != null)
            || (container.conflict_resolution_policy.mode == "Custom" && container.conflict_resolution_policy.conflict_resolution_procedure != null)
          )
        ]
      ]
    ]))
    error_message = "conflict_resolution_policy: mode LastWriterWins takes conflict_resolution_path, mode Custom takes conflict_resolution_procedure — each mode pairs with exactly its own argument."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        account.cors_rule == null || (
          length(account.cors_rule.allowed_methods) >= 1
          && alltrue([for method in account.cors_rule.allowed_methods : contains(["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT", "PATCH"], method)])
          && (account.cors_rule.max_age_in_seconds == null || (account.cors_rule.max_age_in_seconds >= 1 && account.cors_rule.max_age_in_seconds <= 2147483647))
        )
      ]
    ]))
    error_message = "cors_rule: allowed_methods from DELETE, GET, HEAD, MERGE, POST, OPTIONS, PUT, PATCH (at least one) and max_age_in_seconds 1–2147483647 when set."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts :
      account.default_identity_type == null || contains(["FirstPartyIdentity", "SystemAssignedIdentity"], account.default_identity_type) || can(regex("^UserAssignedIdentity=/", account.default_identity_type))
    ])
    error_message = "default_identity_type must be FirstPartyIdentity, SystemAssignedIdentity, or \"UserAssignedIdentity=<full ARM identity ID>\" — the identity used to reach Key Vault."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : [
        for rule_key, rule in account.virtual_network_rule : can(regex("^/", rule.id))
      ]
    ]))
    error_message = "virtual_network_rule ids must be full ARM subnet resource IDs (starting with \"/\") — the allowed list of subnets; is_virtual_network_filter_enabled pairs with it."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts :
      account.identity == null || !contains(["UserAssigned", "SystemAssigned, UserAssigned"], account.identity.type) || alltrue([for id in coalesce(account.identity.identity_ids, []) : can(regex("^/", id))])
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — full ARM resource IDs of user-assigned managed identities."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts :
      length(account.mongo_databases) == 0 || account.kind == "MongoDB"
    ])
    error_message = "mongo_databases require kind = \"MongoDB\" — the Mongo API surface only exists on Mongo-kind accounts."
  }

  validation {
    condition = alltrue([
      for account in var.cosmosdb_accounts :
      length(account.tags) <= 50 && alltrue([for tag_key, tag_value in account.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }

  validation {
    condition = alltrue(concat(
      [for account_key in keys(var.cosmosdb_accounts) : !can(regex("\\.", account_key))],
      flatten([
        for account in var.cosmosdb_accounts : flatten([
          [for db_key in concat(keys(account.sql_databases), keys(account.mongo_databases)) : !can(regex("\\.", db_key))],
          [for db_key, db in account.sql_databases : [for container_key in keys(db.containers) : !can(regex("\\.", container_key))]],
          [for db_key, db in account.mongo_databases : [for collection_key in keys(db.collections) : !can(regex("\\.", collection_key))]]
        ])
      ])
    ))
    error_message = "map keys of cosmosdb_accounts and its nested sql_databases, containers, mongo_databases and collections maps must not contain \".\" — parents compose into child identifiers \"<account_key>.<db_key>[.<container_key>]\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for account in var.cosmosdb_accounts : flatten([
        [
          length(distinct([for db in account.sql_databases : lower(db.name)])) == length(account.sql_databases),
          length(distinct([for db in account.mongo_databases : lower(db.name)])) == length(account.mongo_databases)
        ],
        [for db_key, db in account.sql_databases : length(distinct([for container in db.containers : container.name])) == length(db.containers)],
        [for db_key, db in account.mongo_databases : length(distinct([for collection in db.collections : collection.name])) == length(db.collections)]
      ])
    ]))
    error_message = "database names must be unique within their account (case-insensitive at the API), container names unique within their database and collection names within their Mongo database."
  }
}
