variable "storage_accounts" {
  description = "Map of Azure storage accounts keyed by an arbitrary identifier. Each entry creates one azurerm_storage_account in the named resource group, in the subscription configured on the provider. Account names are unique across all of Azure."
  type = map(object({
    name                              = string
    resource_group_name               = string
    location                          = string
    account_tier                      = string
    account_replication_type          = string
    account_kind                      = optional(string, "StorageV2")
    access_tier                       = optional(string)
    https_traffic_only_enabled        = optional(bool, true)
    min_tls_version                   = optional(string, "TLS1_2")
    shared_access_key_enabled         = optional(bool, true)
    public_network_access             = optional(string, "Enabled")
    allow_nested_items_to_be_public   = optional(bool, false)
    infrastructure_encryption_enabled = optional(bool)
    network_rules = optional(object({
      default_action             = string
      bypass                     = optional(set(string), [])
      ip_rules                   = optional(set(string), [])
      virtual_network_subnet_ids = optional(set(string), [])
    }))
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for s in var.storage_accounts : can(regex("^[a-z0-9]{3,24}$", s.name))
    ])
    error_message = "name must be 3 to 24 lowercase alphanumeric characters — it is the DNS label behind the account's endpoint hostnames and must be globally unique across all of Azure, which the module cannot check: a name taken by an unrelated subscription fails at apply."
  }

  validation {
    condition = alltrue(flatten([
      for key, s in var.storage_accounts : [
        for other_key, t in var.storage_accounts :
        key == other_key || lower(s.name) != lower(t.name)
      ]
    ]))
    error_message = "account names must be unique across entries, case-insensitively — names are lowercase already, so this mostly guards copy-paste mistakes (Azure additionally enforces global uniqueness across all of Azure at apply)."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : length(trimspace(s.name)) > 0 && length(trimspace(s.resource_group_name)) > 0 && length(trimspace(s.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace; use an Azure region name for location — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : contains(["Standard", "Premium"], s.account_tier)
    ])
    error_message = "account_tier must be \"Standard\" or \"Premium\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], s.account_replication_type)
    ])
    error_message = "account_replication_type must be one of \"LRS\", \"ZRS\", \"GRS\", \"GZRS\", \"RAGRS\" or \"RAGZRS\" (case-sensitive, no hyphens)."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : contains(["Storage", "StorageV2", "BlobStorage", "BlockBlobStorage", "FileStorage"], s.account_kind)
    ])
    error_message = "account_kind must be one of \"Storage\", \"StorageV2\", \"BlobStorage\", \"BlockBlobStorage\" or \"FileStorage\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : !contains(["BlockBlobStorage", "FileStorage"], s.account_kind) || s.account_tier == "Premium"
    ])
    error_message = "account_kind \"BlockBlobStorage\" and \"FileStorage\" require account_tier \"Premium\" — ARM rejects those kinds with the Standard tier (premium page blob accounts under StorageV2 are a valid Azure type and this module lets Premium + StorageV2 through to ARM)."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : s.access_tier == null || (contains(["Hot", "Cool", "Cold", "Smart", "Premium"], s.access_tier) && contains(["StorageV2", "BlobStorage", "FileStorage"], s.account_kind))
    ])
    error_message = "access_tier, when set, must be one of \"Hot\", \"Cool\", \"Cold\", \"Smart\" or \"Premium\" (case-sensitive) and is only valid for account_kind \"StorageV2\", \"BlobStorage\" or \"FileStorage\" — Azure rejects it on block-blob-only, files-only and legacy general-purpose kinds."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : s.min_tls_version == "TLS1_2"
    ])
    error_message = "min_tls_version must be \"TLS1_2\" — it is the only value the current provider accepts (TLS 1.0 and 1.1 were retired); the argument is kept so consumers can pin it explicitly."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : contains(["Enabled", "Disabled", "SecuredByPerimeter"], s.public_network_access)
    ])
    error_message = "public_network_access must be one of \"Enabled\", \"Disabled\" or \"SecuredByPerimeter\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : s.network_rules == null || (
        s.network_rules.default_action == "Deny"
        && (length(s.network_rules.ip_rules) > 0 || length(s.network_rules.virtual_network_subnet_ids) > 0)
        && length(s.network_rules.ip_rules) <= 30
        && alltrue([for b in s.network_rules.bypass : contains(["AzureServices", "Logging", "Metrics", "None"], b)])
        && alltrue([for r in s.network_rules.ip_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/([0-9]|[1-2][0-9]|30))?$", r))])
        && alltrue([for id in s.network_rules.virtual_network_subnet_ids : can(regex("^/", id))])
      )
    ])
    error_message = "network_rules, when set: default_action must be \"Deny\" (Azure rejects rules with an Allow default — no block at all restores the Allow default), at least one of ip_rules or virtual_network_subnet_ids must be present, at most 30 ip_rules, bypass values must be from \"AzureServices\", \"Logging\", \"Metrics\" or \"None\", ip_rules must be bare IPv4 addresses or IPv4 CIDRs with a prefix of 0 to 30 (ARM rejects /31 and /32 and non-public addresses), and virtual_network_subnet_ids must be full ARM subnet resource IDs."
  }

  validation {
    condition = alltrue([
      for s in var.storage_accounts : length(s.tags) <= 50 && alltrue([for k, v in s.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
