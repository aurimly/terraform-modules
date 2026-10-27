variable "members" {
  description = "Map of organization members keyed by arbitrary stable identifier. Keys are not usernames and are not sent to GitHub; the username attribute is. The same username must not appear under two keys."
  type = map(object({
    username             = string
    role                 = optional(string, "member")
    downgrade_on_destroy = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for m in var.members : contains(["member", "admin"], m.role)])
    error_message = "role must be one of member or admin."
  }

  validation {
    condition     = length(distinct([for m in var.members : lower(m.username)])) == length(var.members)
    error_message = "the same username must not be listed under two keys (GitHub identifies memberships case-insensitively)."
  }
}
