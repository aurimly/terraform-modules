terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   services = {
#     "api" = {
#       name     = "example-api"
#       location = "europe-west4"
#       template = {
#         containers = [{ image = "europe-docker.pkg.dev/example-prj/example/example-api:1.2.3" }]
#       }
#     }
#   }
# }

inputs = {
  services = {}
}
