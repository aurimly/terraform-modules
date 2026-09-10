resource "google_redis_instance" "instance" {
  for_each = var.instances

  name                    = each.value.name
  region                  = each.value.region
  project                 = each.value.project_id
  memory_size_gb          = each.value.memory_size_gb
  redis_version           = each.value.redis_version
  tier                    = each.value.tier
  location_id             = each.value.location_id
  alternative_location_id = each.value.alternative_location_id
  connect_mode            = each.value.connect_mode
  reserved_ip_range       = each.value.reserved_ip_range
  secondary_ip_range      = each.value.secondary_ip_range
  authorized_network      = each.value.authorized_network
  display_name            = each.value.display_name
  labels                  = each.value.labels
  redis_configs           = each.value.redis_configs
  auth_enabled            = each.value.auth_enabled
  transit_encryption_mode = each.value.transit_encryption_mode
  replica_count           = each.value.replica_count
  read_replicas_mode      = each.value.read_replicas_mode
  deletion_protection     = each.value.deletion_protection

  dynamic "maintenance_policy" {
    for_each = each.value.maintenance_policy != null ? [each.value.maintenance_policy] : []

    content {
      dynamic "weekly_maintenance_window" {
        for_each = [maintenance_policy.value]

        content {
          day = weekly_maintenance_window.value.day

          dynamic "start_time" {
            for_each = [weekly_maintenance_window.value.start_time]

            content {
              hours   = start_time.value.hours
              minutes = start_time.value.minutes
            }
          }
        }
      }
    }
  }

  dynamic "persistence_config" {
    for_each = each.value.persistence_config != null ? [each.value.persistence_config] : []

    content {
      persistence_mode        = persistence_config.value.persistence_mode
      rdb_snapshot_period     = persistence_config.value.rdb_snapshot_period
      rdb_snapshot_start_time = persistence_config.value.rdb_snapshot_start_time
    }
  }

}
