mock_provider "google" {}

run "proxies" {
  command = plan

  variables {
    tcp_proxies = {
      "app" = {
        name            = "example-app-tcp-proxy"
        backend_service = "projects/example-prj/global/backendServices/example-app-tcp-bes"
        proxy_header    = "PROXY_V1"
        deletion_policy = "ABANDON"
      }
    }
    regional_tcp_proxies = {
      "internal" = {
        name            = "example-int-tcp-proxy"
        backend_service = "projects/example-prj/regions/us-central1/backendServices/example-int-tcp-bes"
        region          = "us-central1"
      }
    }
    ssl_proxies = {
      "tls" = {
        name             = "example-tls-ssl-proxy"
        backend_service  = "projects/example-prj/global/backendServices/example-tls-bes"
        ssl_certificates = ["projects/example-prj/global/sslCertificates/example-cert"]
        ssl_policy       = "projects/example-prj/global/sslPolicies/example-policy"
      }
    }
    grpc_proxies = {
      "grpc" = {
        name                   = "example-grpc-proxy"
        url_map                = "projects/example-prj/global/urlMaps/example-grpc-urlmap"
        validate_for_proxyless = true
      }
    }
  }
}

run "rejects_ssl_proxy_without_certificates" {
  command = plan

  variables {
    tcp_proxies          = {}
    regional_tcp_proxies = {}
    grpc_proxies         = {}
    ssl_proxies = {
      "bad" = {
        name            = "example-tls-ssl-proxy"
        backend_service = "projects/example-prj/global/backendServices/example-tls-bes"
      }
    }
  }

  expect_failures = [var.ssl_proxies]
}

run "rejects_tcp_proxy_without_backend_service" {
  command = plan

  variables {
    regional_tcp_proxies = {}
    ssl_proxies          = {}
    grpc_proxies         = {}
    tcp_proxies = {
      "bad" = {
        name            = "example-app-tcp-proxy"
        backend_service = ""
      }
    }
  }

  expect_failures = [var.tcp_proxies]
}

run "rejects_bad_proxy_header" {
  command = plan

  variables {
    regional_tcp_proxies = {}
    ssl_proxies          = {}
    grpc_proxies         = {}
    tcp_proxies = {
      "bad" = {
        name            = "example-app-tcp-proxy"
        backend_service = "projects/example-prj/global/backendServices/example-app-tcp-bes"
        proxy_header    = "PROXY_V2"
      }
    }
  }

  expect_failures = [var.tcp_proxies]
}

run "rejects_grpc_proxy_without_url_map" {
  command = plan

  variables {
    tcp_proxies          = {}
    regional_tcp_proxies = {}
    ssl_proxies          = {}
    grpc_proxies = {
      "bad" = {
        name    = "example-grpc-proxy"
        url_map = ""
      }
    }
  }

  expect_failures = [var.grpc_proxies]
}
