locals {
  # CloudTrail requires the log-stream wildcard on the log-group ARN.
  cloud_watch_logs_group_arns = {
    for k, t in var.trails : k =>
    t.cloud_watch_logs_group_arn == null ? null : "${t.cloud_watch_logs_group_arn}:*"
  }
}

resource "aws_cloudtrail" "trail" {
  for_each = var.trails

  name                          = each.value.name
  s3_bucket_name                = each.value.s3_bucket_name
  s3_key_prefix                 = each.value.s3_key_prefix
  is_multi_region_trail         = each.value.is_multi_region_trail
  is_organization_trail         = each.value.is_organization_trail
  enable_log_file_validation    = each.value.enable_log_file_validation
  enable_logging                = each.value.enable_logging
  include_global_service_events = each.value.include_global_service_events
  kms_key_id                    = each.value.kms_key_id
  sns_topic_name                = each.value.sns_topic_name
  cloud_watch_logs_group_arn    = local.cloud_watch_logs_group_arns[each.key]
  cloud_watch_logs_role_arn     = each.value.cloud_watch_logs_role_arn
  recursive_logging             = each.value.recursive_logging

  dynamic "event_selector" {
    for_each = each.value.event_selectors
    content {
      read_write_type                  = event_selector.value.read_write_type
      include_management_events        = event_selector.value.include_management_events
      exclude_management_event_sources = event_selector.value.exclude_management_event_sources

      dynamic "data_resource" {
        for_each = event_selector.value.data_resources
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  dynamic "advanced_event_selector" {
    for_each = each.value.advanced_event_selectors
    content {
      name = advanced_event_selector.value.name

      dynamic "field_selector" {
        for_each = advanced_event_selector.value.field_selectors
        content {
          field           = field_selector.value.field
          equals          = field_selector.value.equals
          starts_with     = field_selector.value.starts_with
          ends_with       = field_selector.value.ends_with
          not_equals      = field_selector.value.not_equals
          not_starts_with = field_selector.value.not_starts_with
          not_ends_with   = field_selector.value.not_ends_with
        }
      }
    }
  }

  dynamic "insight_selector" {
    for_each = toset(each.value.insight_types)
    content {
      insight_type = insight_selector.value
    }
  }

  tags = each.value.tags
}
