resource "google_compute_target_tcp_proxy" "tcp_proxy" {
  for_each = var.tcp_proxies

  name            = each.value.name
  backend_service = each.value.backend_service
  project         = each.value.project_id
  proxy_header    = each.value.proxy_header
  description     = each.value.description
  deletion_policy = each.value.deletion_policy
}

resource "google_compute_region_target_tcp_proxy" "regional_tcp_proxy" {
  for_each = var.regional_tcp_proxies

  name            = each.value.name
  backend_service = each.value.backend_service
  project         = each.value.project_id
  region          = each.value.region
  proxy_header    = each.value.proxy_header
  description     = each.value.description
  deletion_policy = each.value.deletion_policy
}

resource "google_compute_target_ssl_proxy" "ssl_proxy" {
  for_each = var.ssl_proxies

  name             = each.value.name
  backend_service  = each.value.backend_service
  project          = each.value.project_id
  description      = each.value.description
  proxy_header     = each.value.proxy_header
  ssl_policy       = each.value.ssl_policy
  certificate_map  = each.value.certificate_map
  deletion_policy  = each.value.deletion_policy
  ssl_certificates = each.value.ssl_certificates
}

resource "google_compute_target_grpc_proxy" "grpc_proxy" {
  for_each = var.grpc_proxies

  name                   = each.value.name
  project                = each.value.project_id
  description            = each.value.description
  url_map                = each.value.url_map
  validate_for_proxyless = each.value.validate_for_proxyless
  deletion_policy        = each.value.deletion_policy
}
