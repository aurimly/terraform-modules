resource "google_composer_environment" "environment" {
  for_each = var.environments

  name            = each.value.name
  region          = each.value.region
  project         = each.value.project_id
  labels          = each.value.labels
  deletion_policy = each.value.deletion_policy

  dynamic "storage_config" {
    for_each = each.value.storage_config != null ? [each.value.storage_config] : []

    content {
      bucket = storage_config.value.bucket
    }
  }

  dynamic "config" {
    for_each = each.value.config != null ? [each.value.config] : []

    content {
      environment_size           = config.value.environment_size
      enable_private_environment = config.value.enable_private_environment
      enable_private_builds_only = config.value.enable_private_builds_only

      dynamic "node_config" {
        for_each = config.value.node_config != null ? [config.value.node_config] : []

        content {
          network                           = node_config.value.network
          subnetwork                        = node_config.value.subnetwork
          service_account                   = node_config.value.service_account
          tags                              = node_config.value.tags
          composer_network_attachment       = node_config.value.composer_network_attachment
          composer_internal_ipv4_cidr_block = node_config.value.composer_internal_ipv4_cidr_block
        }
      }

      dynamic "encryption_config" {
        for_each = config.value.encryption_config != null ? [config.value.encryption_config] : []

        content {
          kms_key_name = encryption_config.value.kms_key_name
        }
      }

      dynamic "maintenance_window" {
        for_each = config.value.maintenance_window != null ? [config.value.maintenance_window] : []

        content {
          start_time = maintenance_window.value.start_time
          end_time   = maintenance_window.value.end_time
          recurrence = maintenance_window.value.recurrence
        }
      }

      dynamic "software_config" {
        for_each = config.value.software_config != null ? [config.value.software_config] : []

        content {
          image_version            = software_config.value.image_version
          airflow_config_overrides = software_config.value.airflow_config_overrides
          pypi_packages            = software_config.value.pypi_packages
          env_variables            = software_config.value.env_variables
          web_server_plugins_mode  = software_config.value.web_server_plugins_mode

          dynamic "cloud_data_lineage_integration" {
            for_each = software_config.value.cloud_data_lineage_integration != null ? [software_config.value.cloud_data_lineage_integration] : []

            content {
              enabled = cloud_data_lineage_integration.value.enabled
            }
          }
        }
      }

      dynamic "workloads_config" {
        for_each = config.value.workloads_config != null ? [config.value.workloads_config] : []

        content {
          dynamic "scheduler" {
            for_each = workloads_config.value.scheduler != null ? [workloads_config.value.scheduler] : []

            content {
              cpu        = scheduler.value.cpu
              memory_gb  = scheduler.value.memory_gb
              storage_gb = scheduler.value.storage_gb
              count      = scheduler.value.count
            }
          }

          dynamic "triggerer" {
            for_each = workloads_config.value.triggerer != null ? [workloads_config.value.triggerer] : []

            content {
              cpu       = triggerer.value.cpu
              memory_gb = triggerer.value.memory_gb
              count     = triggerer.value.count
            }
          }

          dynamic "web_server" {
            for_each = workloads_config.value.web_server != null ? [workloads_config.value.web_server] : []

            content {
              cpu        = web_server.value.cpu
              memory_gb  = web_server.value.memory_gb
              storage_gb = web_server.value.storage_gb
            }
          }

          dynamic "worker" {
            for_each = workloads_config.value.worker != null ? [workloads_config.value.worker] : []

            content {
              cpu        = worker.value.cpu
              memory_gb  = worker.value.memory_gb
              storage_gb = worker.value.storage_gb
              min_count  = worker.value.min_count
              max_count  = worker.value.max_count
            }
          }

          dynamic "dag_processor" {
            for_each = workloads_config.value.dag_processor != null ? [workloads_config.value.dag_processor] : []

            content {
              cpu        = dag_processor.value.cpu
              memory_gb  = dag_processor.value.memory_gb
              storage_gb = dag_processor.value.storage_gb
              count      = dag_processor.value.count
            }
          }
        }
      }

      dynamic "recovery_config" {
        for_each = config.value.recovery_config != null ? [config.value.recovery_config] : []

        content {
          dynamic "scheduled_snapshots_config" {
            for_each = config.value.recovery_config.scheduled_snapshots_config != null ? [config.value.recovery_config.scheduled_snapshots_config] : []

            content {
              enabled                    = scheduled_snapshots_config.value.enabled
              snapshot_location          = scheduled_snapshots_config.value.snapshot_location
              snapshot_creation_schedule = scheduled_snapshots_config.value.snapshot_creation_schedule
              time_zone                  = scheduled_snapshots_config.value.time_zone
            }
          }
        }
      }

      dynamic "data_retention_config" {
        for_each = config.value.data_retention_config != null ? [config.value.data_retention_config] : []

        content {
          dynamic "airflow_metadata_retention_config" {
            for_each = config.value.data_retention_config.airflow_metadata_retention_config != null ? [config.value.data_retention_config.airflow_metadata_retention_config] : []

            content {
              retention_mode = airflow_metadata_retention_config.value.retention_mode
              retention_days = airflow_metadata_retention_config.value.retention_days
            }
          }
        }
      }
    }
  }
}
