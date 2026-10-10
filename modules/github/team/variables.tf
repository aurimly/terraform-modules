variable "teams" {
  description = "Map of teams keyed by arbitrary stable identifier. Keys are not team names and are not sent to GitHub; each entry holds settings plus a nested members map. Keys must not contain ':'."
  type = map(object({
    name                 = string
    description          = optional(string, "")
    privacy              = optional(string, "closed")
    notification_setting = optional(string)
    parent_team_key      = optional(string)
    members = optional(map(object({
      username = string
      role     = optional(string, "member")
    })), {})
  }))

  validation {
    condition     = alltrue([for t in var.teams : contains(["closed", "secret"], t.privacy)])
    error_message = "privacy must be one of closed or secret."
  }

  validation {
    condition     = alltrue([for t in var.teams : t.notification_setting == null || contains(["notifications_enabled", "notifications_disabled"], t.notification_setting)])
    error_message = "notification_setting must be one of notifications_enabled or notifications_disabled (left unset for the provider default, notifications_enabled)."
  }

  validation {
    condition     = alltrue([for t in var.teams : alltrue([for m in t.members : contains(["member", "maintainer"], m.role)])])
    error_message = "members role must be one of member or maintainer."
  }

  validation {
    condition = alltrue([
      for tk, t in var.teams :
      t.parent_team_key == null || contains(keys(var.teams), t.parent_team_key)
    ])
    error_message = "parent_team_key must reference a key of the same teams map."
  }

  validation {
    condition     = alltrue([for tk, t in var.teams : t.parent_team_key != tk])
    error_message = "a team cannot be its own parent; parent_team_key must reference another key in the map."
  }
}
