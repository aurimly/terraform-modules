terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_repository" "repo" {
  for_each = var.repositories

  name                   = each.key
  description            = each.value.description
  visibility             = each.value.visibility
  topics                 = each.value.topics
  has_issues             = each.value.has_issues
  has_wiki               = each.value.has_wiki
  delete_branch_on_merge = each.value.delete_branch_on_merge
  archived               = each.value.archived
  archive_on_destroy     = true
}

resource "github_branch_protection" "protection" {
  for_each = {
    for k, r in var.repositories : k => r.branch_protection if r.branch_protection != null
  }

  repository_id  = github_repository.repo[each.key].node_id
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
