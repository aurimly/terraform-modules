mock_provider "cloudflare" {
  mock_resource "cloudflare_notification_policy_webhooks" {
    defaults = {
      id   = "f174e90afafe4643bbbc4a0ed4fc8415"
      type = "generic"
    }
  }
  mock_resource "cloudflare_notification_policy" {
    defaults = {
      id = "5ebe363c0f2b4e0d8f8c3a3b0a1b2c3d"
    }
  }
}

run "webhook_wiring" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    webhooks = {
      "slack" = {
        name   = "example-slack"
        url    = "https://hooks.slack.com/services/example/example/example"
        secret = "example-secret"
      }
    }

    policies = {
      "tunnel-health" = {
        name       = "example tunnel health"
        alert_type = "tunnel_health_event"
        filters = {
          tunnel_id  = ["example-tunnel-id"]
          new_status = ["UNHEALTHY"]
        }
        mechanisms = {
          webhooks = ["slack"]
        }
      }
    }
  }

  assert {
    condition     = output.webhook_ids["slack"] == "f174e90afafe4643bbbc4a0ed4fc8415"
    error_message = "webhook ID keyed by map key"
  }

  assert {
    condition     = output.policy_ids["tunnel-health"] == "5ebe363c0f2b4e0d8f8c3a3b0a1b2c3d"
    error_message = "policy ID keyed by map key"
  }
}

run "rejects_unknown_webhook_key" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    policies = {
      "orphan" = {
        name       = "example orphan policy"
        alert_type = "universal_ssl_event_type"
        mechanisms = {
          webhooks = ["missing"]
        }
      }
    }
  }

  expect_failures = [resource.cloudflare_notification_policy.policies["orphan"]]
}

run "rejects_bad_alert_type" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    policies = {
      "bad" = {
        name       = "example bad alert type"
        alert_type = "not_a_real_alert_type"
        mechanisms = {
          email = ["ops@example.com"]
        }
      }
    }
  }

  expect_failures = [var.policies]
}
