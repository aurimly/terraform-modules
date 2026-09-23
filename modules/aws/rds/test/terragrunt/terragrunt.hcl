terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   instances = {
#     "legacy" = {
#       identifier        = "example-legacy-db"
#       engine            = "postgres"
#       instance_class    = "db.t3.medium"
#       allocated_storage = 50
#       db_subnet_group_name = "example-db-subnet-group"
#     },
#   }
# }

inputs = {
  instances = {}
  clusters  = {}
}
