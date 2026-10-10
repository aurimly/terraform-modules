variable "repository" {
  description = "GitHub repository name to create the environments in. Must already exist (use modules/github/repository or a data source to wire it)."
  type        = string
}

variable "environments" {
  description = "Map of environments keyed by arbitrary stable identifier. Keys are not environment names and are not sent to GitHub; the environment attribute is the name. Keys must not contain ':'."
  type = map(object({
    environment         = string
    wait_timer          = optional(number)
    can_admins_bypass   = optional(bool, true)
    prevent_self_review = optional(bool, false)
    reviewers = optional(object({
      users = optional(list(number), [])
      teams = optional(list(number), [])
    }))
    deployment_branch_policy = optional(object({
      protected_branches     = optional(bool)
      custom_branch_policies = optional(bool)
      branch_patterns        = optional(list(string), [])
      tag_patterns           = optional(list(string), [])
    }))
    secrets = optional(map(object({
      value = string
    })), {})
    variables = optional(map(object({
      value = string
    })), {})
  }))

  validation {
    condition = alltrue([
      for e in var.environments :
      e.wait_timer == null || (e.wait_timer >= 0 && e.wait_timer <= 43200)
    ])
    error_message = "wait_timer must be between 0 and 43200 seconds (24h) — the GitHub API rejects other values."
  }

  validation {
    condition = alltrue([
      for e in var.environments :
      e.deployment_branch_policy == null || (
        coalesce(e.deployment_branch_policy.protected_branches, false) != coalesce(e.deployment_branch_policy.custom_branch_policies, false) &&
        (e.deployment_branch_policy.protected_branches != null || e.deployment_branch_policy.custom_branch_policies != null)
      )
    ])
    error_message = "deployment_branch_policy must set exactly one mode: set exactly one of protected_branches or custom_branch_policies to true and the other to false — the GitHub API rejects 0/0 (422) and nothing set."
  }

  validation {
    condition = alltrue([
      for e in var.environments :
      e.reviewers == null || length(e.reviewers.users) + length(e.reviewers.teams) <= 6
    ])
    error_message = "reviewers may contain at most 6 users and teams combined — the GitHub API rejects more."
  }

  validation {
    condition = alltrue([
      for e in var.environments :
      e.reviewers == null || length(e.reviewers.users) + length(e.reviewers.teams) > 0
    ])
    error_message = "reviewers set with no users and no teams is meaningless; either add reviewers or drop the reviewers object."
  }

  validation {
    condition = alltrue([
      for e in var.environments :
      e.deployment_branch_policy == null || e.deployment_branch_policy.custom_branch_policies ||
      (length(e.deployment_branch_policy.branch_patterns) == 0 && length(e.deployment_branch_policy.tag_patterns) == 0)
    ])
    error_message = "branch_patterns and tag_patterns are only allowed in custom_branch_policies mode — the patterns are rejected when protected_branches mode is on."
  }
}
