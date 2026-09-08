terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   public_ips = {
#     "lb" = {
#       project_id           = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region               = "eu01"
#       network_interface_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       labels = {
#         "env" = "prod"
#       }
#     },
#   }
# }

inputs = {
  public_ips = {}
}
