resource "aws_sqs_queue" "queue" {
  for_each = var.queues

  name                              = each.value.name
  name_prefix                       = each.value.name_prefix
  delay_seconds                     = each.value.delay_seconds
  max_message_size                  = each.value.max_message_size
  message_retention_seconds         = each.value.message_retention_seconds
  receive_wait_time_seconds         = each.value.receive_wait_time_seconds
  visibility_timeout_seconds        = each.value.visibility_timeout_seconds
  sqs_managed_sse_enabled           = each.value.sse.enabled
  kms_master_key_id                 = each.value.sse.kms_master_key_id
  kms_data_key_reuse_period_seconds = each.value.sse.kms_data_key_reuse_period_seconds
  deduplication_scope               = each.value.deduplication_scope
  fifo_throughput_limit             = each.value.fifo_throughput_limit
  redrive_policy = each.value.redrive != null ? jsonencode({
    deadLetterTargetArn = each.value.redrive.dead_letter_target_arn
    maxReceiveCount     = each.value.redrive.max_receive_count
  }) : null
  redrive_allow_policy = each.value.redrive_allow != null ? jsonencode({
    redrivePermission = each.value.redrive_allow.permission
    sourceQueueArns   = each.value.redrive_allow.source_queue_arns
  }) : null
  tags = merge(each.value.tags, { Name = coalesce(each.value.name, each.value.name_prefix) })

  lifecycle {
    precondition {
      condition     = (each.value.name != null) != (each.value.name_prefix != null)
      error_message = "queue \"${each.key}\" must set exactly one of name or name_prefix."
    }

    precondition {
      condition     = each.value.sse.enabled || each.value.sse.kms_master_key_id == null
      error_message = "queue \"${each.key}\": sse.kms_master_key_id requires sse.enabled = true (customer-managed KMS replaces the managed encryption)."
    }

    precondition {
      condition     = !each.value.fifo || can(regex("\\.fifo$", coalesce(each.value.name, "${each.value.name_prefix}.")))
      error_message = "queue \"${each.key}\" is FIFO: name must end in .fifo (and name_prefix must be the prefix of a .fifo name)."
    }
  }
}
