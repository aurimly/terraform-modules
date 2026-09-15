locals {
  cluster_iam_bindings = {
    for b in flatten([
      for cluster_key, cluster in var.clusters : [
        for binding_key, binding in cluster.role_bindings : {
          cluster_key  = cluster_key
          binding_key  = binding_key
          cluster_name = cluster.name
          region       = cluster.region
          binding      = binding
        }
      ]
    ]) : "${b.cluster_key}/${b.binding_key}" => b
  }

  cluster_ids = {
    for cluster_key, cluster in var.clusters : cluster_key =>
    "projects/${cluster.project_id}/regions/${cluster.region}/clusters/${cluster.name}"
    if cluster.project_id != null
  }
}

resource "google_dataproc_cluster" "cluster" {
  for_each = var.clusters

  name                          = each.value.name
  region                        = each.value.region
  project                       = each.value.project_id
  labels                        = each.value.labels
  deletion_policy               = each.value.deletion_policy
  graceful_decommission_timeout = each.value.graceful_decommission_timeout

  dynamic "cluster_config" {
    for_each = each.value.cluster_config != null ? [each.value.cluster_config] : []

    content {
      staging_bucket = cluster_config.value.staging_bucket
      temp_bucket    = cluster_config.value.temp_bucket
      cluster_tier   = cluster_config.value.cluster_tier
      engine         = cluster_config.value.engine

      dynamic "gce_cluster_config" {
        for_each = cluster_config.value.gce_cluster_config != null ? [cluster_config.value.gce_cluster_config] : []

        content {
          zone                   = gce_cluster_config.value.zone
          network                = gce_cluster_config.value.network
          subnetwork             = gce_cluster_config.value.subnetwork
          service_account        = gce_cluster_config.value.service_account
          service_account_scopes = gce_cluster_config.value.service_account_scopes
          tags                   = gce_cluster_config.value.tags
          internal_ip_only       = gce_cluster_config.value.internal_ip_only
          metadata               = gce_cluster_config.value.metadata

          dynamic "shielded_instance_config" {
            for_each = gce_cluster_config.value.shielded_instance_config != null ? [gce_cluster_config.value.shielded_instance_config] : []

            content {
              enable_secure_boot          = shielded_instance_config.value.enable_secure_boot
              enable_vtpm                 = shielded_instance_config.value.enable_vtpm
              enable_integrity_monitoring = shielded_instance_config.value.enable_integrity_monitoring
            }
          }
        }
      }

      dynamic "master_config" {
        for_each = cluster_config.value.master_config != null ? [cluster_config.value.master_config] : []

        content {
          num_instances    = master_config.value.num_instances
          machine_type     = master_config.value.machine_type
          min_cpu_platform = master_config.value.min_cpu_platform

          dynamic "disk_config" {
            for_each = master_config.value.disk_config != null ? [master_config.value.disk_config] : []

            content {
              boot_disk_type                   = disk_config.value.boot_disk_type
              boot_disk_size_gb                = disk_config.value.boot_disk_size_gb
              boot_disk_provisioned_iops       = disk_config.value.boot_disk_provisioned_iops
              boot_disk_provisioned_throughput = disk_config.value.boot_disk_provisioned_throughput
              num_local_ssds                   = disk_config.value.num_local_ssds
              local_ssd_interface              = disk_config.value.local_ssd_interface
            }
          }

          dynamic "accelerators" {
            for_each = master_config.value.accelerators

            content {
              accelerator_type  = accelerators.value.accelerator_type
              accelerator_count = accelerators.value.accelerator_count
            }
          }
        }
      }

      dynamic "worker_config" {
        for_each = cluster_config.value.worker_config != null ? [cluster_config.value.worker_config] : []

        content {
          num_instances     = worker_config.value.num_instances
          machine_type      = worker_config.value.machine_type
          min_cpu_platform  = worker_config.value.min_cpu_platform
          min_num_instances = worker_config.value.min_num_instances

          dynamic "disk_config" {
            for_each = worker_config.value.disk_config != null ? [worker_config.value.disk_config] : []

            content {
              boot_disk_type                   = disk_config.value.boot_disk_type
              boot_disk_size_gb                = disk_config.value.boot_disk_size_gb
              boot_disk_provisioned_iops       = disk_config.value.boot_disk_provisioned_iops
              boot_disk_provisioned_throughput = disk_config.value.boot_disk_provisioned_throughput
              num_local_ssds                   = disk_config.value.num_local_ssds
              local_ssd_interface              = disk_config.value.local_ssd_interface
            }
          }

          dynamic "accelerators" {
            for_each = worker_config.value.accelerators

            content {
              accelerator_type  = accelerators.value.accelerator_type
              accelerator_count = accelerators.value.accelerator_count
            }
          }
        }
      }

      dynamic "preemptible_worker_config" {
        for_each = cluster_config.value.preemptible_worker_config != null ? [cluster_config.value.preemptible_worker_config] : []

        content {
          num_instances  = preemptible_worker_config.value.num_instances
          preemptibility = preemptible_worker_config.value.preemptibility

          dynamic "disk_config" {
            for_each = preemptible_worker_config.value.disk_config != null ? [preemptible_worker_config.value.disk_config] : []

            content {
              boot_disk_type    = disk_config.value.boot_disk_type
              boot_disk_size_gb = disk_config.value.boot_disk_size_gb
              num_local_ssds    = disk_config.value.num_local_ssds
            }
          }
        }
      }

      dynamic "software_config" {
        for_each = cluster_config.value.software_config != null ? [cluster_config.value.software_config] : []

        content {
          image_version       = software_config.value.image_version
          override_properties = software_config.value.override_properties
          optional_components = software_config.value.optional_components
        }
      }

      dynamic "initialization_action" {
        for_each = cluster_config.value.initialization_actions

        content {
          script      = initialization_action.value.script
          timeout_sec = initialization_action.value.timeout_sec
        }
      }

      dynamic "encryption_config" {
        for_each = cluster_config.value.encryption_config != null ? [cluster_config.value.encryption_config] : []

        content {
          kms_key_name = encryption_config.value.kms_key_name
        }
      }

      dynamic "lifecycle_config" {
        for_each = cluster_config.value.lifecycle_config != null ? [cluster_config.value.lifecycle_config] : []

        content {
          idle_delete_ttl  = lifecycle_config.value.idle_delete_ttl
          auto_delete_time = lifecycle_config.value.auto_delete_time
        }
      }

      dynamic "autoscaling_config" {
        for_each = cluster_config.value.autoscaling_config != null ? [cluster_config.value.autoscaling_config] : []

        content {
          policy_uri = autoscaling_config.value.policy_uri
        }
      }
    }
  }
}

resource "google_dataproc_cluster_iam_binding" "binding" {
  for_each = local.cluster_iam_bindings

  cluster = each.value.cluster_name
  region  = each.value.region
  project = var.clusters[each.value.cluster_key].project_id
  role    = each.value.binding.role
  members = each.value.binding.members

  dynamic "condition" {
    for_each = each.value.binding.condition != null ? [each.value.binding.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}
