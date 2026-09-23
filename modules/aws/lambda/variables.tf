variable "functions" {
  description = "Map of Lambda functions keyed by an arbitrary identifier. Each entry creates one aws_lambda_function plus optional event source mappings and invocation permissions. Deployment packages are pulled from S3 and must be uploaded consumer-side."
  type = map(object({
    name                           = string
    role_arn                       = string
    runtime                        = string
    handler                        = string
    description                    = optional(string)
    memory_size                    = optional(number, 128)
    timeout                        = optional(number, 3)
    architectures                  = optional(list(string))
    layers                         = optional(list(string), [])
    s3_bucket                      = string
    s3_key                         = string
    s3_object_version              = optional(string)
    source_code_hash               = optional(string)
    reserved_concurrent_executions = optional(number)
    kms_key_arn                    = optional(string)
    publish                        = optional(bool, false)
    tracing_config = optional(object({
      mode = string
    }))
    dead_letter_config = optional(object({
      target_arn = string
    }))
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
    environment_variables = optional(map(string))
    logging_config = optional(object({
      log_format            = string
      application_log_level = optional(string)
      system_log_level      = optional(string)
      log_group             = optional(string)
    }))
    ephemeral_storage = optional(object({
      size = optional(number)
    }))
    event_source_mappings = optional(map(object({
      event_source_arn                   = string
      enabled                            = optional(bool, true)
      batch_size                         = optional(number)
      starting_position                  = optional(string)
      starting_position_timestamp        = optional(string)
      maximum_batching_window_in_seconds = optional(number)
      maximum_retry_attempts             = optional(number)
      bisect_batch_on_function_error     = optional(bool)
      parallelization_factor             = optional(number)
      destination_arn                    = optional(string)
      function_response_types            = optional(list(string), [])
      filter_criteria = optional(object({
        filters = optional(list(object({
          pattern = string
        })), [])
      }))
    })), {})
    permissions = optional(map(object({
      statement_id   = optional(string)
      action         = optional(string, "lambda:InvokeFunction")
      principal      = string
      source_arn     = optional(string)
      source_account = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.functions) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (event source mapping and permission resource addresses are composed from function and entry keys)."
  }

  validation {
    condition = alltrue([
      for f_key, f in var.functions :
      alltrue([for m_key in keys(f.event_source_mappings) : can(regex("^[^.]+$", m_key))])
    ])
    error_message = "event_source_mappings map keys must not contain '.' (composite resource addresses \"function-key.mapping-key\" are used for resource addresses and outputs)."
  }

  validation {
    condition = alltrue([
      for f_key, f in var.functions :
      alltrue([for p_key in keys(f.permissions) : can(regex("^[^.]+$", p_key))])
    ])
    error_message = "permissions map keys must not contain '.' (composite resource addresses \"function-key.permission-key\" are used for resource addresses and outputs)."
  }

  validation {
    condition     = alltrue([for f in var.functions : length(f.name) <= 64 && can(regex("^[a-zA-Z0-9-_]+$", f.name))])
    error_message = "name must be up to 64 characters of alphanumerics, hyphens and underscores (Lambda function naming rules)."
  }

  validation {
    condition     = alltrue([for f in var.functions : length(f.runtime) > 0 && can(regex("^[a-zA-Z0-9_.-]+$", f.runtime))])
    error_message = "runtime is required and must match the Lambda runtime name shape (e.g. nodejs22.x, python3.13) — deliberately not a fixed list so new runtimes never break the module."
  }

  validation {
    condition     = alltrue([for f in var.functions : length(f.handler) > 0])
    error_message = "handler is required (S3 zip packaging; container-image packaging is out of scope)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.memory_size >= 128 && f.memory_size <= 32768])
    error_message = "memory_size must be between 128 and 32768 MB (AWS CreateFunction range; the account default quota may be lower and raises automatically with usage)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.timeout >= 1 && f.timeout <= 900])
    error_message = "timeout must be between 1 and 900 seconds (AWS limit)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.architectures == null || length(f.architectures) <= 1])
    error_message = "architectures accepts at most one value (the API rejects a function with two architectures)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.architectures == null || alltrue([for a in f.architectures : contains(["x86_64", "arm64"], a)])])
    error_message = "architectures values must be x86_64 or arm64 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.functions : alltrue([for l in f.layers : can(regex("^arn:", l))])])
    error_message = "layers entries must be layer-version ARNs."
  }

  validation {
    condition     = alltrue([for f in var.functions : length(f.layers) <= 5])
    error_message = "a function may attach at most 5 layers (AWS limit)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.reserved_concurrent_executions == null || f.reserved_concurrent_executions >= -1])
    error_message = "reserved_concurrent_executions must be -1 (unreserved) or a non-negative number."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.tracing_config == null || contains(["Active", "PassThrough"], f.tracing_config.mode)])
    error_message = "tracing_config.mode must be Active or PassThrough (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.vpc_config == null || (length(f.vpc_config.subnet_ids) > 0 && length(f.vpc_config.security_group_ids) > 0)])
    error_message = "vpc_config requires at least one subnet_id and one security_group_id (the API rejects one-sided VPC configuration)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.dead_letter_config == null || can(regex("^arn:[^:]+:(sqs|sns):", f.dead_letter_config.target_arn))])
    error_message = "dead_letter_config.target_arn must be an SQS queue or SNS topic ARN (the API rejects other services as DLQs)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.logging_config == null || contains(["JSON", "Text"], f.logging_config.log_format)])
    error_message = "logging_config.log_format must be JSON or Text (case-sensitive); required when logging_config is set (the provider rejects the block without it)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.logging_config == null || f.logging_config.log_format == "JSON" || (f.logging_config.application_log_level == null && f.logging_config.system_log_level == null)])
    error_message = "logging_config: application_log_level and system_log_level only apply to log_format JSON (the API rejects them on Text)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.logging_config == null || f.logging_config.application_log_level == null || contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"], f.logging_config.application_log_level)])
    error_message = "logging_config.application_log_level must be one of TRACE, DEBUG, INFO, WARN, ERROR or FATAL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.logging_config == null || f.logging_config.system_log_level == null || contains(["DEBUG", "INFO", "WARN"], f.logging_config.system_log_level)])
    error_message = "logging_config.system_log_level must be one of DEBUG, INFO or WARN (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.functions : f.ephemeral_storage == null || f.ephemeral_storage.size == null || (f.ephemeral_storage.size >= 512 && f.ephemeral_storage.size <= 10240)])
    error_message = "ephemeral_storage.size must be between 512 and 10240 MB (AWS limits)."
  }

  validation {
    condition     = alltrue([for f in var.functions : alltrue([for m in f.event_source_mappings : can(regex("^arn:[^:]+:(sqs|kinesis|dynamodb|kafka):", m.event_source_arn))])])
    error_message = "event_source_mappings.event_source_arn must be an SQS queue, Kinesis stream, DynamoDB stream or MSK cluster ARN (self-managed Kafka endpoints are out of scope)."
  }

  validation {
    condition = alltrue([for f in var.functions : alltrue([
      for m in f.event_source_mappings : m.starting_position == null || contains(["TRIM_HORIZON", "LATEST", "AT_TIMESTAMP"], m.starting_position)
    ])])
    error_message = "event_source_mappings.starting_position must be TRIM_HORIZON, LATEST or AT_TIMESTAMP (case-sensitive)."
  }

  validation {
    condition = alltrue([for f in var.functions : alltrue([
      for m in f.event_source_mappings : can(regex("^arn:[^:]+:sqs:", m.event_source_arn)) || m.starting_position != null
    ])])
    error_message = "event_source_mappings: starting_position is required for Kinesis, DynamoDB-stream and MSK sources (only SQS omits it)."
  }

  validation {
    condition = alltrue([for f in var.functions : alltrue([
      for m in f.event_source_mappings : !can(regex("^arn:[^:]+:sqs:", m.event_source_arn)) || m.starting_position == null
    ])])
    error_message = "event_source_mappings: starting_position must be omitted for SQS sources (the API rejects StartingPosition on SQS)."
  }

  validation {
    condition = alltrue([for f in var.functions : alltrue([
      for m in f.event_source_mappings : m.starting_position == null || m.starting_position != "AT_TIMESTAMP" || can(regex("^arn:[^:]+:kinesis:", m.event_source_arn))
    ])])
    error_message = "event_source_mappings: starting_position AT_TIMESTAMP is only valid on Kinesis sources."
  }

  validation {
    condition = alltrue([for f in var.functions : alltrue([
      for m in f.event_source_mappings : m.starting_position_timestamp == null || m.starting_position == "AT_TIMESTAMP"
    ])])
    error_message = "event_source_mappings.starting_position_timestamp requires starting_position = AT_TIMESTAMP."
  }

  validation {
    condition = alltrue([for f in var.functions : alltrue([
      for m in f.event_source_mappings : !can(regex("^arn:[^:]+:sqs:", m.event_source_arn)) || m.destination_arn == null
    ])])
    error_message = "event_source_mappings: destination_arn only applies to stream sources (DynamoDB streams, Kinesis and Kafka) — the API rejects a destination config on SQS; use SQS-native redrive policies for SQS sources."
  }

  validation {
    condition = alltrue([for f in var.functions : alltrue([
      for m in f.event_source_mappings : alltrue([for t in m.function_response_types : t == "ReportBatchItemFailures"])
    ])])
    error_message = "event_source_mappings.function_response_types only supports ReportBatchItemFailures (the API rejects other values)."
  }

  validation {
    condition = alltrue([for f in var.functions : alltrue([
      for m in f.event_source_mappings : m.filter_criteria == null || alltrue([
        for flt in m.filter_criteria.filters : flt.pattern == null || length(flt.pattern) > 0
      ])
    ])])
    error_message = "event_source_mappings.filter_criteria.filters[].pattern is required and must be non-empty (the provider requires the pattern attribute; the API rejects empty patterns)."
  }
}
