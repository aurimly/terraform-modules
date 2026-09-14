mock_provider "google" {}

run "workflows" {
  command = plan

  variables {
    workflows = {
      "status-check" = {
        name            = "example-status-check"
        region          = "europe-west4"
        service_account = "projects/example-prj/serviceAccounts/workflows-rt@example-prj.iam.gserviceaccount.com"
        call_log_level  = "LOG_ERRORS_ONLY"
        user_env_vars   = { base_url = "https://api.example.com" }
        source_contents = <<-EOF
          - check:
              call: http.get
              args:
                url: $${sys.get_env("base_url") + "/healthz"}
              result: health
          - return:
              return: $${health.status}
        EOF
      }
      "nightly-report" = {
        name                    = "example-nightly-report"
        region                  = "europe-west4"
        execution_history_level = "EXECUTION_HISTORY_BASIC"
        source_contents         = <<-EOF
          - done:
              return: true
        EOF
      }
    }
  }
}

run "rejects_bad_env_var_key" {
  command = plan

  variables {
    workflows = {
      "w" = {
        name            = "example-workflow"
        region          = "europe-west4"
        user_env_vars   = { GOOGLE_URL = "https://example.com" }
        source_contents = "- done:\n    return: true"
      }
    }
  }

  expect_failures = [var.workflows]
}

run "rejects_bad_call_log_level" {
  command = plan

  variables {
    workflows = {
      "w" = {
        name            = "example-workflow"
        region          = "europe-west4"
        call_log_level  = "LOG_EVERYTHING"
        source_contents = "- done:\n    return: true"
      }
    }
  }

  expect_failures = [var.workflows]
}

run "rejects_bad_crypto_key" {
  command = plan

  variables {
    workflows = {
      "w" = {
        name            = "example-workflow"
        region          = "europe-west4"
        crypto_key_name = "example-key"
        source_contents = "- done:\n    return: true"
      }
    }
  }

  expect_failures = [var.workflows]
}
