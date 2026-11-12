terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   trails = {
#     "audit" = {
#       name                       = "example-audit-trail"
#       s3_bucket_name             = "example-audit-logs"
#       s3_key_prefix              = "cloudtrail"
#       is_multi_region_trail      = true
#       enable_log_file_validation = true
#       kms_key_id                 = "arn:aws:kms:eu-central-1:123456789012:key/example"
#       cloud_watch_logs_group_arn = "arn:aws:logs:eu-central-1:123456789012:log-group:/example/audit"
#       cloud_watch_logs_role_arn  = "arn:aws:iam::123456789012:role/example-cloudtrail-logs"
#       advanced_event_selectors = {
#         "s3-data" = {
#           name = "example-s3-data-events"
#           field_selectors = {
#             "category" = { field = "eventCategory", equals = ["Data"] }
#             "type"     = { field = "resources.type", equals = ["AWS::S3::Object"] }
#           }
#         }
#       }
#     }
#     "org" = {
#       name                   = "example-org-trail"
#       s3_bucket_name         = "example-audit-logs"
#       is_organization_trail  = true
#       is_multi_region_trail  = true
#     }
#   }
# }

inputs = {
  trails = {}
}
