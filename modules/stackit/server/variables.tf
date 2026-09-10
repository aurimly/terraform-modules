variable "servers" {
  description = "Map of STACKIT servers keyed by an arbitrary identifier. Each entry creates one server."
  type = map(object({
    name              = string
    project_id        = string
    machine_type      = string
    region            = optional(string)
    availability_zone = optional(string)
    image_id          = optional(string)
    boot_volume = optional(object({
      source_type           = string
      source_id             = string
      size                  = optional(number)
      performance_class     = optional(string)
      delete_on_termination = optional(bool)
    }))
    network_interface_ids     = optional(list(string))
    keypair_name              = optional(string)
    affinity_group            = optional(string)
    user_data                 = optional(string)
    desired_status            = optional(string)
    agent_provisioning_policy = optional(string)
    labels                    = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for s in var.servers : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.project_id))])
    error_message = "project_id must be a STACKIT project UUID."
  }

  validation {
    condition     = alltrue([for s in var.servers : length(s.name) >= 1 && length(s.name) <= 63 && can(regex("^[A-Za-z0-9]+((-|\\.)[A-Za-z0-9]+)*$", s.name))])
    error_message = "name must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, hyphens and dots in between (the server name rule; underscores, slashes and spaces are not allowed, unlike other IaaS resource names)."
  }

  validation {
    condition     = alltrue([for s in var.servers : length(s.machine_type) >= 1 && length(s.machine_type) <= 63 && can(regex("^[A-Za-z0-9]+((-|_|\\s|\\.)[A-Za-z0-9]+)*$", s.machine_type))])
    error_message = "machine_type must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, hyphens, underscores, dots and whitespace in between (e.g. s3.2xlarge.8)."
  }

  validation {
    condition     = alltrue([for s in var.servers : (s.image_id != null) != (s.boot_volume != null)])
    error_message = "exactly one of image_id or boot_volume must be set (the provider requires at least one and forbids both)."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.boot_volume == null || contains(["volume", "image"], s.boot_volume.source_type)])
    error_message = "boot_volume.source_type must be one of volume or image."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.boot_volume == null || s.boot_volume.source_type != "image" || s.boot_volume.size != null])
    error_message = "boot_volume.size is required (gigabytes) when boot_volume.source_type is image."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.boot_volume == null || s.boot_volume.delete_on_termination == null || s.boot_volume.source_type == "image"])
    error_message = "boot_volume.delete_on_termination is only allowed when boot_volume.source_type is image."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.network_interface_ids == null || alltrue([for ni in s.network_interface_ids : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", ni))])])
    error_message = "network_interface_ids entries must be network interface UUIDs."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.desired_status == null || contains(["active", "inactive", "deallocated"], s.desired_status)])
    error_message = "desired_status must be one of active, inactive or deallocated."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.agent_provisioning_policy == null || contains(["ALWAYS", "NEVER", "INHERIT"], s.agent_provisioning_policy)])
    error_message = "agent_provisioning_policy must be one of ALWAYS, NEVER or INHERIT."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.affinity_group == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.affinity_group))])
    error_message = "affinity_group must be an affinity group UUID."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.keypair_name == null || (length(s.keypair_name) >= 1 && length(s.keypair_name) <= 63 && can(regex("^[A-Za-z0-9]+((-|_|\\s|\\.)[A-Za-z0-9]+)*$", s.keypair_name)))])
    error_message = "keypair_name must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, hyphens, underscores, dots and whitespace in between; it must match the name of an existing STACKIT key pair."
  }

  validation {
    condition     = alltrue([for s in var.servers : alltrue([for k, v in s.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }
}
