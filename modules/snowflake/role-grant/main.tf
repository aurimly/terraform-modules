terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_grant_account_role" "grant" {
  for_each = var.role_grants

  role_name        = each.value.role_name
  user_name        = each.value.user_name
  parent_role_name = each.value.parent_role_name
}
