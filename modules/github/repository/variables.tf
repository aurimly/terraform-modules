variable "repositories" {
  description = "Map of GitHub repositories keyed by repo name. Each entry carries repo settings and optional branch protection. default_branch is not settable (deprecated) — new repos inherit GitHub's 'main' default; it is exported as an output."
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
}
