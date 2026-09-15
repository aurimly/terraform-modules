terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   security_group_rules = {
#     "web-http" = {
#       project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region            = "eu01"
#       security_group_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       direction         = "ingress"
#       protocol_name     = "tcp"
#       port_range = {
#         min = 80
#         max = 80
#       }
#       ip_range = "0.0.0.0/0"
#     },
#   }
# }

inputs = {
  security_group_rules = {}
}
