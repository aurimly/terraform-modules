terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   server_network_interface_attaches = {
#     "app-second-nic" = {
#       project_id           = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region               = "eu01"
#       server_id            = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       network_interface_id = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
#     },
#   }
# }

inputs = {
  server_network_interface_attaches = {}
}
