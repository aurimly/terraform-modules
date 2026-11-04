terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Snowflake, replace the inputs
# below with real values (needs a Snowflake account; the provider config lives
# at the consumer unit level). terragrunt validate with the placeholder inputs
# needs no Snowflake connection — nothing here calls the API.
#
# inputs = {
#   users = {
#     "analyst" = {
#       name           = "USER_ANALYST"
#       default_role   = "ROLE_ANALYST"
#       default_warehouse = "WH_ANALYTICS"
#       display_name    = "Analyst"
#       email          = "analyst@example.com"
#       must_change_password = true
#     }
#   }
# }

inputs = {
  users = {
    "example" = {
      name      = "USER_EXAMPLE"
      login_name = "USER_EXAMPLE_LOGIN"
      email     = "user@example.com"
    }
  }
}
