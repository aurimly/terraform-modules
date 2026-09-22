terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   vpcs = {
#     "main" = {
#       name       = "example-vpc"
#       cidr_block = "10.0.0.0/16"
#       tags = {
#         Environment = "example"
#       }
#     },
#   }
# }

inputs = {
  vpcs = {}
}
