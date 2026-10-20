mock_provider "cloudflare" {
  mock_resource "cloudflare_workers_kv_namespace" {
    defaults = {
      id = "5ebe363c0f2b4e0d8f8c3a3b0a1b2c3d"
    }
  }
}

run "namespaces" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    namespaces = {
      "sessions" = {
        title = "example-sessions"
      }
      "eu-data" = {
        title        = "example-sessions-eu"
        jurisdiction = "eu"
      }
      "instant" = {
        title = "example-instant"
        mode  = "instant"
      }
    }
  }

  assert {
    condition     = output.namespace_ids["sessions"] == "5ebe363c0f2b4e0d8f8c3a3b0a1b2c3d"
    error_message = "namespace ID keyed by map key"
  }

  assert {
    condition     = output.namespace_titles["instant"] == "example-instant"
    error_message = "namespace title keyed by map key"
  }
}

run "rejects_bad_jurisdiction" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    namespaces = {
      "bad" = {
        title        = "example-bad"
        jurisdiction = "apac"
      }
    }
  }

  expect_failures = [var.namespaces]
}

run "rejects_bad_mode" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    namespaces = {
      "bad" = {
        title = "example-bad"
        mode  = "classic"
      }
    }
  }

  expect_failures = [var.namespaces]
}
