terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Snowflake, replace the inputs
# below with real values (needs a Snowflake account; the provider config lives
# at the consumer unit level, e.g. SNOWFLAKE_* env vars or ~/.snowflake/config).
# terragrunt validate with the placeholder inputs needs no Snowflake
# connection — nothing here calls the API. Note that attaching resource_monitor
# needs the ACCOUNTADMIN role as the executing role (see module README).
#
# inputs = {
#   warehouses = {
#     "analytics" = {
#       name                      = "WH_ANALYTICS"
#       warehouse_size            = "MEDIUM"
#       min_cluster_count         = 1
#       max_cluster_count         = 2
#       scaling_policy            = "ECONOMY"
#       auto_suspend              = 300
#       initially_suspended       = true
#       resource_monitor          = "warehouse-limits monitor fully_qualified_name"
#       statement_timeout_in_seconds = 3600
#     }
#   }
# }

inputs = {
  warehouses = {
    "example" = {
      name            = "WH_EXAMPLE"
      warehouse_size  = "XSMALL"
      auto_suspend    = 600
      auto_resume     = true
      resource_monitor = "\"RM_EXAMPLE\""
    }
  }
}
