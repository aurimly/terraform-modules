variable "instances" {
  description = "Map of Filestore instances keyed by an arbitrary identifier. Each entry creates one google_filestore_instance plus optional backups."
  type = map(object({
    name                        = string
    location                    = string
    tier                        = string
    project_id                  = optional(string)
    description                 = optional(string)
    labels                      = optional(map(string), {})
    protocol                    = optional(string)
    kms_key_name                = optional(string)
    deletion_protection_enabled = optional(bool)
    deletion_protection_reason  = optional(string)
    file_shares = object({
      capacity_gb   = number
      name          = string
      source_backup = optional(string)
      nfs_export_options = optional(map(object({
        ip_ranges   = list(string)
        access_mode = string
        squash_mode = optional(string)
        anon_uid    = optional(number)
        anon_gid    = optional(number)
      })), {})
    })
    networks = object({
      network           = string
      modes             = list(string)
      connect_mode      = optional(string)
      reserved_ip_range = optional(string)
    })
    performance_config = optional(object({
      iops_per_tb = optional(object({
        max_iops_per_tb = optional(number)
      }))
      fixed_iops = optional(object({
        max_iops = optional(number)
      }))
    }))
    backups = optional(map(object({
      name        = string
      location    = optional(string)
      description = optional(string)
      labels      = optional(map(string), {})
    })), {})
  }))

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", i.name))])
    error_message = "name must follow RFC1035: lowercase letters, digits and hyphens, starting with a letter, 1 to 63 characters (Filestore naming rules)."
  }

  validation {
    condition     = alltrue([for i in var.instances : contains(["STANDARD", "PREMIUM", "BASIC_HDD", "BASIC_SSD", "HIGH_SCALE_SSD", "ZONAL", "REGIONAL", "ENTERPRISE"], i.tier)])
    error_message = "tier must be one of STANDARD, PREMIUM, BASIC_HDD, BASIC_SSD, HIGH_SCALE_SSD, ZONAL, REGIONAL or ENTERPRISE (case-sensitive; STANDARD and PREMIUM are deprecated aliases of BASIC_HDD and BASIC_SSD)."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", i.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.protocol == null || contains(["NFS_V3", "NFS_V4_1"], i.protocol)])
    error_message = "protocol must be one of NFS_V3 or NFS_V4_1 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.file_shares.capacity_gb > 0])
    error_message = "file_shares.capacity_gb must be greater than 0; per-tier minimums and increments vary (see README) and the API rejects undersized values."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.file_shares.name) <= 16])
    error_message = "file_shares.name must be at most 16 characters (Filestore file share naming limit)."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.networks.modes) > 0 && alltrue([for m in i.networks.modes : contains(["MODE_IPV4", "MODE_IPV6"], m)])])
    error_message = "networks.modes must be a non-empty list of MODE_IPV4 and/or MODE_IPV6 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.networks.connect_mode == null || contains(["PRIVATE_SERVICE_ACCESS", "DIRECT_PEERING"], i.networks.connect_mode)])
    error_message = "networks.connect_mode must be one of PRIVATE_SERVICE_ACCESS or DIRECT_PEERING (case-sensitive)."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for n in i.file_shares.nfs_export_options : contains(["READ_WRITE", "READ_ONLY"], n.access_mode)])])
    error_message = "file_shares.nfs_export_options.access_mode must be one of READ_WRITE or READ_ONLY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for n in i.file_shares.nfs_export_options : n.squash_mode == null || contains(["ROOT_SQUASH", "NO_ROOT_SQUASH"], n.squash_mode)])])
    error_message = "file_shares.nfs_export_options.squash_mode must be one of ROOT_SQUASH or NO_ROOT_SQUASH (case-sensitive)."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for n in i.file_shares.nfs_export_options : (n.anon_uid == null && n.anon_gid == null) || n.squash_mode == "ROOT_SQUASH"])])
    error_message = "file_shares.nfs_export_options.anon_uid/anon_gid may only be set when squash_mode is ROOT_SQUASH."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.performance_config == null || ((i.performance_config.iops_per_tb != null && i.performance_config.iops_per_tb.max_iops_per_tb != null) || (i.performance_config.fixed_iops != null && i.performance_config.fixed_iops.max_iops != null))])
    error_message = "performance_config requires iops_per_tb.max_iops_per_tb or fixed_iops.max_iops to be set (an empty performance_config block is not valid)."
  }

  validation {
    condition     = alltrue([for i in var.instances : alltrue([for b in i.backups : can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", b.name))])])
    error_message = "backups.name must follow RFC1035: lowercase letters, digits and hyphens, starting with a letter, 1 to 63 characters (Filestore backup naming rules)."
  }
}
