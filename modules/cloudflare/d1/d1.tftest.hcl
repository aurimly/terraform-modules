mock_provider "cloudflare" {
  mock_resource "cloudflare_d1_database" {
    defaults = {
      id   = "8c2625da-2ebb-4f8e-8f87-3f4b6c1f0a11"
      uuid = "8c2625da-2ebb-4f8e-8f87-3f4b6c1f0a11"
    }
  }
}

run "wiring" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    databases = {
      "app-primary" = {
        name                  = "app-db"
        jurisdiction          = "eu"
        read_replication_mode = "auto"
      }
      "analytics" = {
        name                  = "analytics-db"
        primary_location_hint = "wnam"
      }
    }
  }

  assert {
    condition     = output.database_ids["app-primary"] == "8c2625da-2ebb-4f8e-8f87-3f4b6c1f0a11"
    error_message = "database ID keyed by map key"
  }

  assert {
    condition     = output.database_names["analytics"] == "analytics-db"
    error_message = "database name keyed by map key"
  }
}

run "missing_account_fails" {
  command = plan

  variables {
    databases = {
      "orphan" = {
        name = "orphan-db"
      }
    }
  }

  expect_failures = [resource.cloudflare_d1_database.database["orphan"]]
}
