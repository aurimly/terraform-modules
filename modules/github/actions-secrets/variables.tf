variable "repository" {
  description = "GitHub repository name to create the secrets in."
  type        = string
}

variable "secrets" {
  description = "Map of Actions secrets keyed by secret name. Keys are the actual secret names — GitHub secret names allow uppercase letters, digits and underscores only."
  type = map(object({
    value = string
  }))
}
