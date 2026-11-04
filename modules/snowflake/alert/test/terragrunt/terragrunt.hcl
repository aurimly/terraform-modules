terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Snowflake, replace the inputs
# below with real values (needs a Snowflake account; the provider config lives
# at the consumer unit level and must opt the alert resource into preview:
# preview_features_enabled = ["snowflake_alert_resource"]).
# terragrunt validate with the placeholder inputs needs no Snowflake
# connection — nothing here calls the API.
#
# inputs = {
#   alerts = {
#     "failed-logins" = {
#       database  = "SECURITY"
#       schema    = "MONITORING"
#       name      = "ALERT_FAILED_LOGINS"
#       warehouse = "WH_MONITORING"
#       condition = "SELECT COUNT(*) FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY WHERE IS_SUCCESS = 'NO' AND EVENT_TIMESTAMP > DATEADD('MINUTE', -10, CURRENT_TIMESTAMP())"
#       action    = "SELECT SYSTEM$SEND_EMAIL('ntf_monitoring', 'oncall@example.com', 'Failed logins detected', 'More than one failed login in the last 10 minutes')"
#       enabled   = true
#       alert_schedule = {
#         interval = 10
#       }
#     }
#   }
# }

inputs = {
  alerts = {
    "example" = {
      database  = "DB_EXAMPLE"
      schema    = "SCHEMA_EXAMPLE"
      name      = "ALERT_EXAMPLE"
      warehouse = "WH_EXAMPLE"
      condition = "SELECT 1"
      action    = "SELECT 1"
      alert_schedule = {
        interval = 10
      }
    }
  }
}
