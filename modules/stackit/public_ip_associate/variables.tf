variable "public_ip_associates" {
  description = "Map of STACKIT public IP associations keyed by an arbitrary identifier. Each entry associates one existing public IP with one network interface."
  type = map(object({
    project_id           = string
    region               = optional(string)
    public_ip_id         = string
    network_interface_id = string
  }))

  validation {
    condition     = alltrue([for a in var.public_ip_associates : alltrue([for id in [a.project_id, a.public_ip_id, a.network_interface_id] : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])])
    error_message = "project_id, public_ip_id and network_interface_id must be UUIDs."
  }
}
