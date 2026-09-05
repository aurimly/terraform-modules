terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   subnets = {
#     "example-app" = {
#       name          = "example-app"
#       network       = "example-vpc"
#       region        = "us-central1"
#       ip_cidr_range = "10.0.0.0/24"
#     },
#     "example-gke" = {
#       name                     = "example-gke"
#       network                  = "projects/example-project-1234/global/networks/example-vpc"
#       region                   = "us-central1"
#       ip_cidr_range            = "10.1.0.0/20"
#       private_ip_google_access = true
#       secondary_ranges = [
#         { range_name = "pods",     ip_cidr_range = "10.8.0.0/14" },
#         { range_name = "services", ip_cidr_range = "10.12.0.0/20" },
#       ]
#     },
#     "example-mon" = {
#       name          = "example-mon"
#       network       = "example-vpc"
#       region        = "europe-west4"
#       ip_cidr_range = "10.2.0.0/24"
#       flow_log = {
#         aggregation_interval = "INTERVAL_10_MIN"
#         flow_sampling        = 0.5
#       }
#     },
#   }
# }

inputs = {
  subnets = {}
}
