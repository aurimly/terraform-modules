mock_provider "google" {}

run "queues" {
  command = plan

  variables {
    queues = {
      "email-notifications" = {
        name     = "example-email-notifications"
        location = "europe-west4"
        rate_limits = {
          max_dispatches_per_second = 5
          max_concurrent_dispatches = 10
        }
        retry_config = {
          max_attempts  = 5
          min_backoff   = "2s"
          max_backoff   = "300s"
          max_doublings = 3
        }
        http_target = {
          http_method = "POST"
          uri_override = {
            host          = "worker.example.com"
            path_override = { path = "/tasks/email" }
          }
          oidc_token = {
            service_account_email = "tasks-rt@example-prj.iam.gserviceaccount.com"
          }
        }
      }
      "billing-sync" = {
        name          = "example-billing-sync"
        location      = "europe-west4"
        desired_state = "PAUSED"
        stackdriver_logging_config = {
          sampling_ratio = 0.5
        }
        role_bindings = {
          "enqueue" = {
            role    = "roles/cloudtasks.enqueuer"
            members = ["serviceAccount:enqueuer@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    queues = {
      "q" = {
        name     = "bad name"
        location = "europe-west4"
      }
    }
  }

  expect_failures = [var.queues]
}

run "rejects_bad_desired_state" {
  command = plan

  variables {
    queues = {
      "q" = {
        name          = "example-queue"
        location      = "europe-west4"
        desired_state = "STOPPED"
      }
    }
  }

  expect_failures = [var.queues]
}

run "rejects_bad_sampling_ratio" {
  command = plan

  variables {
    queues = {
      "q" = {
        name     = "example-queue"
        location = "europe-west4"
        stackdriver_logging_config = {
          sampling_ratio = 1.5
        }
      }
    }
  }

  expect_failures = [var.queues]
}

run "rejects_oauth_and_oidc" {
  command = plan

  variables {
    queues = {
      "q" = {
        name     = "example-queue"
        location = "europe-west4"
        http_target = {
          http_method  = "POST"
          uri_override = { host = "worker.example.com" }
          oauth_token = {
            service_account_email = "tasks-rt@example-prj.iam.gserviceaccount.com"
          }
          oidc_token = {
            service_account_email = "tasks-rt@example-prj.iam.gserviceaccount.com"
          }
        }
      }
    }
  }

  expect_failures = [var.queues]
}

run "rejects_no_uri_override_host" {
  command = plan

  variables {
    queues = {
      "q" = {
        name     = "example-queue"
        location = "europe-west4"
        http_target = {
          http_method  = "POST"
          uri_override = {}
        }
      }
    }
  }

  expect_failures = [var.queues]
}
