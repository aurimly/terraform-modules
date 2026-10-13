variable "container_app_environments" {
  description = "Map of Azure Container Apps managed environments keyed by an arbitrary identifier. Each entry creates one azurerm_container_app_environment in the named resource group; environment names are scoped to the resource group, while the service-generated default domain is globally unique. Apps (see the azure/container-app module) attach by full ARM ID — reference environment_ids."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    logs_destination                            = optional(string)
    log_analytics_workspace_id                  = optional(string)
    dapr_application_insights_connection_string = optional(string)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    infrastructure_subnet_id           = optional(string)
    infrastructure_resource_group_name = optional(string)
    internal_load_balancer_enabled     = optional(bool)
    zone_redundancy_enabled            = optional(bool)
    public_network_access              = optional(string)
    mutual_tls_enabled                 = optional(bool, false)

    workload_profile = optional(map(object({
      name                  = string
      workload_profile_type = string
      maximum_count         = optional(number)
      minimum_count         = optional(number)
    })), {})

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for environment_key in keys(var.container_app_environments) : length(trimspace(environment_key)) > 0 && !can(regex("\\.", environment_key))
    ])
    error_message = "map keys of container_app_environments must be non-empty and must not contain \".\" — keys are the identifiers referenced in the module's outputs (environment_ids and friends); dots would make Terragrunt dependency lookups ambiguous."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,58}[a-zA-Z0-9]?$", environment.name)) && !can(regex("-$", environment.name))
    ])
    error_message = "name must be 2–60 characters, alphanumeric or hyphen, not starting or ending with a hyphen — the provider's managed-environment name rule."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : length(trimspace(environment.name)) > 0 && length(trimspace(environment.resource_group_name)) > 0 && length(trimspace(environment.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : environment.logs_destination == null || contains(["log-analytics", "azure-monitor"], environment.logs_destination)
    ])
    error_message = "logs_destination must be \"log-analytics\" or \"azure-monitor\" when set (case-sensitive) — omit it for environments that only stream logs."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : (environment.log_analytics_workspace_id != null) == (environment.logs_destination == "log-analytics")
    ])
    error_message = "log_analytics_workspace_id and logs_destination pair exactly: a workspace ID requires logs_destination = \"log-analytics\" and \"log-analytics\" requires a workspace ID — the provider rejects any other pairing (\"azure-monitor\" keeps its own table, streamed-only environments leave both unset). Changing either is an in-place update."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : environment.log_analytics_workspace_id == null || can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.OperationalInsights/workspaces/.+$", environment.log_analytics_workspace_id))
    ])
    error_message = "log_analytics_workspace_id, when set, must be a full ARM workspace ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>\") — typically dependency.log.outputs.workspace_ids[...] from the azure/log-analytics module; changing it is an in-place update that re-wires the log destination."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : environment.dapr_application_insights_connection_string == null || length(trimspace(environment.dapr_application_insights_connection_string)) > 0
    ])
    error_message = "dapr_application_insights_connection_string, when set, must be a non-empty Application Insights connection string — Dapr uses it to export service-to-service telemetry. Set at creation only: changing it forces environment replacement."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : environment.infrastructure_subnet_id == null || can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", environment.infrastructure_subnet_id))
    ])
    error_message = "infrastructure_subnet_id, when set, must be a full ARM subnet ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>\") — typically dependency.subnet.outputs.subnet_ids[...] from the azure/subnet module. The subnet must be dedicated to the environment and sized per Notes; set at creation only (changing it forces environment replacement)."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : !coalesce(environment.internal_load_balancer_enabled, false) || environment.infrastructure_subnet_id != null
    ])
    error_message = "internal_load_balancer_enabled = true requires infrastructure_subnet_id — ILB mode is only defined for VNet-injected environments, and the provider enforces the pairing. Set at creation only: changing it forces environment replacement."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : !coalesce(environment.zone_redundancy_enabled, false) || environment.infrastructure_subnet_id != null
    ])
    error_message = "zone_redundancy_enabled = true requires infrastructure_subnet_id — zone spreading is only defined for VNet-injected environments, and the provider enforces the pairing. Set at creation only: changing it forces environment replacement."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : environment.infrastructure_resource_group_name == null || length(environment.workload_profile) > 0
    ])
    error_message = "infrastructure_resource_group_name requires a non-empty workload_profile map — the platform-managed resource group only exists for workload-profile environments, and the provider enforces the pairing. Set at creation only: changing it forces environment replacement."
  }

  validation {
    condition = alltrue([
      for environment_key, environment in var.container_app_environments :
      length(distinct([for workload_profile_key, workload_profile in environment.workload_profile : lower(workload_profile.name)])) == length(environment.workload_profile)
    ])
    error_message = "workload profile names must be unique within the environment, case-insensitively — Azure addresses profiles by name from the app side (container apps set workload_profile_name = profile name)."
  }

  validation {
    condition = alltrue(flatten([
      for environment in var.container_app_environments : [
        for workload_profile in environment.workload_profile :
        contains(["Consumption", "Consumption-GPU-NC24-A100", "Consumption-GPU-NC8as-T4", "D4", "D8", "D16", "D32", "E4", "E8", "E16", "E32", "NC24-A100", "NC48-A100", "NC96-A100"], workload_profile.workload_profile_type)
      ]
    ]))
    error_message = "workload_profile_type must be one of Consumption, Consumption-GPU-NC24-A100, Consumption-GPU-NC8as-T4, D4, D8, D16, D32, E4, E8, E16, E32, NC24-A100, NC48-A100 or NC96-A100 (case-sensitive) — the provider's own value list; a typo fails at plan here before Azure can."
  }

  validation {
    condition = alltrue(flatten([
      for environment in var.container_app_environments : [
        for workload_profile in environment.workload_profile : (workload_profile.workload_profile_type == "Consumption") == (workload_profile.name == "Consumption")
      ]
    ]))
    error_message = "a Consumption-type workload profile must be named \"Consumption\" and only the profile named \"Consumption\" may carry the Consumption type — the service hosts exactly one consumption profile, and the provider silently discards name/type/counts mismatches around it."
  }

  validation {
    condition = alltrue(flatten([
      for environment in var.container_app_environments : [
        for workload_profile in environment.workload_profile :
        workload_profile.workload_profile_type != "Consumption" || (workload_profile.maximum_count == null && workload_profile.minimum_count == null)
      ]
    ]))
    error_message = "minimum_count/maximum_count apply to dedicated workload profiles (D*/E*/NC*/Consumption-GPU-*) only — the Consumption profile autoscales on its own and the provider silently drops any counts set on it."
  }

  validation {
    condition = alltrue(flatten([
      for environment in var.container_app_environments : [
        for workload_profile in environment.workload_profile :
        workload_profile.maximum_count == null || (workload_profile.maximum_count >= 1 && (workload_profile.minimum_count == null || workload_profile.minimum_count <= workload_profile.maximum_count))
      ]
    ]))
    error_message = "maximum_count, when set, must be at least 1, and minimum_count must not exceed maximum_count — the dedicated-profile instance range Azure scales between."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments :
      length([for workload_profile in environment.workload_profile : workload_profile.workload_profile_type if workload_profile.workload_profile_type == "Consumption"]) <= 1
    ])
    error_message = "at most one Consumption workload profile per environment — the service hosts exactly one consumption profile per environment (see the \"Consumption\" name rule)."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : environment.public_network_access == null || contains(["Enabled", "Disabled"], environment.public_network_access)
    ])
    error_message = "public_network_access must be \"Enabled\" or \"Disabled\" (case-sensitive) — omit it (leave null) to let Azure decide based on the environment's VNet provisioning; the attribute is computed by Azure and a hard default would produce perpetual diffs."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : !(environment.public_network_access == "Enabled" && environment.internal_load_balancer_enabled)
    ])
    error_message = "public_network_access cannot be \"Enabled\" together with internal_load_balancer_enabled = true — a fully internal environment has no public path to keep open, and the provider rejects the combination."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : environment.identity == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], environment.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned or \"SystemAssigned, UserAssigned\" (case-sensitive as written)."
  }

  validation {
    condition = alltrue([
      for environment in var.container_app_environments : environment.identity == null || !can(regex("UserAssigned", environment.identity.type)) || length(environment.identity.identity_ids) > 0
    ])
    error_message = "identity.identity_ids must carry at least one user-assigned identity ARM ID when identity.type contains \"UserAssigned\"."
  }

  validation {
    condition = alltrue([
      for environment_key, environment in var.container_app_environments :
      length(environment.tags) <= 50 && alltrue([for tag_key, tag_value in environment.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (Azure-enforced limits)."
  }
}
