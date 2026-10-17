variable "repository" {
  description = "GitHub repository name to create the labels in."
  type        = string
}

variable "labels" {
  description = "Map of labels keyed by an arbitrary stable identifier — the map key becomes the label's display name on GitHub. Pre-existing labels with the same name produce an update (the provider upserts), but names must be unique within the map."
  type = map(object({
    color       = string
    description = optional(string)
  }))

  validation {
    condition = alltrue([
      for key, label in var.labels : can(regex("^[0-9a-fA-F]{6}$", label.color))
    ])
    error_message = "color must be a 6-character hexadecimal code without the leading \"#\" — GitHub rejects anything else."
  }
}
