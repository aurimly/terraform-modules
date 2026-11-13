terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_view" "view" {
  for_each = var.views

  database        = each.value.database
  schema          = each.value.schema
  name            = each.value.name
  statement       = each.value.statement
  is_secure       = each.value.is_secure != null ? tostring(each.value.is_secure) : null
  is_recursive    = each.value.is_recursive != null ? tostring(each.value.is_recursive) : null
  change_tracking = each.value.change_tracking != null ? tostring(each.value.change_tracking) : null
  copy_grants     = each.value.copy_grants
  comment         = each.value.comment

  dynamic "column" {
    for_each = each.value.columns != null ? each.value.columns : []

    content {
      column_name = column.value.column_name
      comment     = column.value.comment
    }
  }
}
