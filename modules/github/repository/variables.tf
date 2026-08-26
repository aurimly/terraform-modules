variable "repositories" {
  description = "Map of GitHub repositories keyed by repo name. Each entry carries repo settings and optional branch protection. default_branch is not settable (deprecated in v6) — new repos get the account's configured default branch name (GitHub's own default is 'main')."
  type = map(object({
    description            = optional(string, "")
    visibility             = optional(string, "private")
    topics                 = optional(list(string), [])
    has_issues             = optional(bool, false)
    has_wiki               = optional(bool, false)
    has_projects           = optional(bool, false)
    delete_branch_on_merge = optional(bool, true)
    archived               = optional(bool, false)
    branch_protection = optional(object({
      branch         = optional(string, "main")
      enforce_admins = optional(bool, true)
      required_pull_request_reviews = optional(object({
        required_approving_review_count = optional(number, 0)
        dismiss_stale_reviews           = optional(bool, false)
      }), {})
      required_status_checks = optional(object({
        strict   = optional(bool, false)
        contexts = optional(list(string), [])
      }), {})
      allows_force_pushes = optional(bool, false)
    }))
  }))

  validation {
    condition     = alltrue([for r in var.repositories : contains(["public", "private", "internal"], r.visibility)])
    error_message = "visibility must be one of public, private or internal."
  }

  validation {
    condition = alltrue([
      for r in var.repositories :
      r.branch_protection == null ||
      (r.branch_protection.required_pull_request_reviews.required_approving_review_count >= 0 &&
      r.branch_protection.required_pull_request_reviews.required_approving_review_count <= 6)
    ])
    error_message = "required_approving_review_count must be between 0 and 6 (GitHub API rejects values above 6)."
  }
}
