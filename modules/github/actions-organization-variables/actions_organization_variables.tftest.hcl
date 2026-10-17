mock_provider "github" {
  mock_resource "github_actions_organization_variable" {
    defaults = {
      id         = "DEPLOY_ENV"
      created_at = "2026-01-01T00:00:00Z"
      updated_at = "2026-01-02T00:00:00Z"
    }
  }
}

run "full_org_variables" {
  command = plan

  variables {
    variables = {
      "DEPLOY_ENV" = {
        value      = "prd"
        visibility = "all"
      }
      "RUNNER_LABEL" = {
        value      = "self-hosted-eu"
        visibility = "selected"
        selected_repository_ids = [
          458636207,
        ]
      }
    }
  }

  assert {
    condition     = length(github_actions_organization_variable.variable) == 2
    error_message = "both variables created"
  }
  assert {
    condition     = github_actions_organization_variable.variable["RUNNER_LABEL"].selected_repository_ids == toset([458636207])
    error_message = "selected-visibility variable carries inline allow-list"
  }
  assert {
    condition     = output.variable_names["DEPLOY_ENV"] == "DEPLOY_ENV"
    error_message = "variable names keyed by map key"
  }
}
