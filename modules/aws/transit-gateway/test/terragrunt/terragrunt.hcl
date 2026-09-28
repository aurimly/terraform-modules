terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   gateways = {
#     "core" = {
#       name            = "example-core"
#       amazon_side_asn = 64512
#       default_route_table_association = "disable"
#       default_route_table_propagation = "disable"
#     },
#   }
#   route_tables = {
#     "prod" = {
#       gateway_key = "core"
#       name        = "example-prod"
#     },
#   }
#   vpc_attachments = {
#     "prod-a" = {
#       name       = "example-prod-a"
#       gateway_key = "core"
#       vpc_id     = dependency.network.outputs.vpc_ids["prod-a"]
#       subnet_ids = dependency.network.outputs.private_subnet_ids["prod-a"]
#       transit_gateway_default_route_table_association = false
#     },
#   }
#   peerings = {
#     "hub" = {
#       name                    = "example-to-hub"
#       gateway_key             = "core"
#       peer_transit_gateway_id = "tgw-0fedcba9876543210"
#       peer_region             = "us-east-1"
#     },
#   }
#   peering_accepters = {
#     "hub" = {
#       transit_gateway_attachment_id = "tgw-attach-0123456789abcdef0"
#     },
#   }
#   routes = {
#     "blackhole-lease" = {
#       route_table_key       = "prod"
#       destination_cidr_block = "0.0.0.0/0"
#       blackhole             = true
#     },
#   }
#   associations = {
#     "prod-a" = {
#       route_table_key = "prod"
#       attachment_key  = "prod-a"
#     },
#   }
#   propagations = {
#     "prod-from-shared" = {
#       route_table_key = "prod"
#       attachment_key  = "shared"
#     },
#   }
# }

inputs = {
  gateways          = {}
  route_tables      = {}
  vpc_attachments   = {}
  peerings          = {}
  peering_accepters = {}
  routes            = {}
  associations      = {}
  propagations      = {}
}
