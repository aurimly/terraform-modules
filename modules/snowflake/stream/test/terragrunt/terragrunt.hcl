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
#   streams = {
#     "raw_events" = {
#       database    = "DB_ANALYTICS"
#       schema      = "ETL"
#       name        = "STREAM_RAW_EVENTS"
#       table       = "\"DB_ANALYTICS\".\"RAW\".\"EVENTS\""
#       append_only = true
#     }
#   }
# }

inputs = {
  streams = {
    "example" = {
      database = "DB_EXAMPLE"
      schema   = "SCHEMA_EXAMPLE"
      name     = "STREAM_EXAMPLE"
      table    = "\"DB_EXAMPLE\".\"SCHEMA_EXAMPLE\".\"TABLE_EXAMPLE\""
    }
  }
}
