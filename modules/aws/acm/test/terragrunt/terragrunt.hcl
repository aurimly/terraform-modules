terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   zone_keys = dependency.zone.outputs.zone_ids
#   certificates = {
#     "wildcard" = {
#       domain_name               = "example.com"
#       subject_alternative_names = ["*.example.com"]
#       route53_zone              = "public"
#     },
#   }
# }

inputs = {
  certificates = {}
  zone_keys    = {}
}
