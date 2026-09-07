terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   templates = {
#     "web" = {
#       name_prefix  = "example-web-"
#       machine_type = "e2-medium"
#       disks = [
#         {
#           source_image = "debian-cloud/debian-12"
#           boot         = true
#           disk_type    = "pd-balanced"
#           disk_size_gb = 20
#         },
#       ]
#       network_interfaces = [
#         {
#           subnetwork = "projects/example-project-1234/regions/us-central1/subnetworks/example-app"
#         },
#       ]
#     },
#   }
# }

inputs = {
  templates = {}
}
