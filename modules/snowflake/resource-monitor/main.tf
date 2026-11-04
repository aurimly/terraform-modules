terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_resource_monitor" "monitor" {
  for_each = var.resource_monitors

  name                      = each.value.name
  credit_quota              = each.value.credit_quota
  frequency                 = each.value.frequency
  start_timestamp           = each.value.start_timestamp
  end_timestamp             = each.value.end_timestamp
  notify_triggers           = each.value.notify_triggers
  suspend_trigger           = each.value.suspend_trigger
  suspend_immediate_trigger = each.value.suspend_immediate_trigger
  notify_users              = each.value.notify_users
}
