terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Snowflake, replace the inputs
# below with real values (needs a Snowflake account; the provider config lives
# at the consumer unit level). terragrunt validate with the placeholder inputs
# needs no Snowflake connection — nothing here calls the API.
#
# inputs = {
#   role_grants = {
#     "analyst-to-user" = {
#       role_name = "\"ROLE_ANALYST\""
#       user_name = "user_fully_qualified_name (e.g. from snowflake/user output)"
#     }
#   }
# }

inputs = {
  role_grants = {
    "example" = {
      role_name = "\"ROLE_EXAMPLE\""
      user_name = "\"USER_EXAMPLE\""
    }
  }
}
