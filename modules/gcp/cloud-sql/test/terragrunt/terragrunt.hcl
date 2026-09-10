terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   instances = {
#     "example" = {
#       name             = "example-app-db"
#       database_version = "POSTGRES_16"
#       region           = "europe-west4"
#       tier             = "db-custom-2-7680"
#     }
#   }
# }

inputs = {
  instances = {}
}
