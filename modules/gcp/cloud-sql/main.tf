locals {
  replicas = {
    for b in flatten([
      for instance_key, instance in var.instances : [
        for replica_key, replica in instance.replicas : {
          instance_key = instance_key
          replica_key  = replica_key
          instance     = instance
          replica      = replica
        }
      ]
    ]) : "${b.instance_key}/${b.replica_key}" => b
  }
}

resource "google_sql_database_instance" "instance" {
  for_each = var.instances

  name                = each.value.name
  database_version    = each.value.database_version
  region              = each.value.region
  project             = each.value.project_id
  root_password       = each.value.root_password
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy

  settings {
    tier                  = each.value.tier
    edition               = each.value.edition
    availability_type     = each.value.availability_type
    disk_type             = each.value.disk_type
    disk_size             = each.value.disk_size
    disk_autoresize       = each.value.disk_autoresize
    disk_autoresize_limit = each.value.disk_autoresize_limit
    user_labels           = each.value.labels

    dynamic "database_flags" {
      for_each = each.value.database_flags

      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    dynamic "backup_configuration" {
      for_each = each.value.backup_configuration != null ? [each.value.backup_configuration] : []

      content {
        enabled                        = backup_configuration.value.enabled
        start_time                     = backup_configuration.value.start_time
        point_in_time_recovery_enabled = backup_configuration.value.point_in_time_recovery_enabled
        binary_log_enabled             = backup_configuration.value.binary_log_enabled
        location                       = backup_configuration.value.location

        dynamic "backup_retention_settings" {
          for_each = backup_configuration.value.retained_backups != null ? [1] : []

          content {
            retained_backups = backup_configuration.value.retained_backups
          }
        }
      }
    }

    dynamic "ip_configuration" {
      for_each = each.value.ip_configuration != null ? [each.value.ip_configuration] : []

      content {
        ipv4_enabled       = ip_configuration.value.ipv4_enabled
        private_network    = ip_configuration.value.private_network
        ssl_mode           = ip_configuration.value.ssl_mode
        allocated_ip_range = ip_configuration.value.allocated_ip_range

        dynamic "authorized_networks" {
          for_each = ip_configuration.value.authorized_networks

          content {
            name  = authorized_networks.value.name
            value = authorized_networks.value.value
          }
        }
      }
    }

    dynamic "maintenance_window" {
      for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []

      content {
        day          = maintenance_window.value.day
        hour         = maintenance_window.value.hour
        update_track = maintenance_window.value.update_track
      }
    }

    dynamic "insights_config" {
      for_each = each.value.insights_config != null ? [each.value.insights_config] : []

      content {
        query_insights_enabled  = insights_config.value.query_insights_enabled
        query_string_length     = insights_config.value.query_string_length
        record_application_tags = insights_config.value.record_application_tags
        record_client_address   = insights_config.value.record_client_address
      }
    }
  }
}

resource "google_sql_database_instance" "replica" {
  for_each = local.replicas

  name                 = each.value.replica.name
  database_version     = each.value.instance.database_version
  region               = each.value.replica.region
  project              = each.value.instance.project_id
  master_instance_name = google_sql_database_instance.instance[each.value.instance_key].name
  deletion_protection  = each.value.replica.deletion_protection
  deletion_policy      = each.value.instance.deletion_policy

  settings {
    tier                  = each.value.replica.tier
    availability_type     = each.value.replica.availability_type
    disk_type             = each.value.replica.disk_type
    disk_size             = each.value.replica.disk_size
    disk_autoresize       = each.value.replica.disk_autoresize
    disk_autoresize_limit = each.value.replica.disk_autoresize_limit

    dynamic "database_flags" {
      for_each = each.value.replica.database_flags

      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    dynamic "ip_configuration" {
      for_each = each.value.replica.ip_configuration != null ? [each.value.replica.ip_configuration] : []

      content {
        ipv4_enabled       = ip_configuration.value.ipv4_enabled
        private_network    = ip_configuration.value.private_network
        ssl_mode           = ip_configuration.value.ssl_mode
        allocated_ip_range = ip_configuration.value.allocated_ip_range

        dynamic "authorized_networks" {
          for_each = ip_configuration.value.authorized_networks

          content {
            name  = authorized_networks.value.name
            value = authorized_networks.value.value
          }
        }
      }
    }
  }
}
