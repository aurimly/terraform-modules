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
#   resource_monitors = {
#     "warehouse-limits" = {
#       name                      = "RM_WAREHOUSE_LIMITS"
#       credit_quota              = 100
#       frequency                 = "WEEKLY"
#       start_timestamp           = "IMMEDIATELY"
#       notify_triggers           = [50, 90]
#       suspend_trigger           = 100
#       suspend_immediate_trigger = 120
#       notify_users              = ["TERRAFORM_SVC"]
#     }
#   }
# }

inputs = {
  resource_monitors = {
    "example" = {
      name            = "RM_EXAMPLE"
      credit_quota    = 100
      frequency       = "WEEKLY"
      start_timestamp = "IMMEDIATELY"
      notify_triggers = [50, 90]
      suspend_trigger = 100
    }
  }
}
