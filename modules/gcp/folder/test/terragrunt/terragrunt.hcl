terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs
# below with real values (needs GCP creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   folders = {
#     "example-team" = {
#       display_name = "team-a"
#       parent       = "organizations/123456789012"
#     },
#     "example-env" = {
#       display_name        = "prod"
#       parent              = "folders/987654321098"
#       deletion_protection = false
#       deletion_policy     = "DELETE"
#       tags = {
#         "tagKeys/281472992016542" = "tagValues/281475003921481"
#       }
#     },
#   }
# }

inputs = {
  folders = {}
}
