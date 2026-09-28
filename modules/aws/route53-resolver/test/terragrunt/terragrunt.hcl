terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   endpoints = {
#     "out" = {
#       name               = "example-outbound"
#       direction          = "OUTBOUND"
#       security_group_ids = dependency.security_groups.outputs.security_group_ids["resolver-out"]
#       ip_addresses = [
#         { subnet_id = dependency.network.outputs.private_subnet_ids["a"] },
#         { subnet_id = dependency.network.outputs.private_subnet_ids["b"] },
#       ]
#     },
#   }
#   rules = {
#     "corp" = {
#       domain_name  = "corp.example.com"
#       rule_type    = "FORWARD"
#       endpoint_key = "out"
#       target_ips = [
#         { ip = "10.0.8.10" },
#         { ip = "10.0.16.10" },
#       ]
#     },
#   }
#   associations = {
#     "corp-prod" = {
#       rule_key = "corp"
#       vpc_id   = dependency.network.outputs.vpc_ids["prod"]
#     },
#   }
#   dnssec_configs = {
#     "prod" = {
#       vpc_id = dependency.network.outputs.vpc_ids["prod"]
#     },
#   }
# }

inputs = {
  endpoints      = {}
  rules          = {}
  associations   = {}
  dnssec_configs = {}
}
