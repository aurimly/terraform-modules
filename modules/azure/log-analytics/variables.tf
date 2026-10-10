variable "workspaces" {
  description = "Map of Log Analytics workspaces keyed by an arbitrary identifier. Each entry creates one azurerm_log_analytics_workspace in the named resource group; nested linked services and linked storage accounts wire into the workspace resources this module creates itself."
  type = map(object({
    name                                    = string
    resource_group_name                     = string
    location                                = string
    sku                                     = optional(string, "PerGB2018")
    retention_in_days                       = optional(number)
    daily_quota_gb                          = optional(number)
    cmk_for_query_forced                    = optional(bool)
    immediate_data_purge_on_30_days_enabled = optional(bool)
    reservation_capacity_in_gb_per_day      = optional(number)
    data_collection_rule_id                 = optional(string)
    internet_ingestion_access_type          = optional(string, "Enabled")
    internet_query_access_type              = optional(string, "Enabled")
    local_authentication_enabled            = optional(bool, true)
    allow_resource_only_permissions         = optional(bool, true)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    linked_services = optional(map(object({
      read_access_id  = optional(string)
      write_access_id = optional(string)
    })), {})

    linked_storage_accounts = optional(map(object({
      data_source_type    = string
      storage_account_ids = list(string)
    })), {})

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for workspace in var.workspaces : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{2,61}[a-zA-Z0-9]$", workspace.name))
    ])
    error_message = "name must be 4–63 characters, letters/digits/hyphens only, no leading or trailing hyphen — the workspace name is globally unique per resource group."
  }

  validation {
    condition = alltrue([
      for workspace in var.workspaces : contains(["PerGB2018", "PerNode", "Premium", "Standalone", "Standard", "CapacityReservation", "LACluster", "Unlimited"], workspace.sku)
    ])
    error_message = "sku must be one of PerGB2018, PerNode, Premium, Standalone, Standard, CapacityReservation, LACluster or Unlimited — most deployments want the default PerGB2018; LACluster applies to workspaces linked to a cluster (see Notes)."
  }

  validation {
    condition = alltrue([
      for workspace in var.workspaces : workspace.retention_in_days == null || (workspace.retention_in_days >= 30 && workspace.retention_in_days <= 730)
    ])
    error_message = "retention_in_days must be between 30 and 730 — note some regions only accept 30, 31, 60, 90, 120, 180, 365, 550 or 730; keep to that subset for region independence."
  }

  validation {
    condition = alltrue([
      for workspace in var.workspaces : workspace.daily_quota_gb == null || workspace.daily_quota_gb >= -1
    ])
    error_message = "daily_quota_gb must be -1 or higher — -1 and omission both mean no cap; any other number is the daily ingestion cap in GB."
  }

  validation {
    condition = alltrue([
      for workspace in var.workspaces : workspace.reservation_capacity_in_gb_per_day == null || (
        workspace.sku == "CapacityReservation"
        && contains([50, 100, 200, 300, 400, 500, 1000, 2000, 5000, 10000, 25000, 50000], workspace.reservation_capacity_in_gb_per_day)
      )
    ])
    error_message = "reservation_capacity_in_gb_per_day requires sku = \"CapacityReservation\" and must be one of 50, 100, 200, 300, 400, 500, 1000, 2000, 5000, 10000, 25000 or 50000 GB/day — the documented reservation levels."
  }

  validation {
    condition = alltrue([
      for workspace in var.workspaces :
      contains(["Enabled", "Disabled", "SecuredByPerimeter"], workspace.internet_ingestion_access_type)
      && contains(["Enabled", "Disabled", "SecuredByPerimeter"], workspace.internet_query_access_type)
    ])
    error_message = "internet_ingestion_access_type and internet_query_access_type must each be one of Enabled, Disabled or SecuredByPerimeter."
  }

  validation {
    condition = alltrue(flatten([
      for workspace in var.workspaces : [
        for link_key, link in workspace.linked_services : (
          (link.read_access_id != null) != (link.write_access_id != null)
          && ((link.read_access_id == null || can(regex("^/", link.read_access_id))))
          && ((link.write_access_id == null || can(regex("^/", link.write_access_id))))
        )
      ]
    ]))
    error_message = "each linked service needs exactly one of read_access_id or write_access_id — a full ARM resource ID starting with \"/\". read_access_id points at an Automation Account, write_access_id at a Log Analytics Cluster; both arm the <type>/<key> import path differently (see the Import section)."
  }

  validation {
    condition = alltrue(flatten([
      for workspace in var.workspaces : [
        for link in workspace.linked_storage_accounts :
        contains(["CustomLogs", "AzureWatson", "Query", "Ingestion", "Alerts"], link.data_source_type)
        && length(link.storage_account_ids) >= 1
        && alltrue([for id in link.storage_account_ids : can(regex("^/", id))])
      ]
    ]))
    error_message = "linked_storage_accounts entries need data_source_type from CustomLogs, AzureWatson, Query, Ingestion or Alerts and at least one full ARM storage-account resource ID (starting with \"/\")."
  }

  validation {
    condition = alltrue(flatten([
      for workspace in var.workspaces : [
        length(distinct([for link in workspace.linked_storage_accounts : link.data_source_type])) == length(workspace.linked_storage_accounts)
      ]
    ]))
    error_message = "linked storage accounts key on the data source type at the Azure API — one entry per data_source_type per workspace, so duplicates would collide (make one entry carry several storage_account_ids instead)."
  }

  validation {
    condition = alltrue(concat(
      [for workspace_key in keys(var.workspaces) : !can(regex("\\.", workspace_key))],
      flatten([
        for workspace in var.workspaces : [
          for child_key in concat(keys(workspace.linked_services), keys(workspace.linked_storage_accounts)) : !can(regex("\\.", child_key))
        ]
      ])
    ))
    error_message = "map keys of workspaces and its nested linked_services and linked_storage_accounts maps must not contain \".\" — workspace keys are composed into child identifiers of the form \"<workspace_key>.<child_key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue([
      for workspace in var.workspaces :
      workspace.identity == null || !contains(["UserAssigned", "SystemAssigned, UserAssigned"], workspace.identity.type) || alltrue([for id in coalesce(workspace.identity.identity_ids, []) : can(regex("^/", id))])
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — full ARM resource IDs of user-assigned managed identities (starting with \"/\")."
  }

  validation {
    condition = alltrue([
      for workspace in var.workspaces :
      length(workspace.tags) <= 50 && alltrue([for tag_key, tag_value in workspace.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
