locals {
  iam_bindings = {
    for b in flatten([
      for key, bucket in var.buckets : [
        for binding_key, binding in bucket.role_bindings : {
          bucket_key  = key
          binding_key = binding_key
          name        = bucket.name
          role        = binding.role
          members     = binding.members
          condition   = binding.condition
        }
      ]
    ]) : "${b.bucket_key}/${b.binding_key}" => b
  }
}

resource "google_storage_bucket" "bucket" {
  for_each = var.buckets

  name                        = each.value.name
  project                     = each.value.project_id
  location                    = each.value.location
  force_destroy               = each.value.force_destroy
  storage_class               = each.value.storage_class
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  public_access_prevention    = each.value.public_access_prevention
  requester_pays              = each.value.requester_pays
  rpo                         = each.value.rpo
  default_event_based_hold    = each.value.default_event_based_hold
  enable_object_retention     = each.value.enable_object_retention
  deletion_policy             = each.value.deletion_policy
  labels                      = each.value.labels

  dynamic "versioning" {
    for_each = each.value.versioning != null ? [each.value.versioning] : []

    content {
      enabled = versioning.value
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules

    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }

      condition {
        age                                     = lifecycle_rule.value.condition.age
        created_before                          = lifecycle_rule.value.condition.created_before
        with_state                              = lifecycle_rule.value.condition.with_state
        matches_storage_class                   = lifecycle_rule.value.condition.matches_storage_class
        matches_prefix                          = lifecycle_rule.value.condition.matches_prefix
        matches_suffix                          = lifecycle_rule.value.condition.matches_suffix
        num_newer_versions                      = lifecycle_rule.value.condition.num_newer_versions
        size_above_bytes                        = lifecycle_rule.value.condition.size_above_bytes
        size_below_bytes                        = lifecycle_rule.value.condition.size_below_bytes
        days_since_custom_time                  = lifecycle_rule.value.condition.days_since_custom_time
        days_since_noncurrent_time              = lifecycle_rule.value.condition.days_since_noncurrent_time
        custom_time_before                      = lifecycle_rule.value.condition.custom_time_before
        noncurrent_time_before                  = lifecycle_rule.value.condition.noncurrent_time_before
        send_age_if_zero                        = lifecycle_rule.value.condition.send_age_if_zero
        send_num_newer_versions_if_zero         = lifecycle_rule.value.condition.send_num_newer_versions_if_zero
        send_days_since_custom_time_if_zero     = lifecycle_rule.value.condition.send_days_since_custom_time_if_zero
        send_days_since_noncurrent_time_if_zero = lifecycle_rule.value.condition.send_days_since_noncurrent_time_if_zero
      }
    }
  }

  dynamic "logging" {
    for_each = each.value.logging != null ? [each.value.logging] : []

    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = logging.value.log_object_prefix
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []

    content {
      default_kms_key_name = encryption.value.default_kms_key_name
    }
  }

  dynamic "retention_policy" {
    for_each = each.value.retention_policy != null ? [each.value.retention_policy] : []

    content {
      retention_period = retention_policy.value.retention_period
      is_locked        = retention_policy.value.is_locked
    }
  }

  dynamic "soft_delete_policy" {
    for_each = each.value.soft_delete_policy != null ? [each.value.soft_delete_policy] : []

    content {
      retention_duration_seconds = soft_delete_policy.value.retention_duration_seconds
    }
  }

  dynamic "custom_placement_config" {
    for_each = each.value.custom_placement_config != null ? [each.value.custom_placement_config] : []

    content {
      data_locations = custom_placement_config.value.data_locations
    }
  }

  dynamic "website" {
    for_each = each.value.website != null ? [each.value.website] : []

    content {
      main_page_suffix = website.value.main_page_suffix
      not_found_page   = website.value.not_found_page
    }
  }

  dynamic "autoclass" {
    for_each = each.value.autoclass != null ? [each.value.autoclass] : []

    content {
      enabled                = autoclass.value.enabled
      terminal_storage_class = autoclass.value.terminal_storage_class
    }
  }

  dynamic "cors" {
    for_each = each.value.cors

    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  dynamic "hierarchical_namespace" {
    for_each = each.value.hierarchical_namespace != null ? [each.value.hierarchical_namespace] : []

    content {
      enabled = hierarchical_namespace.value
    }
  }
}

resource "google_storage_bucket_iam_binding" "binding" {
  for_each = local.iam_bindings

  bucket  = each.value.name
  role    = each.value.role
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_storage_bucket.bucket]
}
