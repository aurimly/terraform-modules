mock_provider "google" {}

run "external_and_internal_load_balancers" {
  command = plan

  variables {
    health_checks = {
      "web" = {
        name               = "example-web-hc"
        check_interval_sec = 10
        timeout_sec        = 5
        http_health_check = {
          request_path = "/healthz"
        }
      },
    }
    backend_services = {
      "app" = {
        name          = "example-app-bes"
        port_name     = "http"
        protocol      = "HTTP"
        enable_cdn    = true
        health_checks = ["web"]
        backends = [
          {
            group           = "projects/example-project-1234/zones/us-central1-a/instanceGroups/example-ig"
            balancing_mode  = "UTILIZATION"
            capacity_scaler = 1
          },
        ]
        log_config = {
          enable = true
        }
      },
    }
    backend_buckets = {
      "assets" = {
        name        = "example-assets-beb"
        bucket_name = "example-static-bucket"
        enable_cdn  = true
        cdn_policy = {
          cache_mode = "CACHE_ALL_STATIC"
        }
      },
    }
    url_maps = {
      "web" = {
        name            = "example-web-urlmap"
        default_service = "projects/example-project-1234/global/backendServices/example-app-bes"
        host_rules = [
          {
            hosts        = ["example.example.com"]
            path_matcher = "example-paths"
          },
        ]
        path_matchers = [
          {
            name            = "example-paths"
            default_service = "projects/example-project-1234/global/backendBuckets/example-assets-beb"
            path_rules = [
              {
                service = "projects/example-project-1234/global/backendBuckets/example-assets-beb"
                paths   = ["/static/*"]
              },
            ]
          },
        ]
      },
    }
    http_proxies = {
      "web" = {
        name    = "example-web-http-proxy"
        url_map = "web"
      },
    }
    https_proxies = {
      "web" = {
        name             = "example-web-https-proxy"
        url_map          = "web"
        ssl_certificates = ["projects/example-project-1234/global/sslCertificates/example-cert"]
      },
    }
    global_forwarding_rules = {
      "web" = {
        name       = "example-web-https-fr"
        target     = "projects/example-project-1234/global/targetHttpsProxies/example-web-https-proxy"
        port_range = "443-443"
        ip_address = "projects/example-project-1234/global/addresses/example-lb-ip"
      },
    }
    regional_health_checks = {
      "app" = {
        name   = "example-app-regional-hc"
        region = "us-central1"
        http_health_check = {
          request_path = "/healthz"
        }
      },
    }
    regional_backend_services = {
      "app" = {
        name          = "example-app-regional-bes"
        region        = "us-central1"
        protocol      = "HTTP"
        health_checks = ["app"]
        backends = [
          {
            group           = "projects/example-project-1234/regions/us-central1/networkEndpointGroups/example-neg"
            balancing_mode  = "CONNECTION"
            capacity_scaler = 1
          },
        ]
      },
    }
    regional_url_maps = {
      "web" = {
        name            = "example-web-regional-urlmap"
        region          = "us-central1"
        default_service = "projects/example-project-1234/regions/us-central1/backendServices/example-app-regional-bes"
      },
    }
    regional_http_proxies = {
      "web" = {
        name    = "example-web-regional-http-proxy"
        region  = "us-central1"
        url_map = "web"
      },
    }
    regional_https_proxies = {
      "web" = {
        name             = "example-web-regional-https-proxy"
        region           = "us-central1"
        url_map          = "web"
        ssl_certificates = ["projects/example-project-1234/regions/us-central1/sslCertificates/example-regional-cert"]
      },
    }
    forwarding_rules = {
      "web" = {
        name                  = "example-web-regional-fr"
        region                = "us-central1"
        target                = "projects/example-project-1234/regions/us-central1/targetHttpsProxies/example-web-regional-https-proxy"
        load_balancing_scheme = "INTERNAL_MANAGED"
        ports                 = ["443"]
        subnetwork            = "projects/example-project-1234/regions/us-central1/subnetworks/example-app"
        ip_address            = "projects/example-project-1234/regions/us-central1/addresses/example-ilb-ip"
      },
    }
  }
}
