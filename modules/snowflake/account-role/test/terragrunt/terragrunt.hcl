terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Snowflake, replace the inputs
# below with real values (needs a Snowflake account; the provider config lives
# at the consumer unit level, e.g. SNOWFLAKE_* env vars or ~/.snowflake/config).
# terragrunt validate with the placeholder inputs needs no Snowflake
# connection — nothing here calls the API.
#
# inputs = {
#   account_roles = {
#     "analyst" = {
#       name    = "ROLE_ANALYST"
#       comment = "read analytics shapes"
#     }
#   }
# }

inputs = {
  account_roles = {
    "example" = {
      name = "ROLE_EXAMPLE"
    }
  }
}
