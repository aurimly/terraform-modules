terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   security_groups = {
#     "web" = {
#       project_id  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       name        = "web-sg"
#       description = "Allow HTTP/HTTPS from anywhere"
#       rules = {
#         "http" = {
#           direction      = "ingress"
#           protocol_name  = "tcp"
#           port_range = {
#             min = 80
#             max = 80
#           }
#           ip_range = "0.0.0.0/0"
#         },
#         "ping" = {
#           direction       = "ingress"
#           protocol_name   = "icmp"
#           icmp_parameters = {
#             type = 8
#             code = 0
#           }
#         },
#       }
#     },
#     "monitoring" = {
#       project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       name       = "monitoring-sg"
#     },
#   }
# }

inputs = {
  security_groups = {}
}
