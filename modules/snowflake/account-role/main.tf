terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_account_role" "role" {
  for_each = var.account_roles

  name    = each.value.name
  comment = each.value.comment
}
