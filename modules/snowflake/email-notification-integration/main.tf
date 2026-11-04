terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_email_notification_integration" "integration" {
  for_each = var.integrations

  name               = each.value.name
  enabled            = each.value.enabled
  allowed_recipients = each.value.allowed_recipients
  comment            = each.value.comment
}
