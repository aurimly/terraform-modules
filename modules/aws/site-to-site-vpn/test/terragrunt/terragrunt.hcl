terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   vpn_gateways = {
#     "main" = {
#       name            = "example-vgw"
#       vpc_id          = "vpc-0123456789abcdef0"
#       amazon_side_asn = 64512
#     },
#   }
#   customer_gateways = {
#     "gcp" = {
#       name       = "example-gcp-peer"
#       bgp_asn    = 64512
#       ip_address = "203.0.113.10"
#     },
#   }
#   connections = {
#     "main" = {
#       customer_gateway   = "gcp"
#       vpn_gateway        = "main"
#       static_routes_only = false
#       tunnel1 = {
#         pre_shared_key = "example-psk-tunnel0"
#         inside_cidr    = "169.254.0.0/30"
#       }
#       tunnel2 = {
#         pre_shared_key = "example-psk-tunnel1"
#         inside_cidr    = "169.254.1.0/30"
#       }
#     },
#   }
# }

inputs = {
  vpn_gateways      = {}
  customer_gateways = {}
  connections       = {}
}
