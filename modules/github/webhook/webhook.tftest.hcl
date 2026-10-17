mock_provider "github" {
  mock_resource "github_repository_webhook" {
    defaults = {
      id  = "example-repo/14711452"
      url = "https://ci.example.com/hooks/inject"
    }
  }
  mock_resource "github_organization_webhook" {
    defaults = {
      id  = "123456789"
      url = "https://audit.example.com/org-hooks/feed"
    }
  }
}

run "full_webhooks" {
  command = plan

  variables {
    repository_webhooks = {
      "ci-injector" = {
        repository = "example-repo"
        events     = ["workflow_run"]
        configuration = {
          url          = "https://ci.example.com/hooks/inject"
          content_type = "json"
        }
      }
    }

    organization_webhooks = {
      "audit-feed" = {
        events = ["issues"]
        configuration = {
          url          = "https://audit.example.com/org-hooks/feed"
          content_type = "json"
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_webhook.repository_webhook) == 1
    error_message = "one repository webhook expected"
  }
  assert {
    condition     = length(github_organization_webhook.organization_webhook) == 1
    error_message = "one organization webhook expected"
  }
  assert {
    condition     = github_repository_webhook.repository_webhook["ci-injector"].repository == "example-repo"
    error_message = "webhook pinned to the named repository"
  }
  assert {
    condition     = output.repository_webhook_repositories["ci-injector"] == "example-repo"
    error_message = "repository output keyed by webhook key"
  }
  assert {
    condition     = output.repository_webhook_ids["ci-injector"] != null
    error_message = "hook id surfaced for import"
  }
  assert {
    condition     = output.organization_webhook_ids["audit-feed"] != null
    error_message = "organization hook id surfaced for import"
  }
}
