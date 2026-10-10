terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_branch_protection" "protection" {
  for_each = var.branch_protections

  repository_id  = each.value.repository_id
  pattern        = each.value.branch
  enforce_admins = each.value.enforce_admins

  required_pull_request_reviews {
    required_approving_review_count = each.value.required_pull_request_reviews.required_approving_review_count
    dismiss_stale_reviews           = each.value.required_pull_request_reviews.dismiss_stale_reviews
  }

  required_status_checks {
    strict   = each.value.required_status_checks.strict
    contexts = each.value.required_status_checks.contexts
  }

  allows_force_pushes = each.value.allows_force_pushes
}
