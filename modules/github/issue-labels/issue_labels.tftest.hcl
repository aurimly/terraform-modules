mock_provider "github" {
  mock_resource "github_issue_label" {
    defaults = {
      id  = "example-repo:urgent"
      url = "https://github.com/example-org/example-repo/labels/urgent"
    }
  }
}

run "full_labels" {
  command = plan

  variables {
    repository = "example-repo"

    labels = {
      "urgent" = {
        color       = "FF0000"
        description = "Drop everything."
      }
      "triage" = {
        color = "FBCA04"
      }
    }
  }

  assert {
    condition     = length(github_issue_label.label) == 2
    error_message = "two labels expected"
  }
  assert {
    condition     = github_issue_label.label["urgent"].color == "FF0000"
    error_message = "color carried through without the # prefix"
  }
  assert {
    condition     = output.label_names["urgent"] == "urgent"
    error_message = "label names keyed by map key"
  }
}
