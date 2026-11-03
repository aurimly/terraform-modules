resource "aws_sfn_state_machine" "machine" {
  for_each = var.state_machines

  name        = each.value.name
  name_prefix = each.value.name_prefix
  type        = each.value.type
  role_arn    = each.value.role_arn
  definition  = each.value.definition
  publish     = each.value.publish

  dynamic "logging_configuration" {
    for_each = each.value.logging_configuration != null ? [each.value.logging_configuration] : []

    content {
      log_destination        = logging_configuration.value.log_destination
      include_execution_data = logging_configuration.value.include_execution_data
      level                  = logging_configuration.value.level
    }
  }

  dynamic "tracing_configuration" {
    for_each = each.value.tracing_configuration != null ? [each.value.tracing_configuration] : []

    content {
      enabled = tracing_configuration.value.enabled
    }
  }

  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration != null ? [each.value.encryption_configuration] : []

    content {
      kms_key_id                        = encryption_configuration.value.kms_key_id
      kms_data_key_reuse_period_seconds = encryption_configuration.value.kms_data_key_reuse_period_seconds
      type                              = encryption_configuration.value.type
    }
  }

  # Name tag only on name-based entries: the final name of a name_prefix
  # entry is unknowable at plan time (the provider appends a random
  # suffix), so those tags pass through unchanged.
  tags = each.value.name != null ? merge(each.value.tags, { Name = each.value.name }) : each.value.tags
}

resource "aws_sfn_activity" "activity" {
  for_each = var.activities

  name = each.value.name

  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration != null ? [each.value.encryption_configuration] : []

    content {
      kms_key_id                        = encryption_configuration.value.kms_key_id
      kms_data_key_reuse_period_seconds = encryption_configuration.value.kms_data_key_reuse_period_seconds
      type                              = encryption_configuration.value.type
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}
