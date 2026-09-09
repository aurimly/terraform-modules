mock_provider "google" {}

run "certificates" {
  command = plan

  variables {
    certificates = {
      "app" = {
        name        = "example-app-cert"
        description = "managed certificate for example.example.com"
        managed = {
          domains = ["example.example.com"]
        }
      },
      "wildcard" = {
        name = "example-wildcard-cert"
        managed = {
          domains = ["*.example.example.org"]
        }
      },
    }
  }
}

run "rejects_empty_domains" {
  command = plan

  variables {
    certificates = {
      "app" = {
        name = "example-app-cert"
        managed = {
          domains = []
        }
      },
    }
  }

  expect_failures = [var.certificates]
}

run "rejects_invalid_domain" {
  command = plan

  variables {
    certificates = {
      "app" = {
        name = "example-app-cert"
        managed = {
          domains = ["bad_domain.example.com"]
        }
      },
    }
  }

  expect_failures = [var.certificates]
}
