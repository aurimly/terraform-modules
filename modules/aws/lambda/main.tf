locals {
  event_source_mappings = merge([
    for f_key, f in var.functions : {
      for m_key, m in f.event_source_mappings : "${f_key}.${m_key}" => merge(m, { function_key = f_key })
    }
  ]...)

  permissions = merge([
    for f_key, f in var.functions : {
      for p_key, p in f.permissions : "${f_key}.${p_key}" => merge(p, { function_key = f_key })
    }
  ]...)
}

resource "aws_lambda_function" "function" {
  for_each = var.functions

  function_name                  = each.value.name
  role                           = each.value.role_arn
  runtime                        = each.value.runtime
  handler                        = each.value.handler
  description                    = each.value.description
  memory_size                    = each.value.memory_size
  timeout                        = each.value.timeout
  architectures                  = each.value.architectures
  layers                         = each.value.layers
  s3_bucket                      = each.value.s3_bucket
  s3_key                         = each.value.s3_key
  s3_object_version              = each.value.s3_object_version
  source_code_hash               = each.value.source_code_hash
  reserved_concurrent_executions = each.value.reserved_concurrent_executions
  kms_key_arn                    = each.value.kms_key_arn
  publish                        = each.value.publish

  dynamic "tracing_config" {
    for_each = each.value.tracing_config != null ? [each.value.tracing_config] : []

    content {
      mode = tracing_config.value.mode
    }
  }

  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_config != null ? [each.value.dead_letter_config] : []

    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  dynamic "vpc_config" {
    for_each = each.value.vpc_config != null ? [each.value.vpc_config] : []

    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "environment" {
    for_each = each.value.environment_variables != null ? [1] : []

    content {
      variables = each.value.environment_variables
    }
  }

  dynamic "logging_config" {
    for_each = each.value.logging_config != null ? [each.value.logging_config] : []

    content {
      log_format            = logging_config.value.log_format
      application_log_level = logging_config.value.application_log_level
      system_log_level      = logging_config.value.system_log_level
      log_group             = logging_config.value.log_group
    }
  }

  dynamic "ephemeral_storage" {
    for_each = each.value.ephemeral_storage != null && each.value.ephemeral_storage.size != null ? [each.value.ephemeral_storage] : []

    content {
      size = ephemeral_storage.value.size
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_lambda_event_source_mapping" "mapping" {
  for_each = local.event_source_mappings

  function_name                      = aws_lambda_function.function[each.value.function_key].function_name
  event_source_arn                   = each.value.event_source_arn
  enabled                            = each.value.enabled
  batch_size                         = each.value.batch_size
  starting_position                  = each.value.starting_position
  starting_position_timestamp        = each.value.starting_position_timestamp
  maximum_batching_window_in_seconds = each.value.maximum_batching_window_in_seconds
  maximum_retry_attempts             = each.value.maximum_retry_attempts
  bisect_batch_on_function_error     = each.value.bisect_batch_on_function_error
  parallelization_factor             = each.value.parallelization_factor
  function_response_types            = each.value.function_response_types

  dynamic "destination_config" {
    for_each = each.value.destination_arn != null ? [1] : []

    content {
      on_failure {
        destination_arn = each.value.destination_arn
      }
    }
  }

  dynamic "filter_criteria" {
    for_each = each.value.filter_criteria != null ? [each.value.filter_criteria] : []

    content {
      dynamic "filter" {
        for_each = filter_criteria.value.filters

        content {
          pattern = filter.value.pattern
        }
      }
    }
  }
}

resource "aws_lambda_permission" "permission" {
  for_each = local.permissions

  function_name  = aws_lambda_function.function[each.value.function_key].function_name
  statement_id   = each.value.statement_id
  action         = each.value.action
  principal      = each.value.principal
  source_arn     = each.value.source_arn
  source_account = each.value.source_account
}
