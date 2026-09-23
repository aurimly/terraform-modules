resource "aws_ecs_cluster" "cluster" {
  for_each = var.clusters

  name = each.value.name

  dynamic "setting" {
    for_each = each.value.enable_container_insights != null ? [1] : []

    content {
      name  = "containerInsights"
      value = each.value.enable_container_insights ? "enabled" : "disabled"
    }
  }

  dynamic "configuration" {
    for_each = each.value.execute_command_configuration != null ? [each.value.execute_command_configuration] : []

    content {
      execute_command_configuration {
        kms_key_id = configuration.value.kms_key_id
        logging    = configuration.value.logging

        dynamic "log_configuration" {
          for_each = configuration.value.log_configuration != null ? [configuration.value.log_configuration] : []

          content {
            cloud_watch_log_group_name     = log_configuration.value.cloud_watch_log_group_name
            cloud_watch_encryption_enabled = log_configuration.value.cloud_watch_encryption_enabled
            s3_bucket_name                 = log_configuration.value.s3_bucket_name
            s3_bucket_encryption_enabled   = log_configuration.value.s3_bucket_encryption_enabled
            s3_key_prefix                  = log_configuration.value.s3_key_prefix
          }
        }
      }
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {
  for_each = { for k, c in var.clusters : k => c if length(c.capacity_providers) > 0 || length(c.default_capacity_provider_strategy) > 0 }

  cluster_name       = aws_ecs_cluster.cluster[each.key].name
  capacity_providers = each.value.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = each.value.default_capacity_provider_strategy

    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = default_capacity_provider_strategy.value.base
    }
  }
}
