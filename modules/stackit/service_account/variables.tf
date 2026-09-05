variable "service_accounts" {
  description = "Map of STACKIT service accounts keyed by an arbitrary identifier. Each entry creates one service account in the given project."
  type = map(object({
    name       = string
    project_id = string
  }))

  validation {
    condition     = alltrue([for sa in var.service_accounts : sa.project_id != ""])
    error_message = "project_id must be set to the STACKIT project UUID."
  }

  validation {
    condition     = length(var.service_accounts) == length(distinct([for sa in var.service_accounts : "${sa.project_id},${sa.name}"]))
    error_message = "duplicate service account: the same (project_id, name) combination must not appear under more than one key (the API rejects duplicate names per project — \"Name not unique\")."
  }
}
