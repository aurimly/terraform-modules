terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   network_areas = {
#     "prod" = {
#       organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       name            = "prod-network-area"
#       labels = {
#         "env" = "prod"
#       }
#     },
#   }
# }

inputs = {
  network_areas = {}
}
