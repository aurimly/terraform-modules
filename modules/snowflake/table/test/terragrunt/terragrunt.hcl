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
#   tables = {
#     "events" = {
#       database = "DB_ANALYTICS"
#       schema   = "RAW"
#       name     = "EVENTS"
#       columns = [
#         {
#           name     = "EVENT_ID"
#           type     = "NUMBER(38,0)"
#           nullable = false
#           default = {
#             sequence = "DB_ANALYTICS.RAW.SEQ_EVENT_ID"
#           }
#         },
#         {
#           name = "CREATED_AT"
#           type = "TIMESTAMP_NTZ(9)"
#           default = {
#             expression = "CURRENT_TIMESTAMP()"
#           }
#         },
#       ]
#       cluster_by                  = ["CREATED_AT"]
#       data_retention_time_in_days = 30
#     }
#   }
# }

inputs = {
  tables = {
    "example" = {
      database = "DB_EXAMPLE"
      schema   = "SCHEMA_EXAMPLE"
      name     = "TABLE_EXAMPLE"
      columns = [
        {
          name     = "ID"
          type     = "NUMBER(38,0)"
          nullable = false
          default = {
            sequence = "DB_EXAMPLE.SCHEMA_EXAMPLE.SEQ_EXAMPLE"
          }
        },
        {
          name = "NAME"
          type = "VARCHAR(100)"
        },
      ]
    }
  }
}
