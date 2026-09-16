terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   access_policies = {
#     "org" = {
#       parent = "organizations/123456789"
#       title  = "example-org-policy"
#     }
#   }
#   service_perimeters = {
#     "storage" = {
#       policy_key = "org"
#       name       = "restrict_storage"
#       title      = "Restrict Storage"
#       status = {
#         restricted_services = ["storage.googleapis.com"]
#       }
#     }
#   }
# }

inputs = {
  access_policies      = {}
  access_levels        = {}
  service_perimeters   = {}
  perimeter_resources  = {}
}
