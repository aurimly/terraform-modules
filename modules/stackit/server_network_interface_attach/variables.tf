variable "server_network_interface_attaches" {
  description = "Map of STACKIT server network interface attachments keyed by an arbitrary identifier. Each entry attaches one network interface to one server."
  type = map(object({
    project_id           = string
    region               = optional(string)
    server_id            = string
    network_interface_id = string
  }))

  validation {
    condition     = alltrue([for a in var.server_network_interface_attaches : alltrue([for id in [a.project_id, a.server_id, a.network_interface_id] : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])])
    error_message = "project_id, server_id and network_interface_id must be UUIDs."
  }
}
