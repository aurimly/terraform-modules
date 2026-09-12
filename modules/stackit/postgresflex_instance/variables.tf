variable "instances" {
  description = "Map of STACKIT PostgreSQL Flex instances keyed by an arbitrary identifier. Each entry creates one instance in the given project and region. network.acl is required: the provider requires exactly one ACL form and this module only supports the non-deprecated network.acl."
  type = map(object({
    project_id      = string
    name            = string
    version         = string
    backup_schedule = string
    storage = object({
      class = string
      size  = number
    })
    flavor_id      = string
    region         = optional(string)
    retention_days = optional(number)
    network = object({
      acl          = list(string)
      access_scope = optional(string)
    })
    encryption = optional(object({
      kek_key_id      = string
      kek_keyring_id  = string
      kek_key_version = string
      service_account = string
    }))
  }))

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", i.name))])
    error_message = "name must start with a lowercase letter and contain only lowercase letters, digits or hyphens, without a trailing hyphen."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.backup_schedule) >= 1 && can(regex("^\\S+\\s+\\S+\\s+\\S+\\s+\\S+\\s+\\S+$", i.backup_schedule))])
    error_message = "backup_schedule must be a cron expression with five whitespace-separated fields (minute hour day-of-month month day-of-week)."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.storage.size >= 1])
    error_message = "storage.size must be at least 1."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.retention_days == null || (i.retention_days >= 32 && i.retention_days <= 90)])
    error_message = "retention_days must be between 32 and 90 when set."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.network.acl) >= 1 && alltrue([for cidr in i.network.acl : can(cidrhost(cidr, 0)) && can(regex("\\.", cidr))])])
    error_message = "network.acl must be a non-empty list of valid IPv4 CIDRs (the provider requires exactly one ACL form and this module only supports network.acl — see the module README)."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.network.access_scope == null || contains(["PUBLIC", "SNA"], i.network.access_scope)])
    error_message = "network.access_scope must be one of PUBLIC or SNA."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.encryption == null || (can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.encryption.kek_key_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.encryption.kek_keyring_id)))])
    error_message = "encryption.kek_key_id and encryption.kek_keyring_id must be UUIDs."
  }
}
