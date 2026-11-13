terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_pipe" "pipe" {
  for_each = var.pipes

  database              = each.value.database
  schema                = each.value.schema
  name                  = each.value.name
  copy_statement        = each.value.copy_statement
  auto_ingest           = each.value.auto_ingest
  aws_sns_topic_arn     = each.value.aws_sns_topic_arn
  integration           = each.value.integration
  error_integration     = each.value.error_integration
  pipe_execution_paused = each.value.pipe_execution_paused
  log_event_level       = each.value.log_event_level
  comment               = each.value.comment
}
