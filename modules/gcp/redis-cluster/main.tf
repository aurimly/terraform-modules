resource "google_memorystore_instance" "instance" {
  for_each = var.instances

  instance_id                 = each.value.name
  location                    = each.value.location
  project                     = each.value.project_id
  shard_count                 = each.value.shard_count
  node_type                   = each.value.node_type
  engine_version              = each.value.engine_version
  engine_configs              = each.value.engine_configs
  labels                      = each.value.labels
  replica_count               = each.value.replica_count
  authorization_mode          = each.value.authorization_mode
  transit_encryption_mode     = each.value.transit_encryption_mode
  deletion_protection_enabled = each.value.deletion_protection

  dynamic "zone_distribution_config" {
    for_each = each.value.zone_distribution_config != null ? [each.value.zone_distribution_config] : []

    content {
      mode = zone_distribution_config.value.mode
      zone = zone_distribution_config.value.zone
    }
  }

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

  dynamic "desired_auto_created_endpoints" {
    for_each = each.value.desired_auto_created_endpoints != null ? each.value.desired_auto_created_endpoints : []

    content {
      network    = desired_auto_created_endpoints.value.network
      project_id = desired_auto_created_endpoints.value.project_id
    }
  }
}
