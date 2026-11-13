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
#   views = {
#     "daily_orders" = {
#       database  = "DB_ANALYTICS"
#       schema    = "REPORT"
#       name      = "DAILY_ORDERS"
#       statement = "SELECT ORDER_DATE, SUM(AMOUNT) AS TOTAL FROM \"DB_ANALYTICS\".\"RAW\".\"ORDERS\" GROUP BY ORDER_DATE"
#       is_secure = true
#     }
#   }
# }

inputs = {
  views = {
    "example" = {
      database  = "DB_EXAMPLE"
      schema    = "SCHEMA_EXAMPLE"
      name      = "VIEW_EXAMPLE"
      statement = "SELECT ID, NAME FROM \"DB_EXAMPLE\".\"SCHEMA_EXAMPLE\".\"TABLE_EXAMPLE\""
    }
  }
}
