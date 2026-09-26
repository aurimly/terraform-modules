terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   distributions = {
#     "web" = {
#       default_root_object = "index.html"
#       origins = {
#         "s3" = {
#           domain_name = "example-bucket.s3.us-east-1.amazonaws.com"
#           oac         = {}
#         }
#       }
#       default_cache_behavior = {
#         target_origin_id       = "s3"
#         viewer_protocol_policy = "redirect-to-https"
#         cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e27f2"
#       }
#     }
#   }
# }

inputs = {
  distributions = {}
}
