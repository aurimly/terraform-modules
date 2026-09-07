terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   instances = {
#     "web" = {
#       name         = "example-web-1"
#       zone         = "us-central1-a"
#       machine_type = "e2-medium"
#       boot_disk = {
#         image = "debian-cloud/debian-12"
#         size  = 20
#       }
#       network_interfaces = [
#         {
#           subnetwork = "projects/example-project-1234/regions/us-central1/subnetworks/example-app"
#         },
#       ]
#     },
#   }
# }

inputs = {
  instances = {}
}
