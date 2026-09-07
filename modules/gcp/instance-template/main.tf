resource "google_compute_instance_template" "template" {
  for_each = var.templates

  name                    = each.value.name
  name_prefix             = each.value.name_prefix
  machine_type            = each.value.machine_type
  project                 = each.value.project_id
  region                  = each.value.region
  description             = each.value.description
  instance_description    = each.value.instance_description
  labels                  = each.value.labels
  metadata                = each.value.metadata
  metadata_startup_script = each.value.metadata_startup_script
  tags                    = each.value.tags
  can_ip_forward          = each.value.can_ip_forward
  min_cpu_platform        = each.value.min_cpu_platform
  resource_policies       = each.value.resource_policies

  lifecycle {
    create_before_destroy = true
  }

  dynamic "disk" {
    for_each = each.value.disks

    content {
      source_image           = disk.value.source_image
      source_snapshot        = disk.value.source_snapshot
      source                 = disk.value.source
      boot                   = disk.value.boot
      auto_delete            = disk.value.auto_delete
      device_name            = disk.value.device_name
      disk_name              = disk.value.disk_name
      disk_type              = disk.value.disk_type
      disk_size_gb           = disk.value.disk_size_gb
      mode                   = disk.value.mode
      interface              = disk.value.interface
      type                   = disk.value.type
      labels                 = disk.value.labels
      provisioned_iops       = disk.value.provisioned_iops
      provisioned_throughput = disk.value.provisioned_throughput
      resource_policies      = disk.value.resource_policies

      dynamic "source_image_encryption_key" {
        for_each = disk.value.source_image_encryption_key != null ? [disk.value.source_image_encryption_key] : []

        content {
          kms_key_self_link       = source_image_encryption_key.value.kms_key_self_link
          kms_key_service_account = source_image_encryption_key.value.kms_key_service_account
        }
      }

      dynamic "source_snapshot_encryption_key" {
        for_each = disk.value.source_snapshot_encryption_key != null ? [disk.value.source_snapshot_encryption_key] : []

        content {
          kms_key_self_link       = source_snapshot_encryption_key.value.kms_key_self_link
          kms_key_service_account = source_snapshot_encryption_key.value.kms_key_service_account
        }
      }

      dynamic "disk_encryption_key" {
        for_each = disk.value.disk_encryption_key != null ? [disk.value.disk_encryption_key] : []

        content {
          kms_key_self_link       = disk_encryption_key.value.kms_key_self_link
          kms_key_service_account = disk_encryption_key.value.kms_key_service_account
        }
      }
    }
  }

  dynamic "network_interface" {
    for_each = each.value.network_interfaces

    content {
      network            = network_interface.value.network
      subnetwork         = network_interface.value.subnetwork
      subnetwork_project = network_interface.value.subnetwork_project
      network_ip         = network_interface.value.network_ip
      nic_type           = network_interface.value.nic_type
      stack_type         = network_interface.value.stack_type
      queue_count        = network_interface.value.queue_count

      dynamic "access_config" {
        for_each = network_interface.value.access_config != null ? [network_interface.value.access_config] : []

        content {
          nat_ip       = access_config.value.nat_ip
          network_tier = access_config.value.network_tier
        }
      }

      dynamic "ipv6_access_config" {
        for_each = network_interface.value.ipv6_access_config != null ? [network_interface.value.ipv6_access_config] : []

        content {
          network_tier = ipv6_access_config.value.network_tier
        }
      }

      dynamic "alias_ip_range" {
        for_each = network_interface.value.alias_ip_ranges

        content {
          ip_cidr_range         = alias_ip_range.value.ip_cidr_range
          subnetwork_range_name = alias_ip_range.value.subnetwork_range_name
        }
      }
    }
  }

  dynamic "service_account" {
    for_each = each.value.service_account != null ? [each.value.service_account] : []

    content {
      email  = service_account.value.email
      scopes = service_account.value.scopes
    }
  }

  dynamic "scheduling" {
    for_each = each.value.scheduling != null ? [each.value.scheduling] : []

    content {
      automatic_restart           = scheduling.value.automatic_restart
      on_host_maintenance         = scheduling.value.on_host_maintenance
      preemptible                 = scheduling.value.preemptible
      provisioning_model          = scheduling.value.provisioning_model
      instance_termination_action = scheduling.value.instance_termination_action

      dynamic "node_affinities" {
        for_each = scheduling.value.node_affinities

        content {
          key      = node_affinities.value.key
          operator = node_affinities.value.operator
          values   = node_affinities.value.values
        }
      }
    }
  }

  dynamic "shielded_instance_config" {
    for_each = each.value.shielded_instance_config != null ? [each.value.shielded_instance_config] : []

    content {
      enable_secure_boot          = shielded_instance_config.value.enable_secure_boot
      enable_vtpm                 = shielded_instance_config.value.enable_vtpm
      enable_integrity_monitoring = shielded_instance_config.value.enable_integrity_monitoring
    }
  }

  dynamic "guest_accelerator" {
    for_each = each.value.guest_accelerators

    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }

  dynamic "advanced_machine_features" {
    for_each = each.value.advanced_machine_features != null ? [each.value.advanced_machine_features] : []

    content {
      enable_nested_virtualization = advanced_machine_features.value.enable_nested_virtualization
      threads_per_core             = advanced_machine_features.value.threads_per_core
      visible_core_count           = advanced_machine_features.value.visible_core_count
    }
  }

  dynamic "confidential_instance_config" {
    for_each = each.value.confidential_instance_config != null ? [each.value.confidential_instance_config] : []

    content {
      enable_confidential_compute = confidential_instance_config.value.enable_confidential_compute
      confidential_instance_type  = confidential_instance_config.value.confidential_instance_type
    }
  }

  dynamic "network_performance_config" {
    for_each = each.value.network_performance_config != null ? [each.value.network_performance_config] : []

    content {
      total_egress_bandwidth_tier = network_performance_config.value.total_egress_bandwidth_tier
    }
  }
}
