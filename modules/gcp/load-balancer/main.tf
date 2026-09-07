resource "google_compute_health_check" "health_check" {
  for_each = var.health_checks

  name                = each.value.name
  project             = each.value.project_id
  description         = each.value.description
  check_interval_sec  = each.value.check_interval_sec
  timeout_sec         = each.value.timeout_sec
  healthy_threshold   = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold
  source_regions      = each.value.source_regions

  dynamic "http_health_check" {
    for_each = each.value.http_health_check != null ? [each.value.http_health_check] : []

    content {
      host               = http_health_check.value.host
      request_path       = http_health_check.value.request_path
      response           = http_health_check.value.response
      port               = http_health_check.value.port
      port_name          = http_health_check.value.port_name
      proxy_header       = http_health_check.value.proxy_header
      port_specification = http_health_check.value.port_specification
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.https_health_check != null ? [each.value.https_health_check] : []

    content {
      host               = https_health_check.value.host
      request_path       = https_health_check.value.request_path
      response           = https_health_check.value.response
      port               = https_health_check.value.port
      port_name          = https_health_check.value.port_name
      proxy_header       = https_health_check.value.proxy_header
      port_specification = https_health_check.value.port_specification
    }
  }

  dynamic "http2_health_check" {
    for_each = each.value.http2_health_check != null ? [each.value.http2_health_check] : []

    content {
      host               = http2_health_check.value.host
      request_path       = http2_health_check.value.request_path
      response           = http2_health_check.value.response
      port               = http2_health_check.value.port
      port_name          = http2_health_check.value.port_name
      proxy_header       = http2_health_check.value.proxy_header
      port_specification = http2_health_check.value.port_specification
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.tcp_health_check != null ? [each.value.tcp_health_check] : []

    content {
      request            = tcp_health_check.value.request
      response           = tcp_health_check.value.response
      port               = tcp_health_check.value.port
      port_name          = tcp_health_check.value.port_name
      proxy_header       = tcp_health_check.value.proxy_header
      port_specification = tcp_health_check.value.port_specification
    }
  }

  dynamic "ssl_health_check" {
    for_each = each.value.ssl_health_check != null ? [each.value.ssl_health_check] : []

    content {
      request            = ssl_health_check.value.request
      response           = ssl_health_check.value.response
      port               = ssl_health_check.value.port
      port_name          = ssl_health_check.value.port_name
      proxy_header       = ssl_health_check.value.proxy_header
      port_specification = ssl_health_check.value.port_specification
    }
  }

  dynamic "grpc_health_check" {
    for_each = each.value.grpc_health_check != null ? [each.value.grpc_health_check] : []

    content {
      port               = grpc_health_check.value.port
      port_name          = grpc_health_check.value.port_name
      port_specification = grpc_health_check.value.port_specification
      grpc_service_name  = grpc_health_check.value.grpc_service_name
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      enable = log_config.value.enable
    }
  }
}

resource "google_compute_region_health_check" "region_health_check" {
  for_each = var.regional_health_checks

  name                = each.value.name
  project             = each.value.project_id
  region              = each.value.region
  description         = each.value.description
  check_interval_sec  = each.value.check_interval_sec
  timeout_sec         = each.value.timeout_sec
  healthy_threshold   = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold

  dynamic "http_health_check" {
    for_each = each.value.http_health_check != null ? [each.value.http_health_check] : []

    content {
      host               = http_health_check.value.host
      request_path       = http_health_check.value.request_path
      response           = http_health_check.value.response
      port               = http_health_check.value.port
      port_name          = http_health_check.value.port_name
      proxy_header       = http_health_check.value.proxy_header
      port_specification = http_health_check.value.port_specification
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.https_health_check != null ? [each.value.https_health_check] : []

    content {
      host               = https_health_check.value.host
      request_path       = https_health_check.value.request_path
      response           = https_health_check.value.response
      port               = https_health_check.value.port
      port_name          = https_health_check.value.port_name
      proxy_header       = https_health_check.value.proxy_header
      port_specification = https_health_check.value.port_specification
    }
  }

  dynamic "http2_health_check" {
    for_each = each.value.http2_health_check != null ? [each.value.http2_health_check] : []

    content {
      host               = http2_health_check.value.host
      request_path       = http2_health_check.value.request_path
      response           = http2_health_check.value.response
      port               = http2_health_check.value.port
      port_name          = http2_health_check.value.port_name
      proxy_header       = http2_health_check.value.proxy_header
      port_specification = http2_health_check.value.port_specification
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.tcp_health_check != null ? [each.value.tcp_health_check] : []

    content {
      request            = tcp_health_check.value.request
      response           = tcp_health_check.value.response
      port               = tcp_health_check.value.port
      port_name          = tcp_health_check.value.port_name
      proxy_header       = tcp_health_check.value.proxy_header
      port_specification = tcp_health_check.value.port_specification
    }
  }

  dynamic "ssl_health_check" {
    for_each = each.value.ssl_health_check != null ? [each.value.ssl_health_check] : []

    content {
      request            = ssl_health_check.value.request
      response           = ssl_health_check.value.response
      port               = ssl_health_check.value.port
      port_name          = ssl_health_check.value.port_name
      proxy_header       = ssl_health_check.value.proxy_header
      port_specification = ssl_health_check.value.port_specification
    }
  }

  dynamic "grpc_health_check" {
    for_each = each.value.grpc_health_check != null ? [each.value.grpc_health_check] : []

    content {
      port               = grpc_health_check.value.port
      port_name          = grpc_health_check.value.port_name
      port_specification = grpc_health_check.value.port_specification
      grpc_service_name  = grpc_health_check.value.grpc_service_name
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      enable = log_config.value.enable
    }
  }
}

resource "google_compute_backend_service" "backend_service" {
  for_each = var.backend_services

  name                            = each.value.name
  project                         = each.value.project_id
  description                     = each.value.description
  affinity_cookie_ttl_sec         = each.value.affinity_cookie_ttl_sec
  compression_mode                = each.value.compression_mode
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  custom_request_headers          = each.value.custom_request_headers
  custom_response_headers         = each.value.custom_response_headers
  enable_cdn                      = each.value.enable_cdn
  load_balancing_scheme           = each.value.load_balancing_scheme
  locality_lb_policy              = each.value.locality_lb_policy
  port_name                       = each.value.port_name
  protocol                        = each.value.protocol
  security_policy                 = each.value.security_policy
  session_affinity                = each.value.session_affinity
  timeout_sec                     = each.value.timeout_sec
  service_lb_policy               = each.value.service_lb_policy

  # Keys into the health_checks variable, resolved to the health check IDs;
  # the reference creates the implicit dependency.
  health_checks = length(each.value.health_checks) > 0 ? [for hc in each.value.health_checks : google_compute_health_check.health_check[hc].id] : null

  dynamic "backend" {
    for_each = each.value.backends

    content {
      balancing_mode               = backend.value.balancing_mode
      capacity_scaler              = backend.value.capacity_scaler
      description                  = backend.value.description
      group                        = backend.value.group
      max_connections              = backend.value.max_connections
      max_connections_per_instance = backend.value.max_connections_per_instance
      max_connections_per_endpoint = backend.value.max_connections_per_endpoint
      max_rate                     = backend.value.max_rate
      max_rate_per_instance        = backend.value.max_rate_per_instance
      max_rate_per_endpoint        = backend.value.max_rate_per_endpoint
      max_utilization              = backend.value.max_utilization
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      enable      = log_config.value.enable
      sample_rate = log_config.value.sample_rate
    }
  }
}

resource "google_compute_region_backend_service" "region_backend_service" {
  for_each = var.regional_backend_services

  name                            = each.value.name
  project                         = each.value.project_id
  region                          = each.value.region
  description                     = each.value.description
  affinity_cookie_ttl_sec         = each.value.affinity_cookie_ttl_sec
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  enable_cdn                      = each.value.enable_cdn
  load_balancing_scheme           = each.value.load_balancing_scheme
  locality_lb_policy              = each.value.locality_lb_policy
  network                         = each.value.network
  port_name                       = each.value.port_name
  protocol                        = each.value.protocol
  security_policy                 = each.value.security_policy
  session_affinity                = each.value.session_affinity
  timeout_sec                     = each.value.timeout_sec

  # Keys into the regional_health_checks variable, resolved to the health
  # check IDs; the reference creates the implicit dependency.
  health_checks = length(each.value.health_checks) > 0 ? [for hc in each.value.health_checks : google_compute_region_health_check.region_health_check[hc].id] : null

  dynamic "backend" {
    for_each = each.value.backends

    content {
      balancing_mode               = backend.value.balancing_mode
      capacity_scaler              = backend.value.capacity_scaler
      description                  = backend.value.description
      group                        = backend.value.group
      max_connections              = backend.value.max_connections
      max_connections_per_instance = backend.value.max_connections_per_instance
      max_connections_per_endpoint = backend.value.max_connections_per_endpoint
      max_rate                     = backend.value.max_rate
      max_rate_per_instance        = backend.value.max_rate_per_instance
      max_rate_per_endpoint        = backend.value.max_rate_per_endpoint
      max_utilization              = backend.value.max_utilization
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      enable      = log_config.value.enable
      sample_rate = log_config.value.sample_rate
    }
  }
}

resource "google_compute_backend_bucket" "backend_bucket" {
  for_each = var.backend_buckets

  name                    = each.value.name
  project                 = each.value.project_id
  bucket_name             = each.value.bucket_name
  description             = each.value.description
  enable_cdn              = each.value.enable_cdn
  compression_mode        = each.value.compression_mode
  edge_security_policy    = each.value.edge_security_policy
  custom_response_headers = each.value.custom_response_headers

  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? [each.value.cdn_policy] : []

    content {
      signed_url_cache_max_age_sec = cdn_policy.value.signed_url_cache_max_age_sec
      default_ttl                  = cdn_policy.value.default_ttl
      max_ttl                      = cdn_policy.value.max_ttl
      client_ttl                   = cdn_policy.value.client_ttl
      negative_caching             = cdn_policy.value.negative_caching
      cache_mode                   = cdn_policy.value.cache_mode
      serve_while_stale            = cdn_policy.value.serve_while_stale
      request_coalescing           = cdn_policy.value.request_coalescing

      dynamic "cache_key_policy" {
        for_each = cdn_policy.value.cache_key_policy != null ? [cdn_policy.value.cache_key_policy] : []

        content {
          query_string_whitelist = cache_key_policy.value.query_string_whitelist
          include_http_headers   = cache_key_policy.value.include_http_headers
        }
      }
    }
  }
}

resource "google_compute_url_map" "url_map" {
  for_each = var.url_maps

  name            = each.value.name
  project         = each.value.project_id
  description     = each.value.description
  default_service = each.value.default_service

  dynamic "default_url_redirect" {
    for_each = each.value.default_url_redirect != null ? [each.value.default_url_redirect] : []

    content {
      strip_query            = default_url_redirect.value.strip_query
      https_redirect         = default_url_redirect.value.https_redirect
      redirect_response_code = default_url_redirect.value.redirect_response_code
    }
  }

  dynamic "default_route_action" {
    for_each = each.value.default_route_action != null ? [each.value.default_route_action] : []

    content {
      dynamic "cors_policy" {
        for_each = default_route_action.value.cors_policy != null ? [default_route_action.value.cors_policy] : []

        content {
          allow_credentials    = cors_policy.value.allow_credentials
          allow_headers        = cors_policy.value.allow_headers
          allow_methods        = cors_policy.value.allow_methods
          allow_origin_regexes = cors_policy.value.allow_origin_regexes
          allow_origins        = cors_policy.value.allow_origins
          disabled             = cors_policy.value.disabled
          expose_headers       = cors_policy.value.expose_headers
          max_age              = cors_policy.value.max_age
        }
      }
    }
  }

  dynamic "host_rule" {
    for_each = each.value.host_rules

    content {
      description  = host_rule.value.description
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }

  dynamic "path_matcher" {
    for_each = each.value.path_matchers

    content {
      name            = path_matcher.value.name
      description     = path_matcher.value.description
      default_service = path_matcher.value.default_service

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules

        content {
          service = path_rule.value.service
          paths   = path_rule.value.paths
        }
      }
    }
  }

  # default_service and path_rules[].service are free strings that may point
  # at backend services or buckets created in this module.
  depends_on = [google_compute_backend_service.backend_service, google_compute_backend_bucket.backend_bucket]
}

resource "google_compute_region_url_map" "region_url_map" {
  for_each = var.regional_url_maps

  name            = each.value.name
  project         = each.value.project_id
  region          = each.value.region
  description     = each.value.description
  default_service = each.value.default_service

  dynamic "default_url_redirect" {
    for_each = each.value.default_url_redirect != null ? [each.value.default_url_redirect] : []

    content {
      strip_query            = default_url_redirect.value.strip_query
      https_redirect         = default_url_redirect.value.https_redirect
      redirect_response_code = default_url_redirect.value.redirect_response_code
    }
  }

  dynamic "default_route_action" {
    for_each = each.value.default_route_action != null ? [each.value.default_route_action] : []

    content {
      dynamic "cors_policy" {
        for_each = default_route_action.value.cors_policy != null ? [default_route_action.value.cors_policy] : []

        content {
          allow_credentials    = cors_policy.value.allow_credentials
          allow_headers        = cors_policy.value.allow_headers
          allow_methods        = cors_policy.value.allow_methods
          allow_origin_regexes = cors_policy.value.allow_origin_regexes
          allow_origins        = cors_policy.value.allow_origins
          disabled             = cors_policy.value.disabled
          expose_headers       = cors_policy.value.expose_headers
          max_age              = cors_policy.value.max_age
        }
      }
    }
  }

  dynamic "host_rule" {
    for_each = each.value.host_rules

    content {
      description  = host_rule.value.description
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }

  dynamic "path_matcher" {
    for_each = each.value.path_matchers

    content {
      name            = path_matcher.value.name
      description     = path_matcher.value.description
      default_service = path_matcher.value.default_service

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules

        content {
          service = path_rule.value.service
          paths   = path_rule.value.paths
        }
      }
    }
  }

  depends_on = [google_compute_region_backend_service.region_backend_service]
}

resource "google_compute_target_http_proxy" "http_proxy" {
  for_each = var.http_proxies

  name                        = each.value.name
  project                     = each.value.project_id
  description                 = each.value.description
  proxy_bind                  = each.value.proxy_bind
  http_keep_alive_timeout_sec = each.value.http_keep_alive_timeout_sec

  # Key into the url_maps variable, resolved to the URL map self link.
  url_map = google_compute_url_map.url_map[each.value.url_map].self_link
}

resource "google_compute_target_https_proxy" "https_proxy" {
  for_each = var.https_proxies

  name                             = each.value.name
  project                          = each.value.project_id
  description                      = each.value.description
  quic_override                    = each.value.quic_override
  tls_early_data                   = each.value.tls_early_data
  ssl_certificates                 = each.value.ssl_certificates
  certificate_map                  = each.value.certificate_map
  certificate_manager_certificates = each.value.certificate_manager_certificates
  ssl_policy                       = each.value.ssl_policy
  http_keep_alive_timeout_sec      = each.value.http_keep_alive_timeout_sec
  server_tls_policy                = each.value.server_tls_policy

  # Key into the url_maps variable, resolved to the URL map self link.
  url_map = google_compute_url_map.url_map[each.value.url_map].self_link
}

resource "google_compute_region_target_http_proxy" "region_http_proxy" {
  for_each = var.regional_http_proxies

  name                        = each.value.name
  project                     = each.value.project_id
  region                      = each.value.region
  description                 = each.value.description
  http_keep_alive_timeout_sec = each.value.http_keep_alive_timeout_sec

  # Key into the regional_url_maps variable, resolved to the URL map self link.
  url_map = google_compute_region_url_map.region_url_map[each.value.url_map].self_link
}

resource "google_compute_region_target_https_proxy" "region_https_proxy" {
  for_each = var.regional_https_proxies

  name                             = each.value.name
  project                          = each.value.project_id
  region                           = each.value.region
  description                      = each.value.description
  ssl_certificates                 = each.value.ssl_certificates
  certificate_manager_certificates = each.value.certificate_manager_certificates
  ssl_policy                       = each.value.ssl_policy
  server_tls_policy                = each.value.server_tls_policy
  http_keep_alive_timeout_sec      = each.value.http_keep_alive_timeout_sec

  # Key into the regional_url_maps variable, resolved to the URL map self link.
  url_map = google_compute_region_url_map.region_url_map[each.value.url_map].self_link
}

resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  for_each = var.global_forwarding_rules

  name                  = each.value.name
  project               = each.value.project_id
  description           = each.value.description
  target                = each.value.target
  ip_address            = each.value.ip_address
  ip_protocol           = each.value.ip_protocol
  ip_version            = each.value.ip_version
  labels                = each.value.labels
  load_balancing_scheme = each.value.load_balancing_scheme
  network               = each.value.network
  port_range            = each.value.port_range
  subnetwork            = each.value.subnetwork
  source_ip_ranges      = each.value.source_ip_ranges
  no_automate_dns_zone  = each.value.no_automate_dns_zone

  dynamic "service_directory_registrations" {
    for_each = each.value.service_directory_registrations != null ? [each.value.service_directory_registrations] : []

    content {
      namespace                = service_directory_registrations.value.namespace
      service_directory_region = service_directory_registrations.value.service_directory_region
    }
  }

  # target is a free string that may point at a target proxy created in
  # this module.
  depends_on = [google_compute_target_http_proxy.http_proxy, google_compute_target_https_proxy.https_proxy]
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  for_each = var.forwarding_rules

  name                    = each.value.name
  project                 = each.value.project_id
  region                  = each.value.region
  description             = each.value.description
  target                  = each.value.target
  ip_address              = each.value.ip_address
  ip_protocol             = each.value.ip_protocol
  backend_service         = each.value.backend_service
  load_balancing_scheme   = each.value.load_balancing_scheme
  network                 = each.value.network
  port_range              = each.value.port_range
  ports                   = each.value.ports
  subnetwork              = each.value.subnetwork
  allow_global_access     = each.value.allow_global_access
  all_ports               = each.value.all_ports
  network_tier            = each.value.network_tier
  service_label           = each.value.service_label
  source_ip_ranges        = each.value.source_ip_ranges
  allow_psc_global_access = each.value.allow_psc_global_access
  no_automate_dns_zone    = each.value.no_automate_dns_zone
  ip_version              = each.value.ip_version
  recreate_closed_psc     = each.value.recreate_closed_psc
  is_mirroring_collector  = each.value.is_mirroring_collector

  dynamic "service_directory_registrations" {
    for_each = each.value.service_directory_registrations != null ? [each.value.service_directory_registrations] : []

    content {
      namespace = service_directory_registrations.value.namespace
      service   = service_directory_registrations.value.service
    }
  }

  # target is a free string that may point at a target proxy created in
  # this module.
  depends_on = [google_compute_region_target_http_proxy.region_http_proxy, google_compute_region_target_https_proxy.region_https_proxy]
}
