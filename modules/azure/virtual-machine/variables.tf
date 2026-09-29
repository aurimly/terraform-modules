variable "virtual_machines" {
  description = "Map of Azure virtual machines keyed by an arbitrary identifier. Each entry creates either an azurerm_linux_virtual_machine or an azurerm_windows_virtual_machine depending on os_type — the entry's key addresses whichever resource it lands in."
  type = map(object({
    os_type             = string
    name                = string
    resource_group_name = string
    location            = string
    size                = string
    admin_username      = string
    admin_password      = optional(string)
    admin_ssh_keys = optional(map(object({
      public_key = string
    })), {})
    disable_password_authentication = optional(bool, true)
    computer_name                   = optional(string)
    zone                            = optional(string)
    availability_set_id             = optional(string)
    network_interface_ids           = list(string)
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    source_image_id = optional(string)
    custom_data     = optional(string)
    os_disk = object({
      storage_account_type = string
      caching              = string
      disk_size_gb         = optional(number)
    })
    boot_diagnostics = optional(object({
      storage_account_uri = optional(string)
    }))
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for v in var.virtual_machines : contains(["Linux", "Windows"], v.os_type)
    ])
    error_message = "os_type must be \"Linux\" or \"Windows\" (case-sensitive) — it picks the resource type each entry creates."
  }

  validation {
    condition = alltrue(flatten([
      for key, v in var.virtual_machines : [
        for other_key, w in var.virtual_machines :
        key == other_key || lower(v.name) != lower(w.name) || lower(v.resource_group_name) != lower(w.resource_group_name)
      ]
    ]))
    error_message = "virtual machine names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : length(trimspace(v.name)) > 0 && length(trimspace(v.resource_group_name)) > 0 && length(trimspace(v.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace; use an Azure region name for location — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : length(trimspace(v.size)) > 0
    ])
    error_message = "size must not be empty, e.g. \"Standard_B2s\"."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : length(trimspace(v.admin_username)) > 0 && (v.os_type != "Windows" || (v.admin_password != null && length(v.admin_password) > 0))
    ])
    error_message = "admin_username must not be empty, and Windows entries require admin_password (the provider also plan-time-validates password complexity and reserved admin usernames, e.g. admin, root, guest)."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : v.os_type != "Linux" || v.disable_password_authentication != true || v.admin_password == null
    ])
    error_message = "Linux entries with disable_password_authentication = true (the default) must leave admin_password unset."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : v.os_type != "Windows" || length(v.admin_ssh_keys) == 0
    ])
    error_message = "Windows entries must leave admin_ssh_keys empty — the Windows resource does not support SSH keys; use admin_password."
  }

  validation {
    condition = alltrue(flatten([
      for v in var.virtual_machines : [
        for k, key in v.admin_ssh_keys : length(trimspace(key.public_key)) > 0
      ]
    ]))
    error_message = "admin_ssh_keys.*.public_key must not be empty — the provider parses the key at plan time and only accepts valid RSA (2048+ bits) or ED25519 public keys."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : v.os_type != "Linux" || (
        v.disable_password_authentication == false ? (v.admin_password != null && length(v.admin_password) > 0) : length(v.admin_ssh_keys) > 0
      )
    ])
    error_message = "Linux entries must either set disable_password_authentication = false with an admin_password (SSH keys do not satisfy the provider's check), or keep password authentication disabled with at least one admin_ssh_key."
  }

  validation {
    condition = alltrue(flatten([
      for v in var.virtual_machines : [
        contains(["Premium_LRS", "Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Premium_ZRS"], v.os_disk.storage_account_type) && contains(["None", "ReadOnly", "ReadWrite"], v.os_disk.caching)
      ]
    ]))
    error_message = "os_disk.storage_account_type must be one of Premium_LRS, Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS or Premium_ZRS and os_disk.caching must be one of None, ReadOnly or ReadWrite (all case-sensitive)."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : v.os_disk.disk_size_gb == null || v.os_disk.disk_size_gb > 0
    ])
    error_message = "os_disk.disk_size_gb must be a positive number of gigabytes or left unset (Azure sizes the disk from the image)."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : (v.source_image_reference != null) != (v.source_image_id != null)
    ])
    error_message = "set exactly one of source_image_reference or source_image_id — the provider enforces exactly-one-of across the image sources (os_managed_disk_id is not exposed by this module)."
  }

  validation {
    condition = alltrue(flatten([
      for v in var.virtual_machines : [
        v.source_image_reference == null || (
          length(trimspace(v.source_image_reference.publisher)) > 0 && length(trimspace(v.source_image_reference.offer)) > 0 && length(trimspace(v.source_image_reference.sku)) > 0 && length(trimspace(v.source_image_reference.version)) > 0
        ),
        v.source_image_id == null || can(regex("^/", v.source_image_id))
      ]
    ]))
    error_message = "source_image_reference attributes (publisher, offer, sku, version) must be non-empty when the reference is set; source_image_id, when set, must be a full ARM resource ID (starts with \"/\")."
  }

  validation {
    condition = alltrue(flatten([
      for key, v in var.virtual_machines : [
        length(v.network_interface_ids) > 0,
        alltrue([for id in v.network_interface_ids : can(regex("^/", id))]),
        alltrue([
          for other_key, w in var.virtual_machines :
          key == other_key || length(setintersection(v.network_interface_ids, w.network_interface_ids)) == 0
        ])
      ]
    ]))
    error_message = "network_interface_ids must be a non-empty list of full ARM resource IDs (start with \"/\"), and a NIC may not appear in two entries — ARM attaches a network interface to one virtual machine at a time. Wire them from azure/network-interface's network_interface_ids output."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : (v.zone == null || contains(["1", "2", "3"], v.zone)) && (v.zone == null || v.availability_set_id == null)
    ])
    error_message = "zone must be \"1\", \"2\" or \"3\" (case-sensitive) or left unset, and zone is mutually exclusive with availability_set_id (mirrors the provider's conflict rule)."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : v.availability_set_id == null || can(regex("^/", v.availability_set_id))
    ])
    error_message = "availability_set_id, when set, must be a full ARM resource ID (starts with \"/\")."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : v.computer_name == null || length(trimspace(v.computer_name)) > 0
    ])
    error_message = "computer_name, when set, must not be empty — Windows names are limited to 15 characters and Linux to 64 (the provider validates and does not truncate)."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : v.custom_data == null || length(v.custom_data) > 0
    ])
    error_message = "custom_data, when set, must be non-empty — pass base64-encoded data (e.g. base64encode(file(\"cloud-init.yaml\"))); the provider validates the encoding at plan time."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : v.boot_diagnostics == null || v.boot_diagnostics.storage_account_uri == null || can(regex("^https://", v.boot_diagnostics.storage_account_uri))
    ])
    error_message = "boot_diagnostics.storage_account_uri, when set, must be an https:// blob endpoint; leaving it null inside boot_diagnostics switches to platform-managed storage."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_machines : length(v.tags) <= 50 && alltrue([for k, val in v.tags : length(k) <= 512 && length(val) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
