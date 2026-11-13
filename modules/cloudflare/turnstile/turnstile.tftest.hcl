mock_provider "cloudflare" {
  mock_resource "cloudflare_turnstile_widget" {
    defaults = {
      id      = "0x4AAAaAaAAAAaAAaAAaAAaAAaAAaAAaAa"
      sitekey = "0x4AAAaAaAAAAaAAaAAaAAaAAaAAaAAaAa"
      secret  = "0x4AAAaAaAAAAaAAaAAaAAaAAaAAaAAaAaX"
    }
  }
}

run "wiring" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    widgets = {
      "login-form" = {
        name    = "login form"
        domains = ["blog.example.com", "www.example.com"]
        mode    = "managed"
      }
      "app-check" = {
        name    = "mobile app check"
        domains = []
        mode    = "non-interactive"
      }
    }
  }

  assert {
    condition     = output.widget_sitekeys["login-form"] == "0x4AAAaAaAAAAaAAaAAaAAaAAaAAaAAaAa"
    error_message = "sitekey keyed by map key"
  }

  assert {
    condition     = length(output.widget_secret_keys) == 2
    error_message = "secrets exported per widget"
  }
}

run "bad_mode_fails" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c353"

    widgets = {
      "broken" = {
        name    = "broken widget"
        domains = ["example.com"]
        mode    = "sometimes"
      }
    }
  }

  expect_failures = [var.widgets]
}

run "missing_account_fails" {
  command = plan

  variables {
    widgets = {
      "orphan" = {
        name    = "orphan widget"
        domains = ["example.com"]
        mode    = "managed"
      }
    }
  }

  expect_failures = [resource.cloudflare_turnstile_widget.widget["orphan"]]
}
