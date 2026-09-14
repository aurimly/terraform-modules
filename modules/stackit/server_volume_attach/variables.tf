variable "server_volume_attaches" {
  description = "Map of STACKIT server volume attachments keyed by an arbitrary identifier. Each entry attaches one volume to one server."
  type = map(object({
    project_id = string
    region     = optional(string)
    server_id  = string
    volume_id  = string
  }))

  validation {
    condition     = alltrue([for a in var.server_volume_attaches : alltrue([for id in [a.project_id, a.server_id, a.volume_id] : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])])
    error_message = "project_id, server_id and volume_id must be UUIDs."
  }
}
