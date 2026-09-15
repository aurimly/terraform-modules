locals {
  instances = {
    for e in flatten([
      for cluster_key, cluster in var.clusters : [
        for instance_key, instance in cluster.instances : {
          cluster_key  = cluster_key
          instance_key = instance_key
          cluster      = cluster
          instance     = instance
        }
      ]
    ]) : "${e.cluster_key}/${e.instance_key}" => e
  }

  backups = {
    for b in flatten([
      for cluster_key, cluster in var.clusters : [
        for backup_key, backup in cluster.backups : {
          cluster_key = cluster_key
          backup_key  = backup_key
          cluster     = cluster
          backup      = backup
        }
      ]
    ]) : "${b.cluster_key}/${b.backup_key}" => b
  }
}

resource "google_alloydb_cluster" "cluster" {
  for_each = var.clusters

  cluster_id          = each.value.cluster_id
  location            = each.value.location
  project             = each.value.project_id
  cluster_type        = each.value.cluster_type
  database_version    = each.value.database_version
  display_name        = each.value.display_name
  labels              = each.value.labels
  annotations         = each.value.annotations
  deletion_policy     = each.value.deletion_policy
  deletion_protection = each.value.deletion_protection

  dynamic "network_config" {
    for_each = each.value.network_config != null ? [each.value.network_config] : []

    content {
      network            = network_config.value.network
      allocated_ip_range = network_config.value.allocated_ip_range
    }
  }

  dynamic "encryption_config" {
    for_each = each.value.encryption_config != null ? [each.value.encryption_config] : []

    content {
      kms_key_name = encryption_config.value.kms_key_name
    }
  }

  dynamic "initial_user" {
    for_each = each.value.initial_user != null ? [each.value.initial_user] : []

    content {
      user     = initial_user.value.user
      password = initial_user.value.password
    }
  }

  dynamic "continuous_backup_config" {
    for_each = each.value.continuous_backup_config != null ? [each.value.continuous_backup_config] : []

    content {
      enabled              = continuous_backup_config.value.enabled
      recovery_window_days = continuous_backup_config.value.recovery_window_days

      dynamic "encryption_config" {
        for_each = continuous_backup_config.value.encryption_config != null ? [continuous_backup_config.value.encryption_config] : []

        content {
          kms_key_name = encryption_config.value.kms_key_name
        }
      }
    }
  }

  dynamic "automated_backup_policy" {
    for_each = each.value.automated_backup_policy != null ? [each.value.automated_backup_policy] : []

    content {
      enabled       = automated_backup_policy.value.enabled
      location      = automated_backup_policy.value.location
      backup_window = automated_backup_policy.value.backup_window
      labels        = automated_backup_policy.value.labels

      dynamic "encryption_config" {
        for_each = automated_backup_policy.value.encryption_config != null ? [automated_backup_policy.value.encryption_config] : []

        content {
          kms_key_name = encryption_config.value.kms_key_name
        }
      }

      dynamic "weekly_schedule" {
        for_each = automated_backup_policy.value.weekly_schedule != null ? [automated_backup_policy.value.weekly_schedule] : []

        content {
          days_of_week = weekly_schedule.value.days_of_week

          dynamic "start_times" {
            for_each = weekly_schedule.value.start_times

            content {
              hours   = start_times.value.hours
              minutes = start_times.value.minutes
              seconds = start_times.value.seconds
              nanos   = start_times.value.nanos
            }
          }
        }
      }

      dynamic "time_based_retention" {
        for_each = automated_backup_policy.value.time_based_retention != null ? [automated_backup_policy.value.time_based_retention] : []

        content {
          retention_period = time_based_retention.value.retention_period
        }
      }

      dynamic "quantity_based_retention" {
        for_each = automated_backup_policy.value.quantity_based_retention != null ? [automated_backup_policy.value.quantity_based_retention] : []

        content {
          count = quantity_based_retention.value.count
        }
      }
    }
  }

  dynamic "secondary_config" {
    for_each = each.value.secondary_config != null ? [each.value.secondary_config] : []

    content {
      primary_cluster_name = secondary_config.value.primary_cluster_name
    }
  }

  dynamic "maintenance_update_policy" {
    for_each = each.value.maintenance_update_policy != null ? [each.value.maintenance_update_policy] : []

    content {
      dynamic "maintenance_windows" {
        for_each = each.value.maintenance_update_policy.maintenance_windows

        content {
          day = maintenance_windows.value.day

          start_time {
            hours   = maintenance_windows.value.start_time.hours
            minutes = maintenance_windows.value.start_time.minutes
            seconds = maintenance_windows.value.start_time.seconds
            nanos   = maintenance_windows.value.start_time.nanos
          }
        }
      }
    }
  }

  dynamic "psc_config" {
    for_each = each.value.psc_config != null ? [each.value.psc_config] : []

    content {
      psc_enabled = psc_config.value.psc_enabled
    }
  }

  subscription_type                = each.value.subscription_type
  skip_await_major_version_upgrade = each.value.skip_await_major_version_upgrade
}

resource "google_alloydb_instance" "instance" {
  for_each = local.instances

  cluster           = google_alloydb_cluster.cluster[each.value.cluster_key].name
  instance_id       = each.value.instance.instance_id
  instance_type     = each.value.instance.instance_type
  display_name      = each.value.instance.display_name
  labels            = each.value.instance.labels
  annotations       = each.value.instance.annotations
  gce_zone          = each.value.instance.gce_zone
  database_flags    = each.value.instance.database_flags
  availability_type = each.value.instance.availability_type
  activation_policy = each.value.instance.activation_policy
  deletion_policy   = each.value.instance.deletion_policy

  dynamic "machine_config" {
    for_each = each.value.instance.machine_config != null ? [each.value.instance.machine_config] : []

    content {
      cpu_count    = machine_config.value.cpu_count
      machine_type = machine_config.value.machine_type
    }
  }

  dynamic "read_pool_config" {
    for_each = each.value.instance.read_pool_config != null ? [each.value.instance.read_pool_config] : []

    content {
      node_count = read_pool_config.value.node_count
    }
  }

  dynamic "query_insights_config" {
    for_each = each.value.instance.query_insights_config != null ? [each.value.instance.query_insights_config] : []

    content {
      query_string_length     = query_insights_config.value.query_string_length
      record_application_tags = query_insights_config.value.record_application_tags
      record_client_address   = query_insights_config.value.record_client_address
      query_plans_per_minute  = query_insights_config.value.query_plans_per_minute
    }
  }

  dynamic "client_connection_config" {
    for_each = each.value.instance.client_connection_config != null ? [each.value.instance.client_connection_config] : []

    content {
      require_connectors = client_connection_config.value.require_connectors

      dynamic "ssl_config" {
        for_each = client_connection_config.value.ssl_config != null ? [client_connection_config.value.ssl_config] : []

        content {
          ssl_mode = ssl_config.value.ssl_mode
        }
      }
    }
  }

  dynamic "network_config" {
    for_each = each.value.instance.network_config != null ? [each.value.instance.network_config] : []

    content {
      enable_public_ip            = network_config.value.enable_public_ip
      enable_outbound_public_ip   = network_config.value.enable_outbound_public_ip
      allocated_ip_range_override = network_config.value.allocated_ip_range_override

      dynamic "authorized_external_networks" {
        for_each = network_config.value.authorized_external_networks

        content {
          cidr_range = authorized_external_networks.value.cidr_range
        }
      }
    }
  }

  depends_on = [google_alloydb_cluster.cluster]
}

resource "google_alloydb_backup" "backup" {
  for_each = local.backups

  backup_id       = each.value.backup.backup_id
  location        = each.value.backup.location
  cluster_name    = google_alloydb_cluster.cluster[each.value.cluster_key].name
  project         = each.value.cluster.project_id
  display_name    = each.value.backup.display_name
  labels          = each.value.backup.labels
  description     = each.value.backup.description
  type            = each.value.backup.type
  deletion_policy = each.value.backup.deletion_policy

  dynamic "encryption_config" {
    for_each = each.value.backup.encryption_config != null ? [each.value.backup.encryption_config] : []

    content {
      kms_key_name = encryption_config.value.kms_key_name
    }
  }

  depends_on = [google_alloydb_instance.instance]
}
