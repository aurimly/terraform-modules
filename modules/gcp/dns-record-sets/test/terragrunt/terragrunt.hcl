terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   managed_zone_name = "example-org-public"
#   record_sets = {
#     "apex" = {
#       name    = "example.com."
#       type    = "A"
#       rrdatas = ["203.0.113.10"]
#     }
#   }
# }

inputs = {
  managed_zone_name = "example-zone"
  record_sets       = {}
}
