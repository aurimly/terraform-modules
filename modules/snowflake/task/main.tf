terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_task" "task" {
  for_each = var.tasks

  database      = each.value.database
  schema        = each.value.schema
  name          = each.value.name
  sql_statement = each.value.sql_statement
  started       = each.value.started
  warehouse     = each.value.warehouse
  when          = each.value.when
  comment       = each.value.comment
  config        = each.value.config
  after         = each.value.after
  finalize      = each.value.finalize

  dynamic "schedule" {
    for_each = each.value.schedule != null ? [each.value.schedule] : []

    content {
      seconds    = schedule.value.seconds
      minutes    = schedule.value.minutes
      hours      = schedule.value.hours
      using_cron = schedule.value.using_cron
    }
  }

  dynamic "target_completion_interval" {
    for_each = each.value.target_completion_interval != null ? [each.value.target_completion_interval] : []

    content {
      seconds = target_completion_interval.value.seconds
      minutes = target_completion_interval.value.minutes
      hours   = target_completion_interval.value.hours
    }
  }

  allow_overlapping_execution                   = each.value.allow_overlapping_execution != null ? tostring(each.value.allow_overlapping_execution) : null
  error_integration                             = each.value.error_integration
  execute_as_user                               = each.value.execute_as_user
  user_task_managed_initial_warehouse_size      = each.value.user_task_managed_initial_warehouse_size
  serverless_task_min_statement_size            = each.value.serverless_task_min_statement_size
  serverless_task_max_statement_size            = each.value.serverless_task_max_statement_size
  suspend_task_after_num_failures               = each.value.suspend_task_after_num_failures
  task_auto_retry_attempts                      = each.value.task_auto_retry_attempts
  user_task_timeout_ms                          = each.value.user_task_timeout_ms
  user_task_minimum_trigger_interval_in_seconds = each.value.user_task_minimum_trigger_interval_in_seconds
  log_level                                     = each.value.log_level
  log_event_level                               = each.value.log_event_level
}
