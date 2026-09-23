terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   load_balancers = {
#     "main" = {
#       name       = "example-alb"
#       subnet_ids = ["subnet-0a", "subnet-0b"]
#     },
#   }
# }

inputs = {
  load_balancers = {}
}
