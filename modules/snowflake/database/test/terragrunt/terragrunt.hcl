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
#   databases = {
#     "reporting" = {
#       name                        = "DB_REPORTING"
#       data_retention_time_in_days = 30
#       comment                     = "Reporting database"
#       replication = {
#         enable_to_account = [
#           { account_identifier = "ORG_ACME.SECONDARY", with_failover = true }
#         ]
#       }
#     }
#   }
# }

inputs = {
  databases = {
    "example" = {
      name                        = "DB_EXAMPLE"
      data_retention_time_in_days = 3
    }
  }
}
