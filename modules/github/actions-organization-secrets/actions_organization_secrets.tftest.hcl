mock_provider "github" {
  mock_resource "github_actions_organization_secret" {
    defaults = {
      id         = "DEPLOY_TOKEN"
      created_at = "2026-01-01T00:00:00Z"
      updated_at = "2026-01-02T00:00:00Z"
    }
  }
  mock_resource "github_actions_organization_secret_repositories" {
    defaults = {
      id = "DEPLOY_TOKEN"
    }
  }
}

run "full_org_secrets" {
  command = plan

  variables {
    secrets = {
      "DEPLOY_TOKEN" = {
        value      = "not-a-real-token"
        visibility = "selected"
        selected_repository_ids = [
          458636207,
        ]
      }
      "PUBLIC_FLAG" = {
        value      = "1"
        visibility = "all"
      }
    }
  }

  assert {
    condition     = length(github_actions_organization_secret.secret) == 2
    error_message = "both secrets created"
  }
  assert {
    condition     = length(github_actions_organization_secret_repositories.secret_repositories) == 1
    error_message = "one allow-list resource for the selected-visibility secret"
  }
  assert {
    condition     = output.secret_names["DEPLOY_TOKEN"] == "DEPLOY_TOKEN"
    error_message = "secret names keyed by map key"
  }
}
