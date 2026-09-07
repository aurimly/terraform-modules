terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   health_checks = {
#     "web" = {
#       name = "example-web-hc"
#       http_health_check = {
#         request_path = "/healthz"
#       }
#     },
#   }
#   backend_services = {
#     "app" = {
#       name          = "example-app-bes"
#       port_name     = "http"
#       health_checks = ["web"]
#       backends = [
#         { group = "projects/example-project-1234/zones/us-central1-a/instanceGroups/example-ig" },
#       ]
#     },
#   }
#   url_maps = {
#     "web" = {
#       name            = "example-web-urlmap"
#       default_service = "projects/example-project-1234/global/backendServices/example-app-bes"
#     },
#   }
#   https_proxies = {
#     "web" = {
#       name             = "example-web-proxy"
#       url_map          = "web"
#       ssl_certificates = ["projects/example-project-1234/global/sslCertificates/example-cert"]
#     },
#   }
#   global_forwarding_rules = {
#     "web" = {
#       name       = "example-web-fr"
#       target     = "projects/example-project-1234/global/targetHttpsProxies/example-web-proxy"
#       port_range = "443-443"
#       ip_address = "projects/example-project-1234/global/addresses/example-lb-ip"
#     },
#   }
# }

inputs = {
  backend_services          = {}
  regional_backend_services = {}
  backend_buckets           = {}
  health_checks             = {}
  regional_health_checks    = {}
  url_maps                  = {}
  regional_url_maps         = {}
  http_proxies              = {}
  https_proxies             = {}
  regional_http_proxies     = {}
  regional_https_proxies    = {}
  global_forwarding_rules   = {}
  forwarding_rules          = {}
}
