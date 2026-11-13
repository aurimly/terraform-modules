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
#   pipes = {
#     "load_events" = {
#       database          = "DB_ANALYTICS"
#       schema            = "RAW"
#       name              = "PIPE_LOAD_EVENTS"
#       copy_statement    = "COPY INTO \"DB_ANALYTICS\".\"RAW\".\"EVENTS\" FROM \"DB_ANALYTICS\".\"RAW\".\"STAGE_RAW\" FILE_FORMAT = (TYPE = PARQUET)"
#       auto_ingest       = true
#       aws_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:stage-events"
#     }
#   }
# }

inputs = {
  pipes = {
    "example" = {
      database       = "DB_EXAMPLE"
      schema         = "SCHEMA_EXAMPLE"
      name           = "PIPE_EXAMPLE"
      copy_statement = "COPY INTO \"DB_EXAMPLE\".\"SCHEMA_EXAMPLE\".\"TABLE_EXAMPLE\" FROM \"DB_EXAMPLE\".\"SCHEMA_EXAMPLE\".\"STAGE_EXAMPLE\" FILE_FORMAT = (TYPE = PARQUET)"
    }
  }
}
