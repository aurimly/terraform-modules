resource "aws_sns_topic" "topic" {
  for_each = var.topics

  name                        = each.value.name
  name_prefix                 = each.value.name_prefix
  display_name                = each.value.display_name
  signature_version           = each.value.signature_version
  tracing_config              = each.value.tracing_mode
  fifo_topic                  = each.value.fifo
  content_based_deduplication = each.value.content_based_deduplication
  kms_master_key_id           = each.value.kms_master_key_id

  application_success_feedback_role_arn    = each.value.application_feedback != null ? each.value.application_feedback.success_feedback_role_arn : null
  application_failure_feedback_role_arn    = each.value.application_feedback != null ? each.value.application_feedback.failure_feedback_role_arn : null
  application_success_feedback_sample_rate = each.value.application_feedback != null ? each.value.application_feedback.success_feedback_sample_rate : null
  lambda_success_feedback_role_arn         = each.value.lambda_feedback != null ? each.value.lambda_feedback.success_feedback_role_arn : null
  lambda_failure_feedback_role_arn         = each.value.lambda_feedback != null ? each.value.lambda_feedback.failure_feedback_role_arn : null
  lambda_success_feedback_sample_rate      = each.value.lambda_feedback != null ? each.value.lambda_feedback.success_feedback_sample_rate : null
  http_success_feedback_role_arn           = each.value.http_feedback != null ? each.value.http_feedback.success_feedback_role_arn : null
  http_failure_feedback_role_arn           = each.value.http_feedback != null ? each.value.http_feedback.failure_feedback_role_arn : null
  http_success_feedback_sample_rate        = each.value.http_feedback != null ? each.value.http_feedback.success_feedback_sample_rate : null
  sqs_success_feedback_role_arn            = each.value.sqs_feedback != null ? each.value.sqs_feedback.success_feedback_role_arn : null
  sqs_failure_feedback_role_arn            = each.value.sqs_feedback != null ? each.value.sqs_feedback.failure_feedback_role_arn : null
  sqs_success_feedback_sample_rate         = each.value.sqs_feedback != null ? each.value.sqs_feedback.success_feedback_sample_rate : null
  firehose_success_feedback_role_arn       = each.value.firehose_feedback != null ? each.value.firehose_feedback.success_feedback_role_arn : null
  firehose_failure_feedback_role_arn       = each.value.firehose_feedback != null ? each.value.firehose_feedback.failure_feedback_role_arn : null
  firehose_success_feedback_sample_rate    = each.value.firehose_feedback != null ? each.value.firehose_feedback.success_feedback_sample_rate : null

  delivery_policy = each.value.delivery_policy

  tags = merge(each.value.tags, { Name = coalesce(each.value.name, each.value.name_prefix) })

  lifecycle {
    precondition {
      condition     = (each.value.name != null) != (each.value.name_prefix != null)
      error_message = "topic \"${each.key}\" must set exactly one of name or name_prefix."
    }

    precondition {
      condition     = !each.value.fifo || can(regex("\\.fifo$", coalesce(each.value.name, "${each.value.name_prefix}.")))
      error_message = "topic \"${each.key}\" is FIFO: name must end in .fifo (and name_prefix must be the prefix of a .fifo name)."
    }

    precondition {
      condition     = each.value.fifo || each.value.content_based_deduplication == null
      error_message = "topic \"${each.key}\": content_based_deduplication is only valid on FIFO topics."
    }
  }
}

resource "aws_sns_topic_policy" "policy" {
  for_each = { for k, t in var.topics : k => t if t.policy != null }

  arn    = aws_sns_topic.topic[each.key].arn
  policy = each.value.policy
}

resource "aws_sns_topic_subscription" "subscription" {
  for_each = { for k, v in local.subscriptions : k => v }

  topic_arn                       = each.value.topic_arn
  protocol                        = each.value.protocol
  endpoint                        = each.value.endpoint
  endpoint_auto_confirms          = each.value.endpoint_auto_confirms
  confirmation_timeout_in_minutes = each.value.confirmation_timeout
  raw_message_delivery            = each.value.raw_message_delivery
  delivery_policy                 = each.value.delivery_policy
  filter_policy                   = each.value.filter_policy
  filter_policy_scope             = each.value.filter_policy_scope
  redrive_policy                  = each.value.redrive_policy
}

locals {
  subscriptions = merge([
    for topic_key, topic in var.topics : {
      for sub_key, sub in topic.subscriptions : "${topic_key}.${sub_key}" => {
        topic_arn              = aws_sns_topic.topic[topic_key].arn
        protocol               = sub.protocol
        endpoint               = sub.endpoint
        endpoint_auto_confirms = sub.endpoint_auto_confirms
        confirmation_timeout   = sub.confirmation_timeout
        raw_message_delivery   = sub.raw_message_delivery
        delivery_policy        = sub.delivery_policy
        filter_policy          = sub.filter_policy
        filter_policy_scope    = sub.filter_policy_scope
        redrive_policy         = sub.redrive_policy
      }
    }
  ]...)
}
