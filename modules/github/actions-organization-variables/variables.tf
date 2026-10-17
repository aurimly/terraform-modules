variable "variables" {
  description = "Map of organization Actions variables keyed by variable name — GitHub variable names allow uppercase letters, digits and underscores only. The inline selected_repository_ids attribute is supported on this resource (unlike the secret counterpart, where it is deprecated)."
  type = map(object({
    value                   = string
    visibility              = string
    selected_repository_ids = optional(list(number))
  }))

  validation {
    condition = alltrue([
      for key in keys(var.variables) : contains(["all", "private", "selected"], var.variables[key].visibility)
    ])
    error_message = "visibility must be one of all, private or selected (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for key, variable in var.variables : variable.selected_repository_ids == null || variable.visibility == "selected"
    ])
    error_message = "selected_repository_ids requires visibility = \"selected\"."
  }

  validation {
    condition = alltrue([
      for key, variable in var.variables : variable.visibility != "selected" || variable.selected_repository_ids != null
    ])
    error_message = "visibility = \"selected\" requires selected_repository_ids — a selected variable with an empty allow-list is unreachable by every repository."
  }

  validation {
    condition = alltrue([
      for key in keys(var.variables) : !can(regex("\\.", key))
    ])
    error_message = "variables map keys (they double as the variable name) must not contain \".\"."
  }
}
