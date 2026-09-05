terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   routers = {
#     "prod" = {
#       name    = "example-router"
#       network = "example-vpc"
#       region  = "us-central1"
#     },
#   }
#
#   nats = {
#     "prod" = {
#       name                               = "example-nat"
#       region                             = "us-central1"
#       router                             = "prod"
#       source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"
#     },
#   }
# }

inputs = {
  routers = {}
  nats    = {}
}
