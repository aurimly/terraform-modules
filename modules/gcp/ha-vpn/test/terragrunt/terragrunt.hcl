terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   routers = {
#     "example" = {
#       name    = "example-vpn-router"
#       network = "example-vpc"
#       region  = "us-central1"
#       bgp = {
#         asn = 64512
#       }
#     },
#   }
#   gateways = {
#     "example" = {
#       name    = "example-ha-vpn"
#       network = "example-vpc"
#       region  = "us-central1"
#     },
#   }
#   external_gateways = {
#     "aws" = {
#       name            = "example-aws-peer"
#       redundancy_type = "TWO_IPS_REDUNDANCY"
#       interfaces = [
#         { id = 0, ip_address = "203.0.113.10" },
#         { id = 1, ip_address = "203.0.113.129" },
#       ]
#     },
#   }
#   tunnels = {
#     "tunnel0" = {
#       name                            = "example-vpn-tunnel-0"
#       region                          = "us-central1"
#       gateway                         = "example"
#       router                          = "example"
#       peer_external_gateway           = "aws"
#       peer_external_gateway_interface = 0
#       shared_secret_wo                = "example-psk-tunnel0"
#       shared_secret_wo_version        = 1
#     },
#     "tunnel1" = {
#       name                            = "example-vpn-tunnel-1"
#       region                          = "us-central1"
#       gateway                         = "example"
#       router                          = "example"
#       peer_external_gateway           = "aws"
#       peer_external_gateway_interface = 1
#       shared_secret_wo                = "example-psk-tunnel1"
#       shared_secret_wo_version        = 1
#     },
#   }
#   bgp_sessions = {
#     "tunnel0" = {
#       name     = "example-bgp-0"
#       tunnel   = "tunnel0"
#       peer_asn = 64512
#     },
#     "tunnel1" = {
#       name     = "example-bgp-1"
#       tunnel   = "tunnel1"
#       peer_asn = 64512
#     },
#   }
# }

inputs = {
  routers           = {}
  gateways          = {}
  external_gateways = {}
  tunnels           = {}
  bgp_sessions      = {}
}
