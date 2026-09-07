locals {
  disks = merge([
    for k, i in var.instances : {
      for idx, d in i.disks : "${k}/${idx}" => {
        instance_key = k
        name         = d.name
        size         = d.size
        type         = d.type
        description  = d.description
        labels       = d.labels
        mode         = d.mode
        device_name  = d.device_name
      }
    }
  ]...)

  iam_bindings = {
    for b in flatten([
      for key, instance in var.instances : [
        for binding_key, binding in instance.iam_role_bindings : {
          instance_key = key
          binding_key  = binding_key
          name         = instance.name
          zone         = instance.zone
          project_id   = instance.project_id
          role         = binding.role
          members      = binding.members
          condition    = binding.condition
        }
      ]
    ]) : "${b.instance_key}/${b.binding_key}" => b
  }
}

resource "google_compute_instance" "instance" {
  for_each = var.instances

  name                      = each.value.name
  machine_type              = each.value.machine_type
  zone                      = each.value.zone
  project                   = each.value.project_id
  description               = each.value.description
  hostname                  = each.value.hostname
  can_ip_forward            = each.value.can_ip_forward
  allow_stopping_for_update = each.value.allow_stopping_for_update
  deletion_protection       = each.value.deletion_protection
  min_cpu_platform          = each.value.min_cpu_platform
  tags                      = each.value.tags
  labels                    = each.value.labels
  metadata                  = each.value.metadata
  metadata_startup_script   = each.value.metadata_startup_script

  boot_disk {
    source      = each.value.boot_disk.source
    auto_delete = each.value.boot_disk.auto_delete
    device_name = each.value.boot_disk.device_name
    mode        = each.value.boot_disk.mode

    dynamic "initialize_params" {
      for_each = each.value.boot_disk.image != null ? [each.value.boot_disk] : []

      content {
        image  = initialize_params.value.image
        labels = initialize_params.value.labels
        size   = initialize_params.value.size
        type   = initialize_params.value.type
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

  lifecycle {
    ignore_changes = [attached_disk]
  }
}

resource "google_compute_disk" "disk" {
  for_each = local.disks

  name        = each.value.name
  project     = var.instances[each.value.instance_key].project_id
  type        = each.value.type
  zone        = var.instances[each.value.instance_key].zone
  size        = each.value.size
  description = each.value.description
  labels      = each.value.labels
}

resource "google_compute_attached_disk" "attached" {
  for_each = local.disks

  disk        = google_compute_disk.disk[each.key].self_link
  instance    = google_compute_instance.instance[each.value.instance_key].self_link
  mode        = each.value.mode
  device_name = each.value.device_name
  zone        = var.instances[each.value.instance_key].zone
  project     = var.instances[each.value.instance_key].project_id
}

resource "google_compute_instance_iam_binding" "binding" {
  for_each = local.iam_bindings

  instance_name = each.value.name
  zone          = each.value.zone
  project       = each.value.project_id
  role          = each.value.role
  members       = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_compute_instance.instance]
}
