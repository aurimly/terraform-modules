terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_schema" "schema" {
  for_each = var.schemas

  database                        = each.value.database
  name                            = each.value.name
  with_managed_access             = each.value.with_managed_access != null ? tostring(each.value.with_managed_access) : null
  is_transient                    = each.value.is_transient != null ? tostring(each.value.is_transient) : null
  comment                         = each.value.comment
  data_retention_time_in_days     = each.value.data_retention_time_in_days
  max_data_extension_time_in_days = each.value.max_data_extension_time_in_days
  default_ddl_collation           = each.value.default_ddl_collation
  log_level                       = each.value.log_level
}
