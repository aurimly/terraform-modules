variable "public_ips" {
  description = "Map of STACKIT public IPs keyed by an arbitrary identifier. Each entry allocates one public IP in the given project and region, optionally associated with a network interface."
  type = map(object({
    project_id           = string
    region               = optional(string)
    network_interface_id = optional(string)
    labels               = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for p in var.public_ips : p.project_id != ""])
    error_message = "project_id must be set to the STACKIT project UUID."
  }

  validation {
    condition     = alltrue([for p in var.public_ips : alltrue([for k, v in p.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }

  validation {
    condition     = alltrue([for p in var.public_ips : p.network_interface_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", p.network_interface_id))])
    error_message = "network_interface_id must be a UUID."
  }
}
