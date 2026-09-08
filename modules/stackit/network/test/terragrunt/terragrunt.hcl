terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   networks = {
#     "app" = {
#       project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       name       = "app-network"
#       region     = "eu01"
#       routed     = true
#     },
#     "db" = {
#       project_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       name             = "db-network"
#       region           = "eu01"
#       ipv4_prefix      = "10.1.0.0/24"
#       ipv4_nameservers = ["1.2.3.4", "5.6.7.8"]
#       labels = {
#         "env" = "prod"
#       }
#     },
#   }
# }

inputs = {
  networks = {}
}
