terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   org_policies = {
#     "require-os-login" = {
#       name   = "projects/example-project/policies/compute.requireOsLogin"
#       parent = "projects/example-project"
#       spec = {
#         rules = [
#           { enforce = "TRUE" },
#         ]
#       }
#     },
#     "restrict-subnetworks" = {
#       name   = "projects/example-project/policies/compute.restrictSharedVpcSubnetworks"
#       parent = "projects/example-project"
#       spec = {
#         rules = [
#           {
#             values = {
#               allowed_values = ["projects/example-host-project/regions/us-central1/subnetworks/example-subnet"]
#             }
#           },
#         ]
#       }
#     },
#   }
# }

inputs = {
  org_policies = {}
}
