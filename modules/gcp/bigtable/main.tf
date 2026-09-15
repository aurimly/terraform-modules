locals {
  tables = {
    for e in flatten([
      for instance_key, instance in var.instances : [
        for table_key, table in instance.tables : {
          instance_key = instance_key
          table_key    = table_key
          instance     = instance
          table        = table
        }
      ]
    ]) : "${e.instance_key}/${e.table_key}" => e
  }

  profiles = {
    for e in flatten([
      for instance_key, instance in var.instances : [
        for profile_key, profile in instance.app_profiles : {
          instance_key = instance_key
          profile_key  = profile_key
          instance     = instance
          profile      = profile
        }
      ]
    ]) : "${e.instance_key}/${e.profile_key}" => e
  }

  gc_policies = {
    for e in flatten([
      for instance_key, instance in var.instances : [
        for table_key, table in instance.tables : [
          for family, policy in table.gc_policies : {
            instance_key = instance_key
            table_key    = table_key
            family       = family
            policy       = policy
          }
        ]
      ]
    ]) : "${e.instance_key}/${e.table_key}/${e.family}" => e
  }

  instance_iam_bindings = {
    for b in flatten([
      for instance_key, instance in var.instances : [
        for binding_key, binding in instance.role_bindings : {
          instance_key  = instance_key
          binding_key   = binding_key
          instance_name = instance.name
          binding       = binding
        }
      ]
    ]) : "${b.instance_key}/${b.binding_key}" => b
  }

  table_iam_bindings = {
    for b in flatten([
      for instance_key, instance in var.instances : [
        for table_key, table in instance.tables : [
          for binding_key, binding in table.role_bindings : {
            instance_key = instance_key
            table_key    = table_key
            binding_key  = binding_key
            instance     = instance
            binding      = binding
          }
        ]
      ]
    ]) : "${b.instance_key}/${b.table_key}/${b.binding_key}" => b
  }
}

resource "google_bigtable_instance" "instance" {
  for_each = var.instances

  name                = each.value.name
  project             = each.value.project_id
  display_name        = each.value.display_name
  labels              = each.value.labels
  edition             = each.value.edition
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
  force_destroy       = each.value.force_destroy

  dynamic "cluster" {
    for_each = each.value.clusters

    content {
      cluster_id          = cluster.value.cluster_id
      zone                = cluster.value.zone
      num_nodes           = cluster.value.num_nodes
      storage_type        = cluster.value.storage_type
      kms_key_name        = cluster.value.kms_key_name
      node_scaling_factor = cluster.value.node_scaling_factor

      dynamic "autoscaling_config" {
        for_each = cluster.value.autoscaling_config != null ? [cluster.value.autoscaling_config] : []

        content {
          min_nodes      = autoscaling_config.value.min_nodes
          max_nodes      = autoscaling_config.value.max_nodes
          cpu_target     = autoscaling_config.value.cpu_target
          storage_target = autoscaling_config.value.storage_target
        }
      }
    }
  }
}

resource "google_bigtable_table" "table" {
  for_each = local.tables

  name                    = each.value.table.name
  instance_name           = google_bigtable_instance.instance[each.value.instance_key].name
  project                 = each.value.instance.project_id
  split_keys              = each.value.table.split_keys
  deletion_protection     = each.value.table.deletion_protection
  deletion_policy         = each.value.table.deletion_policy
  change_stream_retention = each.value.table.change_stream_retention

  dynamic "column_family" {
    for_each = each.value.table.column_families

    content {
      family = column_family.key
      type   = column_family.value.type
    }
  }

  dynamic "automated_backup_policy" {
    for_each = each.value.table.automated_backup_policy != null ? [each.value.table.automated_backup_policy] : []

    content {
      retention_period = automated_backup_policy.value.retention_period
      frequency        = automated_backup_policy.value.frequency
      locations        = automated_backup_policy.value.locations
    }
  }

  depends_on = [google_bigtable_instance.instance]
}

resource "google_bigtable_app_profile" "profile" {
  for_each = local.profiles

  instance        = google_bigtable_instance.instance[each.value.instance_key].name
  app_profile_id  = each.value.profile.app_profile_id
  project         = each.value.instance.project_id
  description     = each.value.profile.description
  ignore_warnings = each.value.profile.ignore_warnings
  deletion_policy = each.value.profile.deletion_policy

  multi_cluster_routing_use_any     = each.value.profile.multi_cluster_routing_use_any
  multi_cluster_routing_cluster_ids = each.value.profile.multi_cluster_routing_cluster_ids

  dynamic "single_cluster_routing" {
    for_each = each.value.profile.single_cluster_routing != null ? [each.value.profile.single_cluster_routing] : []

    content {
      cluster_id                 = single_cluster_routing.value.cluster_id
      allow_transactional_writes = single_cluster_routing.value.allow_transactional_writes
    }
  }

  dynamic "standard_isolation" {
    for_each = each.value.profile.standard_isolation != null ? [each.value.profile.standard_isolation] : []

    content {
      priority = standard_isolation.value.priority
    }
  }

  dynamic "data_boost_isolation_read_only" {
    for_each = each.value.profile.data_boost_isolation_read_only != null ? [each.value.profile.data_boost_isolation_read_only] : []

    content {
      compute_billing_owner = data_boost_isolation_read_only.value.compute_billing_owner
    }
  }

  depends_on = [google_bigtable_instance.instance]
}

resource "google_bigtable_gc_policy" "policy" {
  for_each = local.gc_policies

  instance_name   = google_bigtable_instance.instance[each.value.instance_key].name
  table           = google_bigtable_table.table["${each.value.instance_key}/${each.value.table_key}"].name
  project         = var.instances[each.value.instance_key].project_id
  column_family   = each.value.family
  mode            = each.value.policy.mode
  ignore_warnings = each.value.policy.ignore_warnings
  deletion_policy = each.value.policy.deletion_policy

  dynamic "max_age" {
    for_each = each.value.policy.max_age != null ? [each.value.policy.max_age] : []

    content {
      duration = max_age.value.duration
    }
  }

  dynamic "max_version" {
    for_each = each.value.policy.max_version != null ? [each.value.policy.max_version] : []

    content {
      number = max_version.value.number
    }
  }

  gc_rules = each.value.policy.gc_rules

  depends_on = [google_bigtable_table.table]
}

resource "google_bigtable_instance_iam_binding" "binding" {
  for_each = local.instance_iam_bindings

  instance = google_bigtable_instance.instance[each.value.instance_key].name
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

resource "google_bigtable_table_iam_binding" "binding" {
  for_each = local.table_iam_bindings

  instance_name = google_bigtable_instance.instance[each.value.instance_key].name
  project       = var.instances[each.value.instance_key].project_id
  table         = google_bigtable_table.table["${each.value.instance_key}/${each.value.table_key}"].name
  role          = each.value.binding.role
  members       = each.value.binding.members

  dynamic "condition" {
    for_each = each.value.binding.condition != null ? [each.value.binding.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}
