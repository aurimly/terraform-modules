terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   tcp_proxies = {
#     "app" = {
#       name            = "example-app-tcp-proxy"
#       backend_service = "projects/example-prj/global/backendServices/example-app-tcp-bes"
#     }
#   }
# }

inputs = {
  tcp_proxies          = {}
  regional_tcp_proxies = {}
  ssl_proxies          = {}
  grpc_proxies         = {}
}
