variable "instances" {
  description = "Map of STACKIT Secrets Manager instances keyed by an arbitrary identifier. Each entry creates one instance in the given project."
  type = map(object({
    project_id = string
    name       = string
    acls       = optional(set(string))
    kms_key = optional(object({
      key_id                = string
      key_ring_id           = string
      key_version           = number
      service_account_email = string
    }))
  }))

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.name) >= 1])
    error_message = "name must be at least 1 character."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.acls == null || alltrue([for cidr in i.acls : can(cidrhost(cidr, 0))])])
    error_message = "acls entries must be valid CIDRs (IP or IP range in CIDR notation)."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.kms_key == null || (can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.kms_key.key_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.kms_key.key_ring_id)) && i.kms_key.key_version >= 1)])
    error_message = "kms_key.key_id and kms_key.key_ring_id must be UUIDs and kms_key.key_version must be at least 1."
  }
}
