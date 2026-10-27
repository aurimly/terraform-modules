variable "repositories" {
  description = "Map of repository access grants keyed by arbitrary stable identifier. Keys are not repository names and are not sent to GitHub; the repository attribute is. The same repository must not appear under two keys."
  type = map(object({
    repository = string
    teams = optional(map(object({
      team_id    = string
      permission = optional(string, "push")
    })), {})
    users = optional(map(object({
      username   = string
      permission = optional(string, "push")
    })), {})
  }))

  validation {
    condition = alltrue([
      for r in var.repositories : alltrue([
        for t in r.teams : contains(["pull", "triage", "push", "maintain", "admin"], t.permission)
      ])
    ])
    error_message = "teams permission must be one of pull, triage, push, maintain or admin (custom repository role names are not accepted by this module)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories : alltrue([
        for u in r.users : contains(["pull", "triage", "push", "maintain", "admin"], u.permission)
      ])
    ])
    error_message = "users permission must be one of pull, triage, push, maintain or admin (custom repository role names are not accepted by this module)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories :
      length(distinct([for u in r.users : lower(u.username)])) == length(r.users)
    ])
    error_message = "the same username must not be listed under two keys of one repo's users map (GitHub identifies collaborators case-insensitively)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories :
      length(distinct([for t in r.teams : lower(t.team_id)])) == length(r.teams)
    ])
    error_message = "the same team_id must not be listed under two keys of one repo's teams map."
  }

  validation {
    condition     = length(distinct([for r in var.repositories : lower(r.repository)])) == length(var.repositories)
    error_message = "the same repository must not be listed under two keys (each repo gets one authoritative collaborators resource; two entries would fight over it)."
  }
}
