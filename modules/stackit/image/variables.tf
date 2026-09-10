variable "images" {
  description = "Map of STACKIT images uploaded from local files, keyed by an arbitrary identifier. Each entry uploads one image."
  type = map(object({
    name            = string
    project_id      = string
    disk_format     = string
    local_file_path = string
    region          = optional(string)
    min_disk_size   = optional(number)
    min_ram         = optional(number)
    config = optional(object({
      boot_menu                = optional(bool)
      cdrom_bus                = optional(string)
      disk_bus                 = optional(string)
      nic_model                = optional(string)
      operating_system         = optional(string)
      operating_system_distro  = optional(string)
      operating_system_version = optional(string)
      rescue_bus               = optional(string)
      rescue_device            = optional(string)
      secure_boot              = optional(bool)
      uefi                     = optional(bool)
      video_model              = optional(string)
      virtio_scsi              = optional(bool)
    }))
    labels = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for i in var.images : i.project_id != ""])
    error_message = "project_id must be set to the STACKIT project UUID."
  }

  validation {
    condition     = alltrue([for i in var.images : contains(["ami", "ari", "aki", "qcow2", "raw", "vdi", "vpc", "vmdk"], i.disk_format)])
    error_message = "disk_format must be one of ami, ari, aki, qcow2, raw, vdi, vpc or vmdk."
  }

  validation {
    condition     = alltrue([for i in var.images : i.min_disk_size == null || i.min_disk_size > 0])
    error_message = "min_disk_size must be greater than 0 when set (gigabytes)."
  }

  validation {
    condition     = alltrue([for i in var.images : i.min_ram == null || i.min_ram > 0])
    error_message = "min_ram must be greater than 0 when set (megabytes)."
  }

  validation {
    condition     = alltrue([for i in var.images : alltrue([for k, v in i.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }
}
