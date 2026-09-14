mock_provider "google" {}

run "channels" {
  command = plan

  variables {
    channels = {
      "emails" = {
        type         = "email"
        display_name = "example-team-mailbox"
        labels       = { email_address = "oncall@example.com" }
        user_labels  = { owner = "platform" }
      }
      "slack-oncall" = {
        type         = "slack"
        display_name = "example-slack-oncall"
        labels       = { channel_name = "#alerts" }
        sensitive_labels = {
          auth_token = "xoxb-example"
        }
      }
      "pagerduty-live" = {
        type         = "pagerduty"
        display_name = "example-pagerduty"
        force_delete = true
        sensitive_labels = {
          service_key = "pd-example"
        }
      }
    }
  }
}

run "rejects_missing_display_name" {
  command = plan

  variables {
    channels = {
      "c" = {
        type   = "email"
        labels = { email_address = "oncall@example.com" }
      }
    }
  }

  expect_failures = [var.channels]
}

run "rejects_same_label_both_places" {
  command = plan

  variables {
    channels = {
      "c" = {
        type         = "slack"
        display_name = "example-slack"
        labels       = { channel_name = "#alerts", auth_token = "dup" }
        sensitive_labels = {
          auth_token = "dup-elsewhere"
        }
      }
    }
  }

  expect_failures = [var.channels]
}
