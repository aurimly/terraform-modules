locals {
  databases = {
    for e in flatten([
      for instance_key, instance in var.instances : [
        for database_key, database in instance.databases : {
          instance_key = instance_key
          database_key = database_key
          instance     = instance
          database     = database
        }
      ]
    ]) : "${e.instance_key}/${e.database_key}" => e
  }

  instance_iam_bindings = {
    for b in flatten([
      for instance_key, instance in var.instances : [
        for binding_key, binding in instance.role_bindings : {
          instance_key = instance_key
          binding_key  = binding_key
          binding      = binding
        }
      ]
    ]) : "${b.instance_key}/${b.binding_key}" => b
  }

  database_iam_bindings = {
    for b in flatten([
      for instance_key, instance in var.instances : [
        for database_key, database in instance.databases : [
          for binding_key, binding in database.role_bindings : {
            instance_key = instance_key
            database_key = database_key
            binding_key  = binding_key
            binding      = binding
          }
        ]
      ]
    ]) : "${b.instance_key}/${b.database_key}/${b.binding_key}" => b
  }
}

resource "google_spanner_instance" "instance" {
  for_each = var.instances

  name                         = each.value.name
  project                      = each.value.project_id
  config                       = each.value.config
  display_name                 = each.value.display_name
  labels                       = each.value.labels
  edition                      = each.value.edition
  instance_type                = each.value.instance_type
  num_nodes                    = each.value.num_nodes
  processing_units             = each.value.processing_units
  default_backup_schedule_type = each.value.default_backup_schedule_type
  deletion_policy              = each.value.deletion_policy
  force_destroy                = each.value.force_destroy

  dynamic "autoscaling_config" {
    for_each = each.value.autoscaling_config != null ? [each.value.autoscaling_config] : []

    content {
      dynamic "autoscaling_limits" {
        for_each = autoscaling_config.value.autoscaling_limits != null ? [autoscaling_config.value.autoscaling_limits] : []

        content {
          min_nodes            = autoscaling_limits.value.min_nodes
          max_nodes            = autoscaling_limits.value.max_nodes
          min_processing_units = autoscaling_limits.value.min_processing_units
          max_processing_units = autoscaling_limits.value.max_processing_units
        }
      }

      dynamic "autoscaling_targets" {
        for_each = autoscaling_config.value.autoscaling_targets != null ? [autoscaling_config.value.autoscaling_targets] : []

        content {
          high_priority_cpu_utilization_percent = autoscaling_targets.value.high_priority_cpu_utilization_percent
          storage_utilization_percent           = autoscaling_targets.value.storage_utilization_percent
          total_cpu_utilization_percent         = autoscaling_targets.value.total_cpu_utilization_percent
        }
      }

      dynamic "asymmetric_autoscaling_options" {
        for_each = autoscaling_config.value.asymmetric_autoscaling_options != null ? autoscaling_config.value.asymmetric_autoscaling_options : {}

        content {
          dynamic "replica_selection" {
            for_each = [asymmetric_autoscaling_options.value.replica_selection]

            content {
              location = replica_selection.value.location
            }
          }

          dynamic "overrides" {
            for_each = [asymmetric_autoscaling_options.value.overrides]

            content {
              dynamic "autoscaling_limits" {
                for_each = overrides.value.autoscaling_limits != null ? [overrides.value.autoscaling_limits] : []

                content {
                  min_nodes            = autoscaling_limits.value.min_nodes
                  max_nodes            = autoscaling_limits.value.max_nodes
                  min_processing_units = autoscaling_limits.value.min_processing_units
                  max_processing_units = autoscaling_limits.value.max_processing_units
                }
              }

              autoscaling_target_high_priority_cpu_utilization_percent = overrides.value.autoscaling_target_high_priority_cpu_utilization_percent
              autoscaling_target_total_cpu_utilization_percent         = overrides.value.autoscaling_target_total_cpu_utilization_percent
              disable_high_priority_cpu_autoscaling                    = overrides.value.disable_high_priority_cpu_autoscaling
              disable_total_cpu_autoscaling                            = overrides.value.disable_total_cpu_autoscaling
            }
          }
        }
      }
    }
  }
}

resource "google_spanner_database" "database" {
  for_each = local.databases

  name                     = each.value.database.name
  instance                 = google_spanner_instance.instance[each.value.instance_key].name
  project                  = each.value.instance.project_id
  ddl                      = each.value.database.ddl
  version_retention_period = each.value.database.version_retention_period
  default_time_zone        = each.value.database.default_time_zone
  database_dialect         = each.value.database.database_dialect
  enable_drop_protection   = each.value.database.enable_drop_protection
  deletion_protection      = each.value.database.deletion_protection
  deletion_policy          = each.value.database.deletion_policy

  dynamic "encryption_config" {
    for_each = each.value.database.encryption_config != null ? [each.value.database.encryption_config] : []

    content {
      kms_key_name  = encryption_config.value.kms_key_name
      kms_key_names = encryption_config.value.kms_key_names
    }
  }

  depends_on = [google_spanner_instance.instance]
}

resource "google_spanner_instance_iam_binding" "binding" {
  for_each = local.instance_iam_bindings

  instance = google_spanner_instance.instance[each.value.instance_key].name
  project  = var.instances[each.value.instance_key].project_id
  role     = each.value.binding.role
  members  = each.value.binding.members

  dynamic "condition" {
    for_each = each.value.binding.condition != null ? [each.value.binding.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

resource "google_spanner_database_iam_binding" "binding" {
  for_each = local.database_iam_bindings

  instance = google_spanner_instance.instance[each.value.instance_key].name
  database = google_spanner_database.database["${each.value.instance_key}/${each.value.database_key}"].name
  project  = var.instances[each.value.instance_key].project_id
  role     = each.value.binding.role
  members  = each.value.binding.members

  dynamic "condition" {
    for_each = each.value.binding.condition != null ? [each.value.binding.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}
