variable "backend_services" {
  description = "Map of global backend services keyed by an arbitrary identifier."
  type = map(object({
    name                            = string
    description                     = optional(string)
    project_id                      = optional(string)
    affinity_cookie_ttl_sec         = optional(number)
    compression_mode                = optional(string)
    connection_draining_timeout_sec = optional(number)
    custom_request_headers          = optional(list(string))
    custom_response_headers         = optional(list(string))
    enable_cdn                      = optional(bool)
    health_checks                   = optional(list(string), [])
    load_balancing_scheme           = optional(string)
    locality_lb_policy              = optional(string)
    port_name                       = optional(string)
    protocol                        = optional(string)
    security_policy                 = optional(string)
    session_affinity                = optional(string)
    timeout_sec                     = optional(number)
    service_lb_policy               = optional(string)
    backends = optional(list(object({
      group                        = string
      balancing_mode               = optional(string)
      capacity_scaler              = optional(number)
      description                  = optional(string)
      max_connections              = optional(number)
      max_connections_per_instance = optional(number)
      max_connections_per_endpoint = optional(number)
      max_rate                     = optional(number)
      max_rate_per_instance        = optional(number)
      max_rate_per_endpoint        = optional(number)
      max_utilization              = optional(number)
    })), [])
    log_config = optional(object({
      enable      = optional(bool)
      sample_rate = optional(number)
    }))
  }))

  validation {
    condition     = alltrue([for k, s in var.backend_services : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", s.name))])
    error_message = "backend_services.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, s in var.backend_services : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))])
    error_message = "backend_services.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, s in var.backend_services : alltrue([for b in s.backends : b.group != ""])])
    error_message = "backend_services.backends[].group must be a non-empty instance group, NEG or zonal group self link."
  }

  validation {
    condition     = alltrue([for k, s in var.backend_services : alltrue([for b in s.backends : b.balancing_mode == null || contains(["UTILIZATION", "RATE", "CONNECTION"], b.balancing_mode)])])
    error_message = "backend_services.backends[].balancing_mode must be one of UTILIZATION, RATE or CONNECTION (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, s in var.backend_services : alltrue([for b in s.backends : b.capacity_scaler == null || b.capacity_scaler >= 0])])
    error_message = "backend_services.backends[].capacity_scaler must be >= 0."
  }

  validation {
    condition     = alltrue([for k, s in var.backend_services : alltrue([for hc in s.health_checks : contains(keys(var.health_checks), hc)])])
    error_message = "backend_services.health_checks entries must be keys present in the health_checks variable; they are resolved to the referenced health check IDs."
  }
}

variable "regional_backend_services" {
  description = "Map of regional backend services keyed by an arbitrary identifier."
  type = map(object({
    name                            = string
    region                          = string
    description                     = optional(string)
    project_id                      = optional(string)
    affinity_cookie_ttl_sec         = optional(number)
    connection_draining_timeout_sec = optional(number)
    enable_cdn                      = optional(bool)
    health_checks                   = optional(list(string), [])
    load_balancing_scheme           = optional(string)
    locality_lb_policy              = optional(string)
    network                         = optional(string)
    port_name                       = optional(string)
    protocol                        = optional(string)
    security_policy                 = optional(string)
    session_affinity                = optional(string)
    timeout_sec                     = optional(number)
    backends = optional(list(object({
      group                        = string
      balancing_mode               = optional(string)
      capacity_scaler              = optional(number)
      description                  = optional(string)
      max_connections              = optional(number)
      max_connections_per_instance = optional(number)
      max_connections_per_endpoint = optional(number)
      max_rate                     = optional(number)
      max_rate_per_instance        = optional(number)
      max_rate_per_endpoint        = optional(number)
      max_utilization              = optional(number)
    })), [])
    log_config = optional(object({
      enable      = optional(bool)
      sample_rate = optional(number)
    }))
  }))

  validation {
    condition     = alltrue([for k, s in var.regional_backend_services : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", s.name))])
    error_message = "regional_backend_services.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, s in var.regional_backend_services : can(regex("^[a-z]+-[a-z]+[0-9]+$", s.region))])
    error_message = "regional_backend_services.region must be a GCP region (e.g. us-central1)."
  }

  validation {
    condition     = alltrue([for k, s in var.regional_backend_services : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))])
    error_message = "regional_backend_services.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, s in var.regional_backend_services : alltrue([for b in s.backends : b.group != ""])])
    error_message = "regional_backend_services.backends[].group must be a non-empty instance group, NEG or zonal group self link."
  }

  validation {
    condition     = alltrue([for k, s in var.regional_backend_services : alltrue([for b in s.backends : b.balancing_mode == null || contains(["UTILIZATION", "RATE", "CONNECTION"], b.balancing_mode)])])
    error_message = "regional_backend_services.backends[].balancing_mode must be one of UTILIZATION, RATE or CONNECTION (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, s in var.regional_backend_services : alltrue([for b in s.backends : b.capacity_scaler == null || b.capacity_scaler >= 0])])
    error_message = "regional_backend_services.backends[].capacity_scaler must be >= 0."
  }

  validation {
    condition     = alltrue([for k, s in var.regional_backend_services : alltrue([for hc in s.health_checks : contains(keys(var.regional_health_checks), hc)])])
    error_message = "regional_backend_services.health_checks entries must be keys present in the regional_health_checks variable; they are resolved to the referenced health check IDs."
  }
}

variable "backend_buckets" {
  description = "Map of backend buckets keyed by an arbitrary identifier."
  type = map(object({
    name                    = string
    bucket_name             = string
    description             = optional(string)
    project_id              = optional(string)
    enable_cdn              = optional(bool)
    compression_mode        = optional(string)
    edge_security_policy    = optional(string)
    custom_response_headers = optional(list(string))
    cdn_policy = optional(object({
      signed_url_cache_max_age_sec = optional(number)
      default_ttl                  = optional(number)
      max_ttl                      = optional(number)
      client_ttl                   = optional(number)
      negative_caching             = optional(bool)
      cache_mode                   = optional(string)
      serve_while_stale            = optional(number)
      request_coalescing           = optional(bool)
      cache_key_policy = optional(object({
        query_string_whitelist = optional(list(string))
        include_http_headers   = optional(list(string))
      }))
    }))
  }))

  validation {
    condition     = alltrue([for k, b in var.backend_buckets : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", b.name))])
    error_message = "backend_buckets.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, b in var.backend_buckets : b.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", b.project_id))])
    error_message = "backend_buckets.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, b in var.backend_buckets : b.cdn_policy == null || b.cdn_policy.cache_mode == null || contains(["CACHE_ALL_STATIC", "USE_ORIGIN_HEADERS", "FORCE_CACHE_ALL"], b.cdn_policy.cache_mode)])
    error_message = "backend_buckets.cdn_policy.cache_mode must be one of CACHE_ALL_STATIC, USE_ORIGIN_HEADERS or FORCE_CACHE_ALL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, b in var.backend_buckets : b.cdn_policy == null || (b.cdn_policy.signed_url_cache_max_age_sec == null || b.cdn_policy.signed_url_cache_max_age_sec >= 0) && (b.cdn_policy.default_ttl == null || b.cdn_policy.default_ttl >= 0) && (b.cdn_policy.max_ttl == null || b.cdn_policy.max_ttl >= 0) && (b.cdn_policy.client_ttl == null || b.cdn_policy.client_ttl >= 0) && (b.cdn_policy.serve_while_stale == null || b.cdn_policy.serve_while_stale >= 0)])
    error_message = "backend_buckets.cdn_policy TTL fields (signed_url_cache_max_age_sec, default_ttl, max_ttl, client_ttl, serve_while_stale) must be >= 0."
  }
}

variable "health_checks" {
  description = "Map of global health checks keyed by an arbitrary identifier."
  type = map(object({
    name                = string
    description         = optional(string)
    project_id          = optional(string)
    check_interval_sec  = optional(number)
    timeout_sec         = optional(number)
    healthy_threshold   = optional(number)
    unhealthy_threshold = optional(number)
    source_regions      = optional(list(string))
    http_health_check = optional(object({
      host               = optional(string)
      request_path       = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    https_health_check = optional(object({
      host               = optional(string)
      request_path       = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    http2_health_check = optional(object({
      host               = optional(string)
      request_path       = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    tcp_health_check = optional(object({
      request            = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    ssl_health_check = optional(object({
      request            = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    grpc_health_check = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      grpc_service_name  = optional(string)
    }))
    log_config = optional(object({
      enable = optional(bool)
    }))
  }))

  validation {
    condition     = alltrue([for k, c in var.health_checks : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", c.name))])
    error_message = "health_checks.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, c in var.health_checks : c.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", c.project_id))])
    error_message = "health_checks.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, c in var.health_checks : length([for b in [c.http_health_check, c.https_health_check, c.http2_health_check, c.tcp_health_check, c.ssl_health_check, c.grpc_health_check] : b if b != null]) == 1])
    error_message = "health_checks must set exactly one protocol block: http_health_check, https_health_check, http2_health_check, tcp_health_check, ssl_health_check or grpc_health_check."
  }

  validation {
    condition     = alltrue([for k, c in var.health_checks : (c.check_interval_sec == null || c.check_interval_sec >= 1) && (c.timeout_sec == null || c.timeout_sec >= 1) && (c.healthy_threshold == null || c.healthy_threshold >= 1) && (c.unhealthy_threshold == null || c.unhealthy_threshold >= 1)])
    error_message = "health_checks check_interval_sec, timeout_sec, healthy_threshold and unhealthy_threshold must be >= 1."
  }

  validation {
    condition     = alltrue([for k, c in var.health_checks : alltrue([for b in [c.http_health_check, c.https_health_check, c.http2_health_check, c.tcp_health_check, c.ssl_health_check, c.grpc_health_check] : (b == null) || (b.port_specification == null || contains(["USE_FIXED_PORT", "USE_NAMED_PORT", "USE_SERVING_PORT"], b.port_specification)) && (b.proxy_header == null || contains(["NONE", "PROXY_V1"], b.proxy_header))])])
    error_message = "health_checks protocol blocks: port_specification must be one of USE_FIXED_PORT, USE_NAMED_PORT or USE_SERVING_PORT, and proxy_header must be NONE or PROXY_V1 (case-sensitive)."
  }
}

variable "regional_health_checks" {
  description = "Map of regional health checks keyed by an arbitrary identifier."
  type = map(object({
    name                = string
    region              = string
    description         = optional(string)
    project_id          = optional(string)
    check_interval_sec  = optional(number)
    timeout_sec         = optional(number)
    healthy_threshold   = optional(number)
    unhealthy_threshold = optional(number)
    http_health_check = optional(object({
      host               = optional(string)
      request_path       = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    https_health_check = optional(object({
      host               = optional(string)
      request_path       = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    http2_health_check = optional(object({
      host               = optional(string)
      request_path       = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    tcp_health_check = optional(object({
      request            = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    ssl_health_check = optional(object({
      request            = optional(string)
      response           = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      proxy_header       = optional(string)
      port_specification = optional(string)
    }))
    grpc_health_check = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      grpc_service_name  = optional(string)
    }))
    log_config = optional(object({
      enable = optional(bool)
    }))
  }))

  validation {
    condition     = alltrue([for k, c in var.regional_health_checks : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", c.name))])
    error_message = "regional_health_checks.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, c in var.regional_health_checks : can(regex("^[a-z]+-[a-z]+[0-9]+$", c.region))])
    error_message = "regional_health_checks.region must be a GCP region (e.g. us-central1)."
  }

  validation {
    condition     = alltrue([for k, c in var.regional_health_checks : c.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", c.project_id))])
    error_message = "regional_health_checks.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, c in var.regional_health_checks : length([for b in [c.http_health_check, c.https_health_check, c.http2_health_check, c.tcp_health_check, c.ssl_health_check, c.grpc_health_check] : b if b != null]) == 1])
    error_message = "regional_health_checks must set exactly one protocol block: http_health_check, https_health_check, http2_health_check, tcp_health_check, ssl_health_check or grpc_health_check."
  }

  validation {
    condition     = alltrue([for k, c in var.regional_health_checks : (c.check_interval_sec == null || c.check_interval_sec >= 1) && (c.timeout_sec == null || c.timeout_sec >= 1) && (c.healthy_threshold == null || c.healthy_threshold >= 1) && (c.unhealthy_threshold == null || c.unhealthy_threshold >= 1)])
    error_message = "regional_health_checks check_interval_sec, timeout_sec, healthy_threshold and unhealthy_threshold must be >= 1."
  }

  validation {
    condition     = alltrue([for k, c in var.regional_health_checks : alltrue([for b in [c.http_health_check, c.https_health_check, c.http2_health_check, c.tcp_health_check, c.ssl_health_check, c.grpc_health_check] : (b == null) || (b.port_specification == null || contains(["USE_FIXED_PORT", "USE_NAMED_PORT", "USE_SERVING_PORT"], b.port_specification)) && (b.proxy_header == null || contains(["NONE", "PROXY_V1"], b.proxy_header))])])
    error_message = "regional_health_checks protocol blocks: port_specification must be one of USE_FIXED_PORT, USE_NAMED_PORT or USE_SERVING_PORT, and proxy_header must be NONE or PROXY_V1 (case-sensitive)."
  }
}

variable "url_maps" {
  description = "Map of global URL maps keyed by an arbitrary identifier."
  type = map(object({
    name            = string
    description     = optional(string)
    project_id      = optional(string)
    default_service = optional(string)
    default_url_redirect = optional(object({
      strip_query            = bool
      https_redirect         = optional(bool)
      redirect_response_code = optional(string)
    }))
    default_route_action = optional(object({
      cors_policy = optional(object({
        allow_credentials    = optional(bool)
        allow_headers        = optional(list(string))
        allow_methods        = optional(list(string))
        allow_origin_regexes = optional(list(string))
        allow_origins        = optional(list(string))
        disabled             = optional(bool)
        expose_headers       = optional(list(string))
        max_age              = optional(number)
      }))
    }))
    host_rules = optional(list(object({
      description  = optional(string)
      hosts        = list(string)
      path_matcher = string
    })), [])
    path_matchers = optional(list(object({
      name            = string
      description     = optional(string)
      default_service = optional(string)
      path_rules = optional(list(object({
        service = optional(string)
        paths   = list(string)
      })), [])
    })), [])
  }))

  validation {
    condition     = alltrue([for k, m in var.url_maps : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", m.name))])
    error_message = "url_maps.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, m in var.url_maps : m.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", m.project_id))])
    error_message = "url_maps.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, m in var.url_maps : (m.default_service != null) != (m.default_url_redirect != null)])
    error_message = "url_maps must set exactly one of default_service or default_url_redirect."
  }

  validation {
    condition     = alltrue([for k, m in var.url_maps : m.default_url_redirect == null || m.default_url_redirect.redirect_response_code == null || contains(["MOVED_PERMANENTLY_DEFAULT", "FOUND", "SEE_OTHER", "TEMPORARY_REDIRECT", "PERMANENT_REDIRECT"], m.default_url_redirect.redirect_response_code)])
    error_message = "url_maps.default_url_redirect.redirect_response_code must be one of MOVED_PERMANENTLY_DEFAULT, FOUND, SEE_OTHER, TEMPORARY_REDIRECT or PERMANENT_REDIRECT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, m in var.url_maps : alltrue([for h in m.host_rules : length(h.hosts) > 0])])
    error_message = "url_maps.host_rules[].hosts must contain at least one host pattern."
  }

  validation {
    condition     = alltrue([for k, m in var.url_maps : alltrue([for p in m.path_matchers : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])])
    error_message = "url_maps.path_matchers[].name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, m in var.url_maps : length(distinct([for p in m.path_matchers : p.name])) == length(m.path_matchers)])
    error_message = "url_maps.path_matchers[].name must be unique within the entry; host_rules reference path matchers by this name."
  }

  validation {
    condition     = alltrue([for k, m in var.url_maps : alltrue([for p in m.path_matchers : alltrue([for r in p.path_rules : length(r.paths) > 0])])])
    error_message = "url_maps.path_matchers[].path_rules[].paths must contain at least one path pattern."
  }
}

variable "regional_url_maps" {
  description = "Map of regional URL maps keyed by an arbitrary identifier."
  type = map(object({
    name            = string
    region          = string
    description     = optional(string)
    project_id      = optional(string)
    default_service = optional(string)
    default_url_redirect = optional(object({
      strip_query            = bool
      https_redirect         = optional(bool)
      redirect_response_code = optional(string)
    }))
    default_route_action = optional(object({
      cors_policy = optional(object({
        allow_credentials    = optional(bool)
        allow_headers        = optional(list(string))
        allow_methods        = optional(list(string))
        allow_origin_regexes = optional(list(string))
        allow_origins        = optional(list(string))
        disabled             = optional(bool)
        expose_headers       = optional(list(string))
        max_age              = optional(number)
      }))
    }))
    host_rules = optional(list(object({
      description  = optional(string)
      hosts        = list(string)
      path_matcher = string
    })), [])
    path_matchers = optional(list(object({
      name            = string
      description     = optional(string)
      default_service = optional(string)
      path_rules = optional(list(object({
        service = optional(string)
        paths   = list(string)
      })), [])
    })), [])
  }))

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", m.name))])
    error_message = "regional_url_maps.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : can(regex("^[a-z]+-[a-z]+[0-9]+$", m.region))])
    error_message = "regional_url_maps.region must be a GCP region (e.g. us-central1)."
  }

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : m.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", m.project_id))])
    error_message = "regional_url_maps.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : (m.default_service != null) != (m.default_url_redirect != null)])
    error_message = "regional_url_maps must set exactly one of default_service or default_url_redirect."
  }

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : m.default_url_redirect == null || m.default_url_redirect.redirect_response_code == null || contains(["MOVED_PERMANENTLY_DEFAULT", "FOUND", "SEE_OTHER", "TEMPORARY_REDIRECT", "PERMANENT_REDIRECT"], m.default_url_redirect.redirect_response_code)])
    error_message = "regional_url_maps.default_url_redirect.redirect_response_code must be one of MOVED_PERMANENTLY_DEFAULT, FOUND, SEE_OTHER, TEMPORARY_REDIRECT or PERMANENT_REDIRECT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : alltrue([for h in m.host_rules : length(h.hosts) > 0])])
    error_message = "regional_url_maps.host_rules[].hosts must contain at least one host pattern."
  }

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : alltrue([for p in m.path_matchers : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])])
    error_message = "regional_url_maps.path_matchers[].name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : length(distinct([for p in m.path_matchers : p.name])) == length(m.path_matchers)])
    error_message = "regional_url_maps.path_matchers[].name must be unique within the entry; host_rules reference path matchers by this name."
  }

  validation {
    condition     = alltrue([for k, m in var.regional_url_maps : alltrue([for p in m.path_matchers : alltrue([for r in p.path_rules : length(r.paths) > 0])])])
    error_message = "regional_url_maps.path_matchers[].path_rules[].paths must contain at least one path pattern."
  }
}

variable "http_proxies" {
  description = "Map of global target HTTP proxies keyed by an arbitrary identifier."
  type = map(object({
    name                        = string
    url_map                     = string
    description                 = optional(string)
    project_id                  = optional(string)
    proxy_bind                  = optional(bool)
    http_keep_alive_timeout_sec = optional(number)
  }))

  validation {
    condition     = alltrue([for k, p in var.http_proxies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "http_proxies.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.http_proxies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "http_proxies.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, p in var.http_proxies : contains(keys(var.url_maps), p.url_map)])
    error_message = "http_proxies.url_map must be a key present in the url_maps variable; it is resolved to the referenced URL map self link."
  }
}

variable "https_proxies" {
  description = "Map of global target HTTPS proxies keyed by an arbitrary identifier."
  type = map(object({
    name                             = string
    url_map                          = string
    description                      = optional(string)
    project_id                       = optional(string)
    quic_override                    = optional(string)
    tls_early_data                   = optional(string)
    ssl_certificates                 = optional(list(string))
    certificate_map                  = optional(string)
    certificate_manager_certificates = optional(list(string))
    ssl_policy                       = optional(string)
    http_keep_alive_timeout_sec      = optional(number)
    server_tls_policy                = optional(string)
  }))

  validation {
    condition     = alltrue([for k, p in var.https_proxies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "https_proxies.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.https_proxies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "https_proxies.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, p in var.https_proxies : contains(keys(var.url_maps), p.url_map)])
    error_message = "https_proxies.url_map must be a key present in the url_maps variable; it is resolved to the referenced URL map self link."
  }

  validation {
    condition     = alltrue([for k, p in var.https_proxies : p.ssl_certificates != null || p.certificate_map != null || p.certificate_manager_certificates != null])
    error_message = "https_proxies must set at least one certificate source: ssl_certificates, certificate_map or certificate_manager_certificates."
  }

  validation {
    condition     = alltrue([for k, p in var.https_proxies : p.quic_override == null || contains(["ALLOW", "NONE", "UPGRADE"], p.quic_override)])
    error_message = "https_proxies.quic_override must be one of ALLOW, NONE or UPGRADE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.https_proxies : p.tls_early_data == null || contains(["ACCEPTED", "REJECTED", "PERMISSIVE"], p.tls_early_data)])
    error_message = "https_proxies.tls_early_data must be one of ACCEPTED, REJECTED or PERMISSIVE (case-sensitive)."
  }
}

variable "regional_http_proxies" {
  description = "Map of regional target HTTP proxies keyed by an arbitrary identifier."
  type = map(object({
    name                        = string
    region                      = string
    url_map                     = string
    description                 = optional(string)
    project_id                  = optional(string)
    http_keep_alive_timeout_sec = optional(number)
  }))

  validation {
    condition     = alltrue([for k, p in var.regional_http_proxies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "regional_http_proxies.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_http_proxies : can(regex("^[a-z]+-[a-z]+[0-9]+$", p.region))])
    error_message = "regional_http_proxies.region must be a GCP region (e.g. us-central1)."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_http_proxies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "regional_http_proxies.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_http_proxies : contains(keys(var.regional_url_maps), p.url_map)])
    error_message = "regional_http_proxies.url_map must be a key present in the regional_url_maps variable; it is resolved to the referenced URL map self link."
  }
}

variable "regional_https_proxies" {
  description = "Map of regional target HTTPS proxies keyed by an arbitrary identifier."
  type = map(object({
    name                             = string
    region                           = string
    url_map                          = string
    description                      = optional(string)
    project_id                       = optional(string)
    ssl_certificates                 = optional(list(string))
    certificate_manager_certificates = optional(list(string))
    ssl_policy                       = optional(string)
    server_tls_policy                = optional(string)
    http_keep_alive_timeout_sec      = optional(number)
  }))

  validation {
    condition     = alltrue([for k, p in var.regional_https_proxies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "regional_https_proxies.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_https_proxies : can(regex("^[a-z]+-[a-z]+[0-9]+$", p.region))])
    error_message = "regional_https_proxies.region must be a GCP region (e.g. us-central1)."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_https_proxies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "regional_https_proxies.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_https_proxies : contains(keys(var.regional_url_maps), p.url_map)])
    error_message = "regional_https_proxies.url_map must be a key present in the regional_url_maps variable; it is resolved to the referenced URL map self link."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_https_proxies : p.ssl_certificates != null || p.certificate_manager_certificates != null])
    error_message = "regional_https_proxies must set at least one certificate source: ssl_certificates or certificate_manager_certificates."
  }
}

variable "global_forwarding_rules" {
  description = "Map of global forwarding rules keyed by an arbitrary identifier."
  type = map(object({
    name                  = string
    target                = string
    description           = optional(string)
    project_id            = optional(string)
    ip_address            = optional(string)
    ip_protocol           = optional(string)
    ip_version            = optional(string)
    labels                = optional(map(string))
    load_balancing_scheme = optional(string)
    network               = optional(string)
    port_range            = optional(string)
    subnetwork            = optional(string)
    source_ip_ranges      = optional(list(string))
    no_automate_dns_zone  = optional(bool)
    service_directory_registrations = optional(object({
      namespace                = optional(string)
      service_directory_region = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for k, r in var.global_forwarding_rules : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", r.name))])
    error_message = "global_forwarding_rules.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, r in var.global_forwarding_rules : r.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", r.project_id))])
    error_message = "global_forwarding_rules.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, r in var.global_forwarding_rules : r.load_balancing_scheme == null || contains(["EXTERNAL", "EXTERNAL_MANAGED", "INTERNAL_SELF_MANAGED"], r.load_balancing_scheme)])
    error_message = "global_forwarding_rules.load_balancing_scheme must be one of EXTERNAL, EXTERNAL_MANAGED or INTERNAL_SELF_MANAGED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, r in var.global_forwarding_rules : r.ip_protocol == null || contains(["TCP", "UDP", "SCTP", "ESP", "AH", "ICMP", "L3_DEFAULT"], r.ip_protocol)])
    error_message = "global_forwarding_rules.ip_protocol must be one of TCP, UDP, SCTP, ESP, AH, ICMP or L3_DEFAULT (case-sensitive)."
  }
}

variable "forwarding_rules" {
  description = "Map of regional forwarding rules keyed by an arbitrary identifier."
  type = map(object({
    name                    = string
    region                  = string
    target                  = string
    description             = optional(string)
    project_id              = optional(string)
    ip_address              = optional(string)
    ip_protocol             = optional(string)
    backend_service         = optional(string)
    load_balancing_scheme   = optional(string)
    network                 = optional(string)
    port_range              = optional(string)
    ports                   = optional(list(string))
    subnetwork              = optional(string)
    allow_global_access     = optional(bool)
    all_ports               = optional(bool)
    network_tier            = optional(string)
    service_label           = optional(string)
    source_ip_ranges        = optional(list(string))
    allow_psc_global_access = optional(bool)
    no_automate_dns_zone    = optional(bool)
    ip_version              = optional(string)
    recreate_closed_psc     = optional(bool)
    is_mirroring_collector  = optional(bool)
    service_directory_registrations = optional(object({
      namespace = optional(string)
      service   = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", r.name))])
    error_message = "forwarding_rules.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : can(regex("^[a-z]+-[a-z]+[0-9]+$", r.region))])
    error_message = "forwarding_rules.region must be a GCP region (e.g. us-central1)."
  }

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : r.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", r.project_id))])
    error_message = "forwarding_rules.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : r.load_balancing_scheme == null || contains(["EXTERNAL", "EXTERNAL_MANAGED", "INTERNAL", "INTERNAL_MANAGED"], r.load_balancing_scheme)])
    error_message = "forwarding_rules.load_balancing_scheme must be one of EXTERNAL, EXTERNAL_MANAGED, INTERNAL or INTERNAL_MANAGED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : r.ip_protocol == null || contains(["TCP", "UDP", "SCTP", "ESP", "AH", "ICMP", "L3_DEFAULT"], r.ip_protocol)])
    error_message = "forwarding_rules.ip_protocol must be one of TCP, UDP, SCTP, ESP, AH, ICMP or L3_DEFAULT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : !(r.all_ports == true && r.ports != null)])
    error_message = "forwarding_rules: ports must not be set when all_ports is true."
  }

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : r.ports == null || alltrue([for p in r.ports : can(regex("^[0-9]{1,5}$", p)) && tonumber(p) >= 1 && tonumber(p) <= 65535])])
    error_message = "forwarding_rules.ports entries must be numeric strings between 1 and 65535."
  }

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : r.network_tier == null || contains(["PREMIUM", "STANDARD"], r.network_tier)])
    error_message = "forwarding_rules.network_tier must be PREMIUM or STANDARD (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, r in var.forwarding_rules : r.service_label == null || can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", r.service_label))])
    error_message = "forwarding_rules.service_label must be a single lowercase RFC1035 label."
  }
}
