terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   connectors = {
#     "shared" = {
#       name   = "example-shared-conn"
#       subnet = { name = "example-subnet", project_id = "example-host-prj" }
#     }
#   }
# }

inputs = {
  connectors = {}
}
