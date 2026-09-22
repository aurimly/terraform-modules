terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   security_groups = {
#     "app" = {
#       name        = "example-app"
#       description = "Example application tier"
#       vpc_id      = "vpc-0123456789abcdef0"
#       ingress = {
#         "https" = {
#           description = "HTTPS from anywhere"
#           protocol    = "tcp"
#           cidr_ipv4   = "0.0.0.0/0"
#           from_port   = 443
#           to_port     = 443
#         }
#       }
#       egress = {
#         "all" = {
#           description = "Allow all outbound"
#           protocol    = "-1"
#           cidr_ipv4   = "0.0.0.0/0"
#         }
#       }
#     },
#   }
# }

inputs = {
  security_groups = {}
}
