variable "file_systems" {
  description = "Map of EFS file systems keyed by an arbitrary identifier. Each entry creates one aws_efs_file_system plus optional backup policy and file system policy. name becomes the creation_token and the Name tag. Encryption defaults to true (the provider default is false — see the encrypted row)."
  type = map(object({
    name                            = string
    performance_mode                = optional(string, "generalPurpose")
    throughput_mode                 = optional(string, "bursting")
    provisioned_throughput_in_mibps = optional(number)
    encrypted                       = optional(bool, true)
    kms_key_id                      = optional(string)
    lifecycle_policy = optional(object({
      transition_to_ia                    = optional(string)
      transition_to_archive               = optional(string)
      transition_to_primary_storage_class = optional(string)
    }))
    protection = optional(object({
      replication_overwrite = optional(string)
    }))
    backup_policy = optional(object({
      status = string
    }))
    policy = optional(string)
    tags   = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.file_systems) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\" — the dot character is reserved in the composite \"fsKey.mtKey\"/\"fsKey.apKey\" resource keys."
  }

  validation {
    condition     = alltrue([for t in var.file_systems : length(t.name) >= 1 && length(t.name) <= 64])
    error_message = "name must be 1-64 characters; it becomes the creation_token, whose maximum length is 64 (EFS API limit)."
  }

  validation {
    condition     = alltrue([for t in var.file_systems : contains(["generalPurpose", "maxIO"], t.performance_mode)])
    error_message = "performance_mode must be generalPurpose or maxIO (case-sensitive); performance mode is immutable after creation."
  }

  validation {
    condition     = alltrue([for t in var.file_systems : contains(["bursting", "provisioned", "elastic"], t.throughput_mode)])
    error_message = "throughput_mode must be bursting, provisioned or elastic."
  }

  validation {
    condition     = alltrue([for t in var.file_systems : t.provisioned_throughput_in_mibps == null || t.throughput_mode == "provisioned"])
    error_message = "provisioned_throughput_in_mibps applies only with throughput_mode = provisioned (the API rejects it otherwise)."
  }

  validation {
    condition     = alltrue([for t in var.file_systems : t.kms_key_id == null || t.encrypted])
    error_message = "kms_key_id requires encrypted = true (the API rejects a KMS key on an unencrypted file system)."
  }

  validation {
    condition     = alltrue([for t in var.file_systems : t.throughput_mode != "elastic" || t.performance_mode == "generalPurpose"])
    error_message = "throughput_mode = elastic requires performance_mode = generalPurpose (Max I/O does not support Elastic throughput; One Zone file systems are out of scope for this module)."
  }

  validation {
    condition = alltrue([
      for t in var.file_systems : t.lifecycle_policy == null || t.lifecycle_policy.transition_to_ia == null || contains(["AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS"], t.lifecycle_policy.transition_to_ia)
    ])
    error_message = "lifecycle_policy.transition_to_ia must be one of AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS or AFTER_365_DAYS."
  }

  validation {
    condition = alltrue([
      for t in var.file_systems : t.lifecycle_policy == null || t.lifecycle_policy.transition_to_archive == null || contains(["AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS"], t.lifecycle_policy.transition_to_archive)
    ])
    error_message = "lifecycle_policy.transition_to_archive must be one of AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS or AFTER_365_DAYS."
  }

  validation {
    condition = alltrue([
      for t in var.file_systems : t.lifecycle_policy == null || t.lifecycle_policy.transition_to_archive == null || t.lifecycle_policy.transition_to_ia != null
    ])
    error_message = "lifecycle_policy.transition_to_archive requires transition_to_ia to be set (the API requires IA transitions before archive transitions)."
  }

  validation {
    condition = alltrue([
      for t in var.file_systems : t.lifecycle_policy == null || t.lifecycle_policy.transition_to_primary_storage_class == null || t.lifecycle_policy.transition_to_ia != null
    ])
    error_message = "lifecycle_policy.transition_to_primary_storage_class requires transition_to_ia to be set (files must live in the IA storage class before transitioning back to primary storage)."
  }

  validation {
    condition = alltrue([
      for t in var.file_systems : t.lifecycle_policy == null || t.lifecycle_policy.transition_to_primary_storage_class == null || t.lifecycle_policy.transition_to_primary_storage_class == "AFTER_1_ACCESS"
    ])
    error_message = "lifecycle_policy.transition_to_primary_storage_class must be AFTER_1_ACCESS (the only supported value)."
  }

  validation {
    condition = alltrue([
      for t in var.file_systems : t.protection == null || t.protection.replication_overwrite == null || contains(["ENABLED", "DISABLED"], t.protection.replication_overwrite)
    ])
    error_message = "protection.replication_overwrite must be ENABLED or DISABLED."
  }

  validation {
    condition = alltrue([
      for t in var.file_systems : t.backup_policy == null || contains(["ENABLED", "DISABLED"], t.backup_policy.status)
    ])
    error_message = "backup_policy.status must be ENABLED or DISABLED."
  }

  validation {
    condition = alltrue([
      for t in var.file_systems : t.policy == null || can(jsondecode(t.policy))
    ])
    error_message = "policy must be a valid JSON policy document (pass jsonencode({...}))."
  }
}

variable "mount_targets" {
  description = "Map of EFS mount targets keyed by an arbitrary identifier. Each entry creates one aws_efs_mount_target in the referenced file system. Mount targets have no tags in the API. Security groups are pass-through (pair with the aws/security-group module, port 2049)."
  type = map(object({
    fs_key             = string
    subnet_id          = string
    security_group_ids = optional(set(string))
    ip_address         = optional(string)
    ip_address_type    = optional(string)
    ipv6_address       = optional(string)
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.mount_targets) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\" — the dot character is reserved in the composite \"fsKey.mtKey\" resource keys."
  }

  validation {
    condition     = alltrue([for m in var.mount_targets : can(regex("^subnet-[0-9a-f]{8,17}$", m.subnet_id))])
    error_message = "subnet_id must be a subnet ID (subnet-...), typically dependency.network.outputs.private_subnet_ids with the aws/subnet module."
  }

  validation {
    condition     = alltrue([for m in var.mount_targets : m.ip_address_type == null || contains(["IPV4_ONLY", "IPV6_ONLY", "DUAL_STACK"], m.ip_address_type)])
    error_message = "ip_address_type must be IPV4_ONLY, IPV6_ONLY or DUAL_STACK (API default IPV4_ONLY)."
  }

  validation {
    condition     = alltrue([for m in var.mount_targets : m.ipv6_address == null || contains(["IPV6_ONLY", "DUAL_STACK"], coalesce(m.ip_address_type, "IPV4_ONLY"))])
    error_message = "ipv6_address is valid only when ip_address_type is IPV6_ONLY or DUAL_STACK (the API rejects IPv6 addresses on IPv4-only mount targets)."
  }
}

variable "access_points" {
  description = "Map of EFS access points keyed by an arbitrary identifier. Each entry creates one aws_efs_access_point on the referenced file system. posix_user is module-required (the API defaults to root 0:0 — this module requires the identity explicitly). Access points carry pass-through tags only; there is no name attribute."
  type = map(object({
    fs_key = string
    posix_user = object({
      uid            = number
      gid            = number
      secondary_gids = optional(set(number))
    })
    root_directory = optional(object({
      path = optional(string)
      creation_info = optional(object({
        owner_uid   = number
        owner_gid   = number
        permissions = string
      }))
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.access_points) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\" — the dot character is reserved in the composite \"fsKey.apKey\" resource keys."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.access_points : a.root_directory == null || a.root_directory.creation_info == null ? [true] : [
        can(regex("^[0-7]{3,4}$", a.root_directory.creation_info.permissions))
      ]
    ]))
    error_message = "root_directory.creation_info.permissions must be an octal mode string like \"0755\" (3-4 octal digits)."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.access_points : a.root_directory == null || a.root_directory.path == null ? [true] : [
        can(regex("^/", a.root_directory.path))
      ]
    ]))
    error_message = "root_directory.path must be an absolute path on the EFS file system (starts with /; up to four subdirectories deep)."
  }
}
