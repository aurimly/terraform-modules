variable "branch_protections" {
  description = "Map of branch protections keyed by an arbitrary stable identifier (typically the key of the repo in the repository unit that created it; keys must not contain ':'). The scoped nested shape matches the inline branch_protection in modules/github/repository, so config can be lifted between the two."
  type = map(object({
    repository_id  = string
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

  validation {
    condition = alltrue([
      for p in var.branch_protections :
      p.required_pull_request_reviews.required_approving_review_count >= 0 &&
      p.required_pull_request_reviews.required_approving_review_count <= 6
    ])
    error_message = "required_approving_review_count must be between 0 and 6 (the GitHub API rejects values above 6)."
  }
}
