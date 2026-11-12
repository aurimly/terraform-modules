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
#   schemas = {
#     "analytics_raw" = {
#       database             = "DB_ANALYTICS"
#       name                 = "RAW"
#       with_managed_access  = true
#       data_retention_time_in_days = 30
#     }
#     "analytics_report" = {
#       database             = "DB_ANALYTICS"
#       name                 = "REPORT"
#     }
#   }
# }

inputs = {
  schemas = {
    "example" = {
      database = "DB_EXAMPLE"
      name     = "EXAMPLE_SCHEMA"
    }
  }
}
