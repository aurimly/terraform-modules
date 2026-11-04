terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_alert" "alert" {
  for_each = var.alerts

  database  = each.value.database
  schema    = each.value.schema
  name      = each.value.name
  warehouse = each.value.warehouse
  condition = each.value.condition
  action    = each.value.action
  enabled   = each.value.enabled
  comment   = each.value.comment

  dynamic "alert_schedule" {
    for_each = each.value.alert_schedule != null ? [each.value.alert_schedule] : []
    content {
      interval = alert_schedule.value.interval

      dynamic "cron" {
        for_each = alert_schedule.value.cron != null ? [alert_schedule.value.cron] : []
        content {
          expression = cron.value.expression
          time_zone  = cron.value.time_zone
        }
      }
    }
  }
}
