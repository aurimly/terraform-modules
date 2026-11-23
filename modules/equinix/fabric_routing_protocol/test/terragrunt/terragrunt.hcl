terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Equinix, replace the inputs
# below with real values (needs Equinix creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   direct_protocols = {
#     "dc-peer" = {
#       connection_uuid = "12345678-1234-1234-1234-123456789012"
#       name            = "example-direct"
#       direct_ipv4 = {
#         equinix_iface_ip = "192.168.0.1/30"
#       }
#     },
#   }
#   bgp_protocols = {
#     "dc-bgp" = {
#       connection_uuid = "12345678-1234-1234-1234-123456789012"
#       name            = "example-bgp"
#       customer_asn    = 65001
#       bgp_ipv4 = {
#         customer_peer_ip = "192.168.0.2"
#         enabled          = true
#       }
#     },
#   }
# }

inputs = {
  direct_protocols = {}
  bgp_protocols    = {}
}
