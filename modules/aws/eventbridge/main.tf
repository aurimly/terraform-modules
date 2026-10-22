resource "aws_cloudwatch_event_bus" "bus" {
  for_each = var.event_buses

  name              = each.value.name
  event_source_name = each.value.event_source_name
  description       = each.value.description

  tags = merge(each.value.tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition     = each.value.event_source_name == null || each.value.name == each.value.event_source_name
      error_message = "event_bus \"${each.key}\": for a partner event bus, name must equal event_source_name (AWS derives the bus from the source)."
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "bus_policy" {
  for_each = { for k, b in var.event_buses : k => b if b.policy != null }

  event_bus_name = aws_cloudwatch_event_bus.bus[each.key].name
  policy         = each.value.policy
}

resource "aws_cloudwatch_event_rule" "rule" {
  for_each = var.rules

  name                = each.value.name
  description         = each.value.description
  schedule_expression = each.value.schedule_expression
  event_pattern       = each.value.event_pattern
  role_arn            = each.value.role_arn
  state               = each.value.state
  event_bus_name      = each.value.event_bus_key != null ? var.event_buses[each.value.event_bus_key].name : each.value.event_bus_name
  force_destroy       = each.value.force_destroy

  tags = merge(each.value.tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition     = (each.value.event_bus_key != null) != (each.value.event_bus_name != null)
      error_message = "rule \"${each.key}\" must set exactly one of event_bus_key (key into var.event_buses) or event_bus_name (literal name, e.g. \"default\" for the default bus)."
    }

    precondition {
      condition     = (each.value.schedule_expression != null) != (each.value.event_pattern != null)
      error_message = "rule \"${each.key}\" must set exactly one of schedule_expression or event_pattern."
    }
  }
}

resource "aws_cloudwatch_event_target" "target" {
  for_each = local.targets

  rule           = aws_cloudwatch_event_rule.rule[each.value.rule_key].name
  event_bus_name = aws_cloudwatch_event_rule.rule[each.value.rule_key].event_bus_name
  target_id      = each.value.target_id
  arn            = each.value.arn
  role_arn       = each.value.role_arn
  input          = each.value.input
  input_path     = each.value.input_path

  retry_policy {
    maximum_event_age_in_seconds = each.value.retry_policy.maximum_event_age_in_seconds
    maximum_retry_attempts       = each.value.retry_policy.maximum_retry_attempts
  }

  dynamic "batch_target" {
    for_each = each.value.batch_parameters != null ? [each.value.batch_parameters] : []
    content {
      job_definition = batch_target.value.job_definition
      job_name       = batch_target.value.job_name
      array_size     = batch_target.value.array_size
      job_attempts   = batch_target.value.job_attempts
    }
  }

  dynamic "http_target" {
    for_each = each.value.http_parameters != null ? [each.value.http_parameters] : []
    content {
      path_parameter_values   = http_target.value.path_parameter_values
      query_string_parameters = http_target.value.query_string_parameters
      header_parameters       = http_target.value.header_parameters
    }
  }

  dynamic "sqs_target" {
    for_each = each.value.message_group_id != null ? [1] : []
    content {
      message_group_id = each.value.message_group_id
    }
  }

  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_arn != null ? [each.value.dead_letter_arn] : []
    content {
      arn = dead_letter_config.value
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.input == null || each.value.input_path == null
      error_message = "target \"${each.key}\" must set at most one of input or input_path (both target the event payload)."
    }
  }
}

resource "aws_cloudwatch_event_archive" "archive" {
  for_each = local.archives

  name               = each.value.name
  description        = each.value.description
  event_source_arn   = each.value.event_source_arn
  retention_days     = each.value.retention_days
  event_pattern      = each.value.event_pattern
  kms_key_identifier = each.value.kms_key_arn
}

resource "aws_scheduler_schedule_group" "schedule_group" {
  for_each = var.schedule_groups

  name = each.value.name

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_scheduler_schedule" "schedule" {
  for_each = var.schedules

  name                         = each.value.name
  description                  = each.value.description
  group_name                   = each.value.group_name
  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.schedule_expression_timezone
  start_date                   = each.value.start_date
  end_date                     = each.value.end_date
  state                        = each.value.state
  action_after_completion      = each.value.target.action_after_completion
  kms_key_arn                  = each.value.kms_key_arn

  flexible_time_window {
    mode                      = each.value.flexible_time_window.mode
    maximum_window_in_minutes = each.value.flexible_time_window.maximum_window_in_minutes
  }

  target {
    arn      = each.value.target.arn
    role_arn = each.value.target.role_arn
    input    = each.value.target.input

    dynamic "dead_letter_config" {
      for_each = each.value.target.dead_letter_arn != null ? [each.value.target.dead_letter_arn] : []
      content {
        arn = dead_letter_config.value
      }
    }

    retry_policy {
      maximum_event_age_in_seconds = each.value.target.retry_policy.maximum_event_age_in_seconds
      maximum_retry_attempts       = each.value.target.retry_policy.maximum_retry_attempts
    }
  }
}

locals {
  archives = merge([
    for bus_key, bus in var.event_buses : {
      for archive_key, archive in bus.archives : "${bus_key}.${archive_key}" => {
        name             = archive.name
        description      = archive.description
        event_source_arn = archive.event_source_arn != null ? archive.event_source_arn : aws_cloudwatch_event_bus.bus[bus_key].arn
        retention_days   = archive.retention_days
        event_pattern    = archive.event_pattern
        kms_key_arn      = archive.kms_key_arn
      }
    }
  ]...)

  targets = merge([
    for rule_key, rule in var.rules : {
      for target_key, target in rule.targets : "${rule_key}.${target_key}" => merge(target, {
        rule_key = rule_key
      })
    }
  ]...)
}
