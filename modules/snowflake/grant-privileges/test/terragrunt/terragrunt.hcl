terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Snowflake, replace the inputs
# below with real values (needs a Snowflake account; the provider config lives
# at the consumer unit level). terragrunt validate with the placeholder inputs
# needs no Snowflake connection — nothing here calls the API. Object and schema
# references must be quoted fully qualified names (see module README).
#
# inputs = {
#   grants = {
#     "analyst-select-all-tables" = {
#       account_role_name = "account_role_fully_qualified_name (e.g. from snowflake/account-role output)"
#       privileges        = ["SELECT"]
#       on_schema_object = {
#         all = {
#           object_type_plural = "TABLES"
#           in_schema          = "\"TEST_DB\".\"TEST_SCHEMA\""
#         }
#       }
#     }
#   }
# }

inputs = {
  grants = {
    "example-account-object" = {
      account_role_name = "\"ROLE_EXAMPLE\""
      privileges        = ["SELECT", "INSERT"]
      on_account_object = {
        object_type = "DATABASE"
        object_name = "\"DB_EXAMPLE\""
      }
    }
  }
}
