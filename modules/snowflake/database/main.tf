terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_database" "database" {
  for_each = var.databases

  name                            = each.value.name
  comment                         = each.value.comment
  is_transient                    = each.value.is_transient
  data_retention_time_in_days     = each.value.data_retention_time_in_days
  max_data_extension_time_in_days = each.value.max_data_extension_time_in_days
  drop_public_schema_on_creation  = each.value.drop_public_schema_on_creation
  default_ddl_collation           = each.value.default_ddl_collation
  log_level                       = each.value.log_level

  dynamic "replication" {
    for_each = each.value.replication != null ? [each.value.replication] : []
    content {
      ignore_edition_check = replication.value.ignore_edition_check
      dynamic "enable_to_account" {
        for_each = replication.value.enable_to_account
        content {
          account_identifier = enable_to_account.value.account_identifier
          with_failover      = enable_to_account.value.with_failover
        }
      }
    }
  }
}
