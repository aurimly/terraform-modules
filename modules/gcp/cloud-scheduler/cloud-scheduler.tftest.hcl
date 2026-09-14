mock_provider "google" {}

run "jobs" {
  command = plan

  variables {
    jobs = {
      "nightly-sync" = {
        name             = "example-nightly-sync"
        schedule         = "0 3 * * *"
        time_zone        = "Europe/Berlin"
        attempt_deadline = "320s"
        http_target = {
          uri         = "https://api.example.com/jobs/sync"
          http_method = "POST"
          body        = base64encode("{\"kind\":\"sync\"}")
          headers     = { "Content-Type" = "application/json" }
          oidc_token = {
            service_account_email = "jobs-rt@example-prj.iam.gserviceaccount.com"
            audience              = "https://api.example.com"
          }
        }
        retry_config = {
          retry_count          = 3
          min_backoff_duration = "1s"
          max_retry_duration   = "300s"
        }
      }
      "weekly-snapshot" = {
        name        = "example-weekly-snapshot"
        description = "publishes a snapshot request"
        schedule    = "0 5 * * 1"
        pubsub_target = {
          topic_name = "projects/example-prj/topics/example-snapshot-requests"
          data       = base64encode("{\"scope\":\"full\"}")
        }
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    jobs = {
      "j" = {
        name        = "Bad Name"
        schedule    = "0 3 * * *"
        http_target = { uri = "https://example.com" }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_two_targets" {
  command = plan

  variables {
    jobs = {
      "j" = {
        name     = "example-job"
        schedule = "0 3 * * *"
        pubsub_target = {
          topic_name = "projects/example-prj/topics/example-snapshot-requests"
        }
        http_target = {
          uri = "https://example.com"
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_deadline_on_pubsub" {
  command = plan

  variables {
    jobs = {
      "j" = {
        name             = "example-job"
        schedule         = "0 3 * * *"
        attempt_deadline = "60s"
        pubsub_target = {
          topic_name = "projects/example-prj/topics/example-snapshot-requests"
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_oauth_and_oidc" {
  command = plan

  variables {
    jobs = {
      "j" = {
        name     = "example-job"
        schedule = "0 3 * * *"
        http_target = {
          uri = "https://example.com"
          oauth_token = {
            service_account_email = "jobs-rt@example-prj.iam.gserviceaccount.com"
          }
          oidc_token = {
            service_account_email = "jobs-rt@example-prj.iam.gserviceaccount.com"
          }
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_bad_retry_count" {
  command = plan

  variables {
    jobs = {
      "j" = {
        name     = "example-job"
        schedule = "0 3 * * *"
        http_target = {
          uri = "https://example.com"
        }
        retry_config = {
          retry_count = 7
        }
      }
    }
  }

  expect_failures = [var.jobs]
}
