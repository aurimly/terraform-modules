variable "role_grants" {
  description = "Map of account-role grants keyed by an arbitrary identifier. Each entry grants one account role to one user or one parent role, creating the role hierarchy edge."
  type = map(object({
    role_name        = string
    user_name        = optional(string)
    parent_role_name = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for g in var.role_grants : (g.user_name == null) != (g.parent_role_name == null)])
    error_message = "set exactly one of user_name or parent_role_name as the grantee."
  }

  validation {
    condition = alltrue([
      for g in var.role_grants :
      length(trimspace(g.role_name)) > 0 && !can(regex("\\|", g.role_name)) &&
      (g.user_name == null || length(trimspace(g.user_name)) > 0 && !can(regex("\\|", g.user_name))) &&
      (g.parent_role_name == null || length(trimspace(g.parent_role_name)) > 0 && !can(regex("\\|", g.parent_role_name)))
    ])
    error_message = "role_name/user_name/parent_role_name must be non-empty and must not contain \"|\" (the import identifier separates fields with pipes). Quoted fully qualified identifiers are accepted."
  }

  validation {
    condition = alltrue(flatten([
      for key, g in var.role_grants : [
        for other_key, n in var.role_grants :
        key == other_key ||
        g.role_name != n.role_name ||
        ((g.user_name != null) != (n.user_name != null)) ||
        coalesce(g.user_name, g.parent_role_name) != coalesce(n.user_name, n.parent_role_name)
      ]
    ]))
    error_message = "two entries granting the same role to the same grantee (role and grantee compared as written, including the role's type — user vs parent role) conflict at apply — Snowflake re-granting errors on the duplicate."
  }
}
