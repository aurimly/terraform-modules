terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   project_roles = {
#     "example" = {
#       role_id     = "exampleDeployer"
#       title       = "Example Deployer"
#       permissions = ["run.services.get"]
#     }
#   }
# }

inputs = {
  organization_roles = {}
  project_roles      = {}
}
