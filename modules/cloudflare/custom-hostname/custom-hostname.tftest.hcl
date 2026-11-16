mock_provider "cloudflare" {
  mock_resource "cloudflare_custom_hostname" {
    defaults = {
      id     = "0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d"
      status = "pending"
      ownership_verification = {
        type  = "txt"
        name  = "_acme-challenge.app.customer.example"
        value = "ownership-verification-token"
      }
    }
  }
  mock_resource "cloudflare_custom_hostname_fallback_origin" {
    defaults = {
      id     = "023e105f4ecef8ad9ca31a8372d0c353"
      status = "pending_deployment"
    }
  }
}

run "wiring" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    fallback_origin = {
      origin = "saas.example.com"
    }

    hostnames = {
      "acme" = {
        hostname             = "app.customer.example"
        custom_origin_server = "origin.example.com"
        ssl = {
          method = "txt"
        }
      }
    }
  }

  assert {
    condition     = output.custom_hostname_ids["acme"] == "0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d"
    error_message = "custom hostname ID keyed by map key"
  }

  assert {
    condition     = output.ownership_verifications["acme"].name == "_acme-challenge.app.customer.example"
    error_message = "ownership verification passed through per entry"
  }

  assert {
    condition     = output.fallback_origin_status == "pending_deployment"
    error_message = "fallback origin status exported when configured"
  }
}

run "bad_ssl_type_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    hostnames = {
      "broken" = {
        hostname = "app.customer.example"
        ssl = {
          type = "non_dv"
        }
      }
    }
  }

  expect_failures = [var.hostnames]
}

run "duplicate_hostname_fails" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    hostnames = {
      "first" = {
        hostname = "app.customer.example"
      }
      "second" = {
        hostname = "APP.customer.example"
      }
    }
  }

  expect_failures = [var.hostnames]
}

run "same_hostname_different_zones_ok" {
  command = plan

  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

    hostnames = {
      "one" = {
        hostname = "app.customer.example"
      }
      "two" = {
        hostname = "app.customer.example"
        zone_id  = "1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d"
      }
    }
  }

  assert {
    condition     = length(output.custom_hostname_ids) == 2
    error_message = "identical hostnames in different zones do not conflict"
  }
}

run "missing_zone_fails" {
  command = plan

  variables {
    hostnames = {
      "orphan" = {
        hostname = "app.customer.example"
      }
    }
  }

  expect_failures = [resource.cloudflare_custom_hostname.custom_hostname["orphan"]]
}
