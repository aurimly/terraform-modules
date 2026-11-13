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
#   tasks = {
#     "load_root" = {
#       database      = "DB_ANALYTICS"
#       schema        = "ETL"
#       name          = "LOAD"
#       sql_statement = "CALL DB_ANALYTICS.ETL.LOAD_EVENTS()"
#       warehouse     = "WH_ETL"
#       schedule = {
#         using_cron = "0 2 * * * UTC"
#       }
#     }
#     "transform_child" = {
#       database      = "DB_ANALYTICS"
#       schema        = "ETL"
#       name          = "TRANSFORM"
#       sql_statement = "CALL DB_ANALYTICS.ETL.TRANSFORM_EVENTS()"
#       warehouse     = "WH_ETL"
#       after = [
#         "DB_ANALYTICS.ETL.LOAD",
#       ]
#     }
#   }
# }

inputs = {
  tasks = {
    "example" = {
      database      = "DB_EXAMPLE"
      schema        = "SCHEMA_EXAMPLE"
      name          = "TASK_EXAMPLE"
      sql_statement = "CALL DB_EXAMPLE.SCHEMA_EXAMPLE.PROC_EXAMPLE()"
      warehouse     = "WH_EXAMPLE"
      schedule = {
        minutes = 10
      }
    }
  }
}
