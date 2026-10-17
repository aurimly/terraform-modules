variable "secrets" {
  description = "Map of organization Actions secrets keyed by secret name — GitHub secret names allow uppercase letters, digits and underscores only. The standalone github_actions_organization_secret_repositories resource is created for entries with selected_repository_ids (the inline attribute on the secret resource itself is deprecated by the provider)."
  type = map(object({
    value                   = string
    visibility              = string
    selected_repository_ids = optional(list(number))
  }))

  validation {
    condition = alltrue([
      for key in keys(var.secrets) : contains(["all", "private", "selected"], var.secrets[key].visibility)
    ])
    error_message = "visibility must be one of all, private or selected (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for key, secret in var.secrets : secret.selected_repository_ids == null || secret.visibility == "selected"
    ])
    error_message = "selected_repository_ids requires visibility = \"selected\" — the repository allow-list only applies to selected-visibility secrets."
  }

  validation {
    condition = alltrue([
      for key, secret in var.secrets : secret.visibility != "selected" || secret.selected_repository_ids != null
    ])
    error_message = "visibility = \"selected\" requires selected_repository_ids — a selected secret with an empty allow-list is unreachable by every repository."
  }

  validation {
    condition = alltrue([
      for key in keys(var.secrets) : !can(regex("\\.", key))
    ])
    error_message = "secrets map keys (they double as the secret name) must not contain \".\"."
  }
}
