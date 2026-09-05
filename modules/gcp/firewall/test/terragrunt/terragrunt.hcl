terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   firewalls = {
#     "ssh" = {
#       name          = "example-allow-ssh-ingress"
#       network       = "example-vpc"
#       direction     = "INGRESS"
#       source_ranges = ["203.0.113.0/24"]
#       allow = [
#         { protocol = "tcp", ports = ["22"] },
#       ]
#     },
#   }
# }

inputs = {
  firewalls = {}
}
