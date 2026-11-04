terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant" {
  for_each = var.grants

  account_role_name           = each.value.account_role_name
  privileges                  = each.value.privileges
  all_privileges              = each.value.all_privileges
  with_grant_option           = each.value.with_grant_option
  always_apply                = each.value.always_apply
  strict_privilege_management = each.value.strict_privilege_management
  on_account                  = each.value.on_account

  dynamic "on_account_object" {
    for_each = each.value.on_account_object != null ? [each.value.on_account_object] : []
    content {
      object_type = on_account_object.value.object_type
      object_name = on_account_object.value.object_name

      dynamic "inherited" {
        for_each = on_account_object.value.inherited != null ? [on_account_object.value.inherited] : []
        content {
          object_type_plural = inherited.value.object_type_plural
        }
      }
    }
  }

  dynamic "on_schema" {
    for_each = each.value.on_schema != null ? [each.value.on_schema] : []
    content {
      schema_name                = on_schema.value.schema_name
      all_schemas_in_database    = on_schema.value.all_schemas_in_database
      future_schemas_in_database = on_schema.value.future_schemas_in_database

      dynamic "inherited" {
        for_each = on_schema.value.inherited != null ? [on_schema.value.inherited] : []
        content {
          in_account  = inherited.value.in_account
          in_database = inherited.value.in_database
        }
      }
    }
  }

  dynamic "on_schema_object" {
    for_each = each.value.on_schema_object != null ? [each.value.on_schema_object] : []
    content {
      object_type = on_schema_object.value.object_type
      object_name = on_schema_object.value.object_name

      dynamic "all" {
        for_each = on_schema_object.value.all != null ? [on_schema_object.value.all] : []
        content {
          object_type_plural = all.value.object_type_plural
          in_database        = all.value.in_database
          in_schema          = all.value.in_schema
        }
      }

      dynamic "future" {
        for_each = on_schema_object.value.future != null ? [on_schema_object.value.future] : []
        content {
          object_type_plural = future.value.object_type_plural
          in_database        = future.value.in_database
          in_schema          = future.value.in_schema
        }
      }

      dynamic "inherited" {
        for_each = on_schema_object.value.inherited != null ? [on_schema_object.value.inherited] : []
        content {
          object_type_plural = inherited.value.object_type_plural
          in_account         = inherited.value.in_account
          in_database        = inherited.value.in_database
          in_schema          = inherited.value.in_schema
        }
      }
    }
  }
}
