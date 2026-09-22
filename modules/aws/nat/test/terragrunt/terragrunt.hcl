terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   nat_gateways = {
#     "az-a" = {
#       name      = "example-nat-us-east-1a"
#       subnet_id = "subnet-0123456789abcdef0"
#     },
#     "az-b" = {
#       name      = "example-nat-us-east-1b"
#       subnet_id = "subnet-0fffffffffffffff0"
#     },
#   }
# }

inputs = {
  nat_gateways = {}
}
