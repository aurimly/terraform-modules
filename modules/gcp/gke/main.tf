locals {
  node_pools = merge([for ck, c in var.clusters : { for p in c.node_pools : "${ck}/${p.name}" => {
    cluster_key = ck
    cluster     = c
    pool        = p
  } }]...)

  backup_plans = merge([for ck, c in var.clusters : { for b in c.backup_plans : "${ck}/${b.name}" => {
    cluster_key = ck
    cluster     = c
    plan        = b
  } }]...)
}

resource "google_container_cluster" "cluster" {
  for_each = var.clusters

  name                      = each.value.name
  project                   = each.value.project_id
  description               = each.value.description
  location                  = each.value.location
  deletion_protection       = each.value.deletion_protection
  default_max_pods_per_node = each.value.default_max_pods_per_node
  resource_labels           = each.value.resource_labels
  network                   = each.value.network
  subnetwork                = each.value.subnetwork

  # The default pool is a throwaway bootstrap pool: it is removed right after
  # cluster creation and node pools are managed via google_container_node_pool.
  remove_default_node_pool = each.value.enable_autopilot == true ? null : true
  initial_node_count       = each.value.enable_autopilot == true ? null : 1

  # Secure boot keeps the one-node bootstrap pool alive under org policies
  # that enforce Shielded VM settings; the pool is deleted immediately after.
  dynamic "node_config" {
    for_each = each.value.enable_autopilot == true ? [] : [1]

    content {
      shielded_instance_config {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }

  enable_autopilot = each.value.enable_autopilot

  dynamic "release_channel" {
    for_each = each.value.release_channel != null ? [each.value.release_channel] : []

    content {
      channel = release_channel.value.channel
    }
  }

  dynamic "gateway_api_config" {
    for_each = each.value.gateway_api_channel != null ? [each.value.gateway_api_channel] : []

    content {
      channel = gateway_api_config.value
    }
  }

  dynamic "workload_identity_config" {
    for_each = each.value.workload_identity == true ? [1] : []

    content {
      workload_pool = "${each.value.project_id}.svc.id.goog"
    }
  }

  min_master_version = each.value.min_master_version

  dynamic "maintenance_policy" {
    for_each = each.value.daily_maintenance_window != null ? [each.value.daily_maintenance_window] : []

    content {
      daily_maintenance_window {
        start_time = maintenance_policy.value.start_time
      }
    }
  }

  dynamic "maintenance_policy" {
    for_each = each.value.recurring_maintenance_window != null ? [each.value.recurring_maintenance_window] : []

    content {
      recurring_window {
        start_time = maintenance_policy.value.start_time
        end_time   = maintenance_policy.value.end_time
        recurrence = maintenance_policy.value.recurrence
      }
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = each.value.ip_allocation_policy != null ? each.value.ip_allocation_policy.cluster_secondary_range_name : null
    services_secondary_range_name = each.value.ip_allocation_policy != null ? each.value.ip_allocation_policy.services_secondary_range_name : null
  }

  dynamic "master_authorized_networks_config" {
    for_each = each.value.master_authorized_networks_config != null ? [each.value.master_authorized_networks_config] : []

    content {
      dynamic "cidr_blocks" {
        for_each = master_authorized_networks_config.value.cidr_blocks

        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  dynamic "private_cluster_config" {
    for_each = each.value.private_cluster_config != null ? [each.value.private_cluster_config] : []

    content {
      enable_private_nodes    = private_cluster_config.value.enable_private_nodes
      enable_private_endpoint = private_cluster_config.value.enable_private_endpoint
      master_ipv4_cidr_block  = private_cluster_config.value.master_ipv4_cidr_block

      dynamic "master_global_access_config" {
        for_each = private_cluster_config.value.master_global_access_config != null ? [private_cluster_config.value.master_global_access_config] : []

        content {
          enabled = master_global_access_config.value.enabled
        }
      }
    }
  }

  dynamic "network_policy" {
    for_each = each.value.network_policy != null ? [each.value.network_policy] : []

    content {
      enabled  = network_policy.value.enabled
      provider = network_policy.value.provider
    }
  }

  dynamic "addons_config" {
    for_each = each.value.addons_config != null ? [each.value.addons_config] : []

    content {
      dynamic "horizontal_pod_autoscaling" {
        for_each = addons_config.value.horizontal_pod_autoscaling != null ? [addons_config.value.horizontal_pod_autoscaling] : []

        content {
          disabled = horizontal_pod_autoscaling.value.disabled
        }
      }

      dynamic "http_load_balancing" {
        for_each = addons_config.value.http_load_balancing != null ? [addons_config.value.http_load_balancing] : []

        content {
          disabled = http_load_balancing.value.disabled
        }
      }

      dynamic "gcs_fuse_csi_driver_config" {
        for_each = addons_config.value.gcs_fuse_csi_driver_config != null ? [addons_config.value.gcs_fuse_csi_driver_config] : []

        content {
          enabled = gcs_fuse_csi_driver_config.value.enabled
        }
      }

      dynamic "gcp_filestore_csi_driver_config" {
        for_each = addons_config.value.gcp_filestore_csi_driver_config != null ? [addons_config.value.gcp_filestore_csi_driver_config] : []

        content {
          enabled = gcp_filestore_csi_driver_config.value.enabled
        }
      }

      dynamic "gke_backup_agent_config" {
        for_each = addons_config.value.gke_backup_agent_config != null ? [addons_config.value.gke_backup_agent_config] : []

        content {
          enabled = gke_backup_agent_config.value.enabled
        }
      }
    }
  }

  dynamic "vertical_pod_autoscaling" {
    for_each = each.value.vertical_pod_autoscaling != null ? [each.value.vertical_pod_autoscaling] : []

    content {
      enabled = vertical_pod_autoscaling.value.enabled
    }
  }

  datapath_provider                        = each.value.datapath_provider
  enable_shielded_nodes                    = each.value.enable_shielded_nodes
  enable_intranode_visibility              = each.value.enable_intranode_visibility
  enable_l4_ilb_subsetting                 = each.value.enable_l4_ilb_subsetting
  enable_fqdn_network_policy               = each.value.enable_fqdn_network_policy
  enable_multi_networking                  = each.value.enable_multi_networking
  enable_cilium_clusterwide_network_policy = each.value.enable_cilium_clusterwide_network_policy
  disable_l4_lb_firewall_reconciliation    = each.value.disable_l4_lb_firewall_reconciliation

  logging_service = each.value.logging_service

  dynamic "logging_config" {
    for_each = each.value.logging_config != null ? [each.value.logging_config] : []

    content {
      enable_components = logging_config.value.enable_components
    }
  }

  monitoring_service = each.value.monitoring_service

  dynamic "monitoring_config" {
    for_each = each.value.monitoring_config != null ? [each.value.monitoring_config] : []

    content {
      enable_components = monitoring_config.value.enable_components

      dynamic "managed_prometheus" {
        for_each = monitoring_config.value.managed_prometheus != null ? [monitoring_config.value.managed_prometheus] : []

        content {
          enabled = managed_prometheus.value.enabled
        }
      }

      dynamic "advanced_datapath_observability_config" {
        for_each = monitoring_config.value.advanced_datapath_observability_config != null ? [monitoring_config.value.advanced_datapath_observability_config] : []

        content {
          enable_metrics = advanced_datapath_observability_config.value.enable_metrics
          enable_relay   = advanced_datapath_observability_config.value.enable_relay
        }
      }
    }
  }

  dynamic "dns_config" {
    for_each = each.value.dns_config != null ? [each.value.dns_config] : []

    content {
      cluster_dns                   = dns_config.value.cluster_dns
      cluster_dns_scope             = dns_config.value.cluster_dns_scope
      cluster_dns_domain            = dns_config.value.cluster_dns_domain
      additive_vpc_scope_dns_domain = dns_config.value.additive_vpc_scope_dns_domain
    }
  }

  dynamic "security_posture_config" {
    for_each = each.value.security_posture_config != null ? [each.value.security_posture_config] : []

    content {
      mode               = security_posture_config.value.mode
      vulnerability_mode = security_posture_config.value.vulnerability_mode
    }
  }

  dynamic "binary_authorization" {
    for_each = each.value.binary_authorization != null ? [each.value.binary_authorization] : []

    content {
      evaluation_mode = binary_authorization.value.evaluation_mode
    }
  }

  dynamic "confidential_nodes" {
    for_each = each.value.confidential_nodes != null ? [each.value.confidential_nodes] : []

    content {
      enabled = confidential_nodes.value.enabled
    }
  }

  dynamic "service_external_ips_config" {
    for_each = each.value.service_external_ips_config != null ? [each.value.service_external_ips_config] : []

    content {
      enabled = service_external_ips_config.value.enabled
    }
  }

  dynamic "authenticator_groups_config" {
    for_each = each.value.authenticator_groups_config != null ? [each.value.authenticator_groups_config] : []

    content {
      security_group = authenticator_groups_config.value.security_group
    }
  }

  dynamic "notification_config" {
    for_each = each.value.notification_config != null ? [each.value.notification_config] : []

    content {
      pubsub {
        enabled = notification_config.value.pubsub.enabled
        topic   = notification_config.value.pubsub.topic

        dynamic "filter" {
          for_each = notification_config.value.pubsub.filter != null ? [notification_config.value.pubsub.filter] : []

          content {
            event_type = filter.value.event_type
          }
        }
      }
    }
  }

  dynamic "cost_management_config" {
    for_each = each.value.cost_management_config != null ? [each.value.cost_management_config] : []

    content {
      enabled = cost_management_config.value.enabled
    }
  }

  dynamic "database_encryption" {
    for_each = each.value.database_encryption != null ? [each.value.database_encryption] : []

    content {
      state    = database_encryption.value.state
      key_name = database_encryption.value.key_name
    }
  }

  dynamic "resource_usage_export_config" {
    for_each = each.value.resource_usage_export_config != null ? [each.value.resource_usage_export_config] : []

    content {
      enable_network_egress_metering       = resource_usage_export_config.value.enable_network_egress_metering
      enable_resource_consumption_metering = resource_usage_export_config.value.enable_resource_consumption_metering

      bigquery_destination {
        dataset_id = resource_usage_export_config.value.bigquery_destination.dataset_id
      }
    }
  }

  dynamic "node_pool_auto_config" {
    for_each = each.value.node_pool_auto_config != null ? [each.value.node_pool_auto_config] : []

    content {
      dynamic "network_tags" {
        for_each = node_pool_auto_config.value.network_tags != null ? [node_pool_auto_config.value.network_tags] : []

        content {
          tags = network_tags.value.tags
        }
      }

      resource_manager_tags = node_pool_auto_config.value.resource_manager_tags

      dynamic "node_kubelet_config" {
        for_each = node_pool_auto_config.value.node_kubelet_config != null ? [node_pool_auto_config.value.node_kubelet_config] : []

        content {
          insecure_kubelet_readonly_port_enabled = node_kubelet_config.value.insecure_kubelet_readonly_port_enabled
        }
      }

      dynamic "linux_node_config" {
        for_each = node_pool_auto_config.value.linux_node_config != null ? [node_pool_auto_config.value.linux_node_config] : []

        content {
          cgroup_mode = linux_node_config.value.cgroup_mode
        }
      }
    }
  }

  dynamic "node_pool_defaults" {
    for_each = each.value.node_pool_defaults != null ? [each.value.node_pool_defaults] : []

    content {
      dynamic "node_config_defaults" {
        for_each = node_pool_defaults.value.node_config_defaults != null ? [node_pool_defaults.value.node_config_defaults] : []

        content {
          insecure_kubelet_readonly_port_enabled = node_config_defaults.value.insecure_kubelet_readonly_port_enabled
          logging_variant                        = node_config_defaults.value.logging_variant

          dynamic "gcfs_config" {
            for_each = node_config_defaults.value.gcfs_config != null ? [node_config_defaults.value.gcfs_config] : []

            content {
              enabled = gcfs_config.value.enabled
            }
          }
        }
      }
    }
  }

  dynamic "cluster_autoscaling" {
    for_each = each.value.cluster_autoscaling != null ? [each.value.cluster_autoscaling] : []

    content {
      enabled = cluster_autoscaling.value.enabled

      dynamic "resource_limits" {
        for_each = cluster_autoscaling.value.resource_limits

        content {
          resource_type = resource_limits.value.resource_type
          minimum       = resource_limits.value.minimum
          maximum       = resource_limits.value.maximum
        }
      }

      dynamic "auto_provisioning_defaults" {
        for_each = cluster_autoscaling.value.auto_provisioning_defaults != null ? [cluster_autoscaling.value.auto_provisioning_defaults] : []

        content {
          service_account = auto_provisioning_defaults.value.service_account
        }
      }
    }
  }

  dynamic "secret_manager_config" {
    for_each = each.value.secret_manager_config != null ? [each.value.secret_manager_config] : []

    content {
      enabled = secret_manager_config.value.enabled

      dynamic "rotation_config" {
        for_each = secret_manager_config.value.rotation_config != null ? [secret_manager_config.value.rotation_config] : []

        content {
          enabled           = rotation_config.value.enabled
          rotation_interval = rotation_config.value.rotation_interval
        }
      }
    }
  }

  dynamic "fleet" {
    for_each = each.value.fleet != null ? [each.value.fleet] : []

    content {
      project = fleet.value.project
    }
  }

  dynamic "control_plane_endpoints_config" {
    for_each = each.value.control_plane_endpoints_config != null ? [each.value.control_plane_endpoints_config] : []

    content {
      dynamic "dns_endpoint_config" {
        for_each = control_plane_endpoints_config.value.dns_endpoint_config != null ? [control_plane_endpoints_config.value.dns_endpoint_config] : []

        content {
          allow_external_traffic = dns_endpoint_config.value.allow_external_traffic
        }
      }
    }
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }

  # initial_node_count and node_config only shape the throwaway default pool;
  # ignoring them avoids permadiffs once the pool is gone.
  lifecycle {
    ignore_changes = [initial_node_count, node_config]
  }
}

resource "google_container_node_pool" "node_pool" {
  depends_on = [google_container_cluster.cluster]

  for_each = local.node_pools

  name     = each.value.pool.name
  project  = each.value.cluster.project_id
  cluster  = each.value.cluster.name
  location = each.value.cluster.location

  # node_count is dropped when autoscaling manages the pool size.
  node_count = each.value.pool.autoscaling != null ? null : each.value.pool.node_count

  node_locations    = each.value.pool.node_locations
  max_pods_per_node = each.value.pool.max_pods_per_node

  dynamic "autoscaling" {
    for_each = each.value.pool.autoscaling != null ? [each.value.pool.autoscaling] : []

    content {
      min_node_count       = autoscaling.value.min_node_count
      max_node_count       = autoscaling.value.max_node_count
      total_min_node_count = autoscaling.value.total_min_node_count
      total_max_node_count = autoscaling.value.total_max_node_count
      location_policy      = autoscaling.value.location_policy
    }
  }

  dynamic "management" {
    for_each = each.value.pool.management != null ? [each.value.pool.management] : []

    content {
      auto_repair  = management.value.auto_repair
      auto_upgrade = management.value.auto_upgrade
    }
  }

  dynamic "upgrade_settings" {
    for_each = each.value.pool.upgrade_settings != null ? [each.value.pool.upgrade_settings] : []

    content {
      max_surge       = upgrade_settings.value.max_surge
      max_unavailable = upgrade_settings.value.max_unavailable
    }
  }

  dynamic "node_config" {
    for_each = each.value.pool.node_config != null ? [each.value.pool.node_config] : []

    content {
      image_type       = node_config.value.image_type
      machine_type     = node_config.value.machine_type
      min_cpu_platform = node_config.value.min_cpu_platform
      disk_size_gb     = node_config.value.disk_size_gb
      disk_type        = node_config.value.disk_type
      preemptible      = node_config.value.preemptible
      spot             = node_config.value.spot
      service_account  = node_config.value.service_account
      oauth_scopes     = node_config.value.oauth_scopes
      tags             = node_config.value.tags
      labels           = node_config.value.labels
      metadata         = node_config.value.metadata

      dynamic "taint" {
        for_each = node_config.value.taints

        content {
          key    = taint.value.key
          value  = taint.value.value
          effect = taint.value.effect
        }
      }

      dynamic "shielded_instance_config" {
        for_each = node_config.value.shielded_instance_config != null ? [node_config.value.shielded_instance_config] : []

        content {
          enable_secure_boot          = shielded_instance_config.value.enable_secure_boot
          enable_integrity_monitoring = shielded_instance_config.value.enable_integrity_monitoring
        }
      }

      dynamic "workload_metadata_config" {
        for_each = node_config.value.workload_metadata_config != null ? [node_config.value.workload_metadata_config] : []

        content {
          mode = workload_metadata_config.value.mode
        }
      }

      dynamic "guest_accelerator" {
        for_each = node_config.value.guest_accelerators

        content {
          type               = guest_accelerator.value.type
          count              = guest_accelerator.value.count
          gpu_partition_size = guest_accelerator.value.gpu_partition_size

          dynamic "gpu_driver_installation_config" {
            for_each = guest_accelerator.value.gpu_driver_installation_config != null ? [guest_accelerator.value.gpu_driver_installation_config] : []

            content {
              gpu_driver_version = gpu_driver_installation_config.value.gpu_driver_version
            }
          }

          dynamic "gpu_sharing_config" {
            for_each = guest_accelerator.value.gpu_sharing_config != null ? [guest_accelerator.value.gpu_sharing_config] : []

            content {
              gpu_sharing_strategy       = gpu_sharing_config.value.gpu_sharing_strategy
              max_shared_clients_per_gpu = gpu_sharing_config.value.max_shared_clients_per_gpu
            }
          }
        }
      }
    }
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

resource "google_gke_backup_backup_plan" "backup_plan" {
  for_each = local.backup_plans

  name        = each.value.plan.name
  cluster     = google_container_cluster.cluster[each.value.cluster_key].id
  location    = each.value.cluster.location
  project     = each.value.cluster.project_id
  description = each.value.plan.description
  deactivated = each.value.plan.deactivated
  labels      = each.value.plan.labels

  dynamic "retention_policy" {
    for_each = each.value.plan.retention_policy != null ? [each.value.plan.retention_policy] : []

    content {
      backup_delete_lock_days = retention_policy.value.backup_delete_lock_days
      backup_retain_days      = retention_policy.value.backup_retain_days
      locked                  = retention_policy.value.locked
    }
  }

  dynamic "backup_schedule" {
    for_each = each.value.plan.backup_schedule != null ? [each.value.plan.backup_schedule] : []

    content {
      cron_schedule = backup_schedule.value.cron_schedule
      paused        = backup_schedule.value.paused

      dynamic "rpo_config" {
        for_each = backup_schedule.value.rpo_config != null ? [backup_schedule.value.rpo_config] : []

        content {
          target_rpo_minutes = rpo_config.value.target_rpo_minutes

          dynamic "exclusion_windows" {
            for_each = rpo_config.value.exclusion_windows

            content {
              duration = exclusion_windows.value.duration

              dynamic "start_time" {
                for_each = exclusion_windows.value.start_time != null ? [exclusion_windows.value.start_time] : []

                content {
                  hours   = start_time.value.hours
                  minutes = start_time.value.minutes
                  seconds = start_time.value.seconds
                  nanos   = start_time.value.nanos
                }
              }

              dynamic "single_occurrence_date" {
                for_each = exclusion_windows.value.single_occurrence_date != null ? [exclusion_windows.value.single_occurrence_date] : []

                content {
                  day   = single_occurrence_date.value.day
                  month = single_occurrence_date.value.month
                  year  = single_occurrence_date.value.year
                }
              }

              dynamic "days_of_week" {
                for_each = exclusion_windows.value.days_of_week != null ? [exclusion_windows.value.days_of_week] : []

                content {
                  days_of_week = days_of_week.value.days_of_week
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "backup_config" {
    for_each = each.value.plan.backup_config != null ? [each.value.plan.backup_config] : []

    content {
      include_volume_data = backup_config.value.include_volume_data
      include_secrets     = backup_config.value.include_secrets
      all_namespaces      = backup_config.value.all_namespaces
      permissive_mode     = backup_config.value.permissive_mode

      dynamic "encryption_key" {
        for_each = backup_config.value.encryption_key != null ? [backup_config.value.encryption_key] : []

        content {
          gcp_kms_encryption_key = encryption_key.value.gcp_kms_encryption_key
        }
      }

      dynamic "selected_namespaces" {
        for_each = backup_config.value.selected_namespaces != null ? [backup_config.value.selected_namespaces] : []

        content {
          namespaces = selected_namespaces.value.namespaces
        }
      }

      dynamic "selected_applications" {
        for_each = backup_config.value.selected_applications != null ? [backup_config.value.selected_applications] : []

        content {
          dynamic "namespaced_names" {
            for_each = selected_applications.value.namespaced_names

            content {
              name      = namespaced_names.value.name
              namespace = namespaced_names.value.namespace
            }
          }
        }
      }
    }
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}
