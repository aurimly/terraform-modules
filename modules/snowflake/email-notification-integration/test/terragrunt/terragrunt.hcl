terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Snowflake, replace the inputs
# below with real values (needs a Snowflake account; the provider config lives
# at the consumer unit level and must opt the integration resource into
# preview: preview_features_enabled = ["snowflake_email_notification_integration_resource"]).
# terragrunt validate with the placeholder inputs needs no Snowflake
# connection — nothing here calls the API.
#
# inputs = {
#   integrations = {
#     "monitoring" = {
#       name               = "NTF_MONITORING"
#       enabled            = true
#       allowed_recipients = ["oncall@example.com", "ops@example.com"]
#       comment            = "on-call notifications for monitoring alerts"
#     }
#   }
# }

inputs = {
  integrations = {
    "example" = {
      name               = "NTF_EXAMPLE"
      enabled            = true
      allowed_recipients = ["user@example.com"]
    }
  }
}
