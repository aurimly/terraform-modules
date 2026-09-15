variable "keyrings" {
  description = "Map of STACKIT KMS keyrings keyed by an arbitrary identifier. Each entry creates one keyring in the given project and region. Keyrings are not destroyed by OpenTofu/Terraform — see the module README."
  type = map(object({
    project_id   = string
    display_name = string
    description  = optional(string)
    region       = optional(string)
  }))

  validation {
    condition     = alltrue([for k in var.keyrings : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", k.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for k in var.keyrings : length(k.display_name) >= 1])
    error_message = "display_name must be at least 1 character."
  }
}
