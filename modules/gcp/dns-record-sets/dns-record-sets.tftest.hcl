mock_provider "google" {}

run "record_sets" {
  command = plan

  variables {
    managed_zone_name = "example-org-public"

    record_sets = {
      "apex" = {
        name    = "example.com."
        type    = "A"
        rrdatas = ["203.0.113.10"]
      }
      "mx" = {
        name    = "example.com."
        type    = "MX"
        rrdatas = ["10 mail.example.com."]
      }
      "internal-app" = {
        name = "app.example.internal."
        type = "A"
        routing_policy = {
          primary_backup = {
            primary = {
              internal_load_balancers = [
                {
                  ip_address  = "10.0.0.20"
                  port        = "80"
                  ip_protocol = "tcp"
                  network_url = "https://www.googleapis.com/compute/v1/projects/example-prj/global/networks/vpc-example"
                  project     = "example-prj"
                  region      = "europe-west4"
                },
              ]
            }
            backup_geo = [{ location = "europe-west1", rrdatas = ["10.0.0.30"] }]
          }
        }
      }
    }
  }
}

run "rejects_rrdatas_and_routing_policy" {
  command = plan

  variables {
    managed_zone_name = "example-org-public"

    record_sets = {
      "apex" = {
        name    = "example.com."
        type    = "A"
        rrdatas = ["203.0.113.10"]
        routing_policy = {
          wrr = [
            { weight = 1, rrdatas = ["203.0.113.10"] },
          ]
        }
      }
    }
  }

  expect_failures = [var.record_sets]
}

run "rejects_name_without_trailing_dot" {
  command = plan

  variables {
    managed_zone_name = "example-org-public"

    record_sets = {
      "www" = {
        name    = "www.example.com"
        type    = "CNAME"
        rrdatas = ["example.com."]
      }
    }
  }

  expect_failures = [var.record_sets]
}

run "rejects_two_routing_policies" {
  command = plan

  variables {
    managed_zone_name = "example-org-public"

    record_sets = {
      "internal-app" = {
        name = "app.example.internal."
        type = "A"
        routing_policy = {
          wrr = [
            { weight = 1, rrdatas = ["10.0.0.20"] },
          ]
          geo = [
            { location = "europe-west4", rrdatas = ["10.0.0.30"] },
          ]
        }
      }
    }
  }

  expect_failures = [var.record_sets]
}

run "rejects_empty_routing_entry" {
  command = plan

  variables {
    managed_zone_name = "example-org-public"

    record_sets = {
      "internal-app" = {
        name = "app.example.internal."
        type = "A"
        routing_policy = {
          geo = [
            { location = "europe-west4" },
          ]
        }
      }
    }
  }

  expect_failures = [var.record_sets]
}
