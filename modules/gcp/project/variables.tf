variable "projects" {
  description = "Map of GCP projects keyed by an arbitrary identifier. Each entry creates one project. A project must have either org_id or folder_id set as its parent."
  type = map(object({
    name                = string
    project_id          = string
    org_id              = optional(string)
    folder_id           = optional(string)
    billing_account     = string
    auto_create_network = optional(bool, false)
    deletion_policy     = optional(string, "PREVENT")
    labels              = optional(map(string), {})
  }))
}
