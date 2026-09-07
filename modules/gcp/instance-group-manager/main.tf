resource "google_compute_instance_group_manager" "manager" {
  for_each = var.managers

  name                           = each.value.name
  base_instance_name             = each.value.base_instance_name
  zone                           = each.value.zone
  project                        = each.value.project_id
  description                    = each.value.description
  deletion_policy                = each.value.deletion_policy
  target_size                    = each.value.target_size
  target_pools                   = each.value.target_pools
  wait_for_instances             = each.value.wait_for_instances
  wait_for_instances_status      = each.value.wait_for_instances_status
  list_managed_instances_results = each.value.list_managed_instances_results
  target_stopped_size            = each.value.target_stopped_size
  target_suspended_size          = each.value.target_suspended_size

  dynamic "version" {
    for_each = each.value.versions

    content {
      name              = version.value.name
      instance_template = version.value.instance_template

      dynamic "target_size" {
        for_each = version.value.target_size != null ? [version.value.target_size] : []

        content {
          fixed   = target_size.value.fixed
          percent = target_size.value.percent
        }
      }
    }
  }

  dynamic "named_port" {
    for_each = each.value.named_ports

    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }

  dynamic "auto_healing_policies" {
    for_each = each.value.auto_healing_policies != null ? [each.value.auto_healing_policies] : []

    content {
      health_check      = auto_healing_policies.value.health_check
      initial_delay_sec = auto_healing_policies.value.initial_delay_sec
    }
  }

  dynamic "all_instances_config" {
    for_each = each.value.all_instances_config != null ? [each.value.all_instances_config] : []

    content {
      metadata = all_instances_config.value.metadata
      labels   = all_instances_config.value.labels
    }
  }

  dynamic "stateful_disk" {
    for_each = each.value.stateful_disks

    content {
      device_name = stateful_disk.value.device_name
      delete_rule = stateful_disk.value.delete_rule
    }
  }

  dynamic "stateful_internal_ip" {
    for_each = each.value.stateful_internal_ips

    content {
      interface_name = stateful_internal_ip.value.interface_name
      delete_rule    = stateful_internal_ip.value.delete_rule
    }
  }

  dynamic "stateful_external_ip" {
    for_each = each.value.stateful_external_ips

    content {
      interface_name = stateful_external_ip.value.interface_name
      delete_rule    = stateful_external_ip.value.delete_rule
    }
  }

  dynamic "update_policy" {
    for_each = each.value.update_policy != null ? [each.value.update_policy] : []

    content {
      type                           = update_policy.value.type
      minimal_action                 = update_policy.value.minimal_action
      most_disruptive_allowed_action = update_policy.value.most_disruptive_allowed_action
      max_surge_fixed                = update_policy.value.max_surge_fixed
      max_surge_percent              = update_policy.value.max_surge_percent
      max_unavailable_fixed          = update_policy.value.max_unavailable_fixed
      max_unavailable_percent        = update_policy.value.max_unavailable_percent
      replacement_method             = update_policy.value.replacement_method
    }
  }

  dynamic "instance_lifecycle_policy" {
    for_each = each.value.instance_lifecycle_policy != null ? [each.value.instance_lifecycle_policy] : []

    content {
      force_update_on_repair    = instance_lifecycle_policy.value.force_update_on_repair
      default_action_on_failure = instance_lifecycle_policy.value.default_action_on_failure
      on_failed_health_check    = instance_lifecycle_policy.value.on_failed_health_check

      dynamic "on_repair" {
        for_each = instance_lifecycle_policy.value.on_repair != null ? [instance_lifecycle_policy.value.on_repair] : []

        content {
          allow_changing_zone = on_repair.value.allow_changing_zone
        }
      }
    }
  }

  dynamic "standby_policy" {
    for_each = each.value.standby_policy != null ? [each.value.standby_policy] : []

    content {
      initial_delay_sec = standby_policy.value.initial_delay_sec
      mode              = standby_policy.value.mode
    }
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  for_each = { for k, m in var.managers : k => m if m.autoscaler != null }

  name            = coalesce(each.value.autoscaler.name, each.value.name)
  description     = each.value.autoscaler.description
  target          = google_compute_instance_group_manager.manager[each.key].self_link
  zone            = each.value.zone
  project         = each.value.project_id
  deletion_policy = each.value.autoscaler.deletion_policy

  autoscaling_policy {
    min_replicas         = each.value.autoscaler.autoscaling_policy.min_replicas
    max_replicas         = each.value.autoscaler.autoscaling_policy.max_replicas
    cooldown_period      = each.value.autoscaler.autoscaling_policy.cooldown_period
    stabilization_period = each.value.autoscaler.autoscaling_policy.stabilization_period
    mode                 = each.value.autoscaler.autoscaling_policy.mode

    dynamic "cpu_utilization" {
      for_each = each.value.autoscaler.autoscaling_policy.cpu_utilization != null ? [each.value.autoscaler.autoscaling_policy.cpu_utilization] : []

      content {
        target            = cpu_utilization.value.target
        predictive_method = cpu_utilization.value.predictive_method
      }
    }

    dynamic "metric" {
      for_each = each.value.autoscaler.autoscaling_policy.metric

      content {
        name                       = metric.value.name
        target                     = metric.value.target
        single_instance_assignment = metric.value.single_instance_assignment
        type                       = metric.value.type
        filter                     = metric.value.filter
      }
    }

    dynamic "load_balancing_utilization" {
      for_each = each.value.autoscaler.autoscaling_policy.load_balancing_utilization != null ? [each.value.autoscaler.autoscaling_policy.load_balancing_utilization] : []

      content {
        target = load_balancing_utilization.value.target
      }
    }

    dynamic "scaling_schedules" {
      for_each = each.value.autoscaler.autoscaling_policy.scaling_schedules

      content {
        name                  = scaling_schedules.value.name
        min_required_replicas = scaling_schedules.value.min_required_replicas
        schedule              = scaling_schedules.value.schedule
        duration_sec          = scaling_schedules.value.duration_sec
        time_zone             = scaling_schedules.value.time_zone
        disabled              = scaling_schedules.value.disabled
        description           = scaling_schedules.value.description
      }
    }

    dynamic "scale_in_control" {
      for_each = each.value.autoscaler.autoscaling_policy.scale_in_control != null ? [each.value.autoscaler.autoscaling_policy.scale_in_control] : []

      content {
        time_window_sec = scale_in_control.value.time_window_sec

        dynamic "max_scaled_in_replicas" {
          for_each = scale_in_control.value.max_scaled_in_replicas != null ? [scale_in_control.value.max_scaled_in_replicas] : []

          content {
            fixed   = max_scaled_in_replicas.value.fixed
            percent = max_scaled_in_replicas.value.percent
          }
        }
      }
    }
  }
}
