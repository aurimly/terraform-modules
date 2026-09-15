variable "server_service_account_attaches" {
  description = "Map of STACKIT server service account attachments keyed by an arbitrary identifier. Each entry attaches one service account to one server."
  type = map(object({
    project_id            = string
    region                = optional(string)
    server_id             = string
    service_account_email = string
  }))

  validation {
    condition     = alltrue([for a in var.server_service_account_attaches : alltrue([for id in [a.project_id, a.server_id] : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])])
    error_message = "project_id and server_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for a in var.server_service_account_attaches : length(a.service_account_email) >= 1 && can(regex("@", a.service_account_email))])
    error_message = "service_account_email must be the full service account email (e.g. from the stackit/service_account module's output email)."
  }
}
