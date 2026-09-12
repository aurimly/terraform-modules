terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   network_interfaces = {
#     "app-nic" = {
#       project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       network_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       region     = "eu01"
#       name       = "app-nic"
#       security_group_ids = [
#         "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz",
#       ]
#       labels = {
#         "env" = "prod"
#       }
#     },
#   }
# }

inputs = {
  network_interfaces = {}
}
