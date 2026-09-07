terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   addresses = {
#     "vm" = {
#       name         = "example-vm-ip"
#       region       = "us-central1"
#       address_type = "INTERNAL"
#       subnetwork   = "projects/example-project-1234/regions/us-central1/subnetworks/example-app"
#     },
#   }
# }

inputs = {
  addresses = {}
}
