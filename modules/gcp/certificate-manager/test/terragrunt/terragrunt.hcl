terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   dns_authorizations = {
#     "a" = {
#       name   = "example-dns-auth"
#       domain = "service.example.com"
#     },
#   }
#   certificates = {
#     "edge" = {
#       name  = "example-edge-cert"
#       managed = {
#         domains            = ["service.example.com"]
#         dns_authorizations = ["a"]
#       }
#     },
#   }
#   certificate_maps = {
#     "lb" = {
#       name = "example-lb-cert-map"
#     }
#   }
#   certificate_map_entries = {
#     "sni" = {
#       map_key      = "lb"
#       name         = "example-sni-entry"
#       certificates = ["edge"]
#     }
#   }
# }

inputs = {
  dns_authorizations      = {}
  certificates            = {}
  certificate_maps        = {}
  certificate_map_entries = {}
}
