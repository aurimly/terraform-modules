variable "queues" {
  description = "Map of SQS queues keyed by an arbitrary identifier. Each entry creates one aws_sqs_queue."
  type = map(object({
    name                       = optional(string)
    name_prefix                = optional(string)
    fifo                       = optional(bool, false)
    delay_seconds              = optional(number)
    max_message_size           = optional(number)
    message_retention_seconds  = optional(number)
    receive_wait_time_seconds  = optional(number)
    visibility_timeout_seconds = optional(number)
    deduplication_scope        = optional(string)
    fifo_throughput_limit      = optional(string)
    sse = optional(object({
      enabled                           = optional(bool, true)
      kms_master_key_id                 = optional(string)
      kms_data_key_reuse_period_seconds = optional(number)
    }), {})
    redrive = optional(object({
      dead_letter_target_arn = string
      max_receive_count      = number
    }))
    redrive_allow = optional(object({
      permission        = string
      source_queue_arns = optional(list(string))
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for q in var.queues : q.name == null || (length(q.name) <= 80 && can(regex("^[a-zA-Z0-9_-]+(\\.fifo)?$", q.name)))])
    error_message = "name must be up to 80 characters with alphanumerics, hyphens and underscores; FIFO queue names must end in .fifo (SQS naming rules)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.name_prefix == null || (length(q.name_prefix) <= 48 && can(regex("^[a-zA-Z0-9_-]+$", q.name_prefix)))])
    error_message = "name_prefix must be up to 48 characters with alphanumerics, hyphens and underscores (leaves room for the generated suffix and .fifo)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.delay_seconds == null || q.delay_seconds >= 0 && q.delay_seconds <= 900])
    error_message = "delay_seconds must be between 0 and 900 (SQS DelaySeconds range)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.max_message_size == null || q.max_message_size >= 1024 && q.max_message_size <= 262144])
    error_message = "max_message_size must be between 1024 and 262144 bytes (1 KiB to 256 KiB, SQS MaximumMessageSize range)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.message_retention_seconds == null || (q.message_retention_seconds >= 60 && q.message_retention_seconds <= 1209600)])
    error_message = "message_retention_seconds must be between 60 and 1209600 (1 minute to 14 days, SQS MessageRetentionPeriod range)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.receive_wait_time_seconds == null || q.receive_wait_time_seconds >= 0 && q.receive_wait_time_seconds <= 20])
    error_message = "receive_wait_time_seconds must be between 0 and 20 (SQS ReceiveMessageWaitTimeSeconds range)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.visibility_timeout_seconds == null || q.visibility_timeout_seconds >= 0 && q.visibility_timeout_seconds <= 43200])
    error_message = "visibility_timeout_seconds must be between 0 and 43200 (SQS VisibilityTimeout range)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.deduplication_scope == null || !q.fifo || contains(["queue", "messageGroup"], q.deduplication_scope)])
    error_message = "deduplication_scope must be one of queue or messageGroup, and only applies to FIFO queues."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.fifo_throughput_limit == null || !q.fifo || contains(["perQueue", "perMessageGroupId"], q.fifo_throughput_limit)])
    error_message = "fifo_throughput_limit must be one of perQueue or perMessageGroupId, and only applies to FIFO queues."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.deduplication_scope == null && q.fifo_throughput_limit == null || q.fifo])
    error_message = "deduplication_scope and fifo_throughput_limit are FIFO-only settings; set fifo = true to use them."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.redrive == null || q.redrive.max_receive_count >= 1 && q.redrive.max_receive_count <= 1000])
    error_message = "redrive.max_receive_count must be between 1 and 1000 (SQS maxReceiveCount range)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.redrive_allow == null || contains(["byQueue", "never", "all"], q.redrive_allow.permission)])
    error_message = "redrive_allow.permission must be one of byQueue, never or all (case-sensitive)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.redrive_allow == null || q.redrive_allow.permission != "byQueue" || length(q.redrive_allow.source_queue_arns) > 0])
    error_message = "redrive_allow.source_queue_arns must contain at least one ARN when permission is byQueue."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.redrive_allow == null || q.redrive_allow.permission == "byQueue" || q.redrive_allow.source_queue_arns == null])
    error_message = "redrive_allow.source_queue_arns is only valid when permission is byQueue (the API rejects it otherwise)."
  }

  validation {
    condition     = alltrue([for q in var.queues : q.sse.kms_data_key_reuse_period_seconds == null || q.sse.kms_data_key_reuse_period_seconds >= 60 && q.sse.kms_data_key_reuse_period_seconds <= 86400])
    error_message = "sse.kms_data_key_reuse_period_seconds must be between 60 and 86400 (SQS KMS DataKeyReusePeriodSeconds range)."
  }
}
