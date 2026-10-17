variable "service_plans" {
  description = "Map of App Service Plans keyed by an arbitrary identifier. Function apps (Linux and Windows) bind to plans via service_plan_key."
  type = map(object({
    name                            = string
    resource_group_name             = string
    location                        = string
    os_type                         = string
    sku_name                        = string
    worker_count                    = optional(number)
    maximum_elastic_worker_count    = optional(number)
    premium_plan_auto_scale_enabled = optional(bool)
    per_site_scaling_enabled        = optional(bool, false)
    zone_balancing_enabled          = optional(bool, false)
    app_service_environment_id      = optional(string)
    tags                            = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key in keys(var.service_plans) : !can(regex("\\.", key))
    ])
    error_message = "service_plans map keys must not contain \".\"."
  }

  validation {
    condition = alltrue(flatten([
      for key, p in var.service_plans : [
        for other_key, q in var.service_plans :
        key == other_key || lower(p.name) != lower(q.name) || lower(p.resource_group_name) != lower(q.resource_group_name)
      ]
    ]))
    error_message = "service plan names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : length(trimspace(p.name)) > 0 && length(trimspace(p.resource_group_name)) > 0 && length(trimspace(p.location)) > 0 && length(trimspace(p.sku_name)) > 0 && length(trimspace(p.os_type)) > 0
    ])
    error_message = "name, resource_group_name, location, sku_name and os_type must not be empty or whitespace."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : contains(["Windows", "Linux", "WindowsContainer"], p.os_type)
    ])
    error_message = "os_type must be one of Windows, Linux or WindowsContainer (case-sensitive) — the OS is immutable and tied to the SKU pricing family."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : p.worker_count == null || p.worker_count >= 1
    ])
    error_message = "worker_count, when set, must be at least 1."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : p.premium_plan_auto_scale_enabled != true || (can(regex("^P[0-9]", p.sku_name)) && p.worker_count == null)
    ])
    error_message = "premium_plan_auto_scale_enabled requires a Premium SKU (P0v3, P1v3, ... P5mv4 — the sku_name must start with \"P\" followed by a digit) and a worker_count left for the autoscaler to manage."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : p.maximum_elastic_worker_count == null || can(regex("^EP[0-9]", p.sku_name)) || p.premium_plan_auto_scale_enabled == true
    ])
    error_message = "maximum_elastic_worker_count applies to Elastic Premium plans (EP1, EP2, EP3 in sku_name) or Premium plans with premium_plan_auto_scale_enabled."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : !p.zone_balancing_enabled || p.worker_count == null || p.worker_count > 1
    ])
    error_message = "zone_balancing_enabled spreads the plan across zones and therefore needs more than one worker — set worker_count to 2+ (or leave it to the autoscaler)."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : p.app_service_environment_id == null || (can(regex("^I[0-9]", p.sku_name)) && can(regex("^/", p.app_service_environment_id)))
    ])
    error_message = "app_service_environment_id requires an Isolated SKU (I1v2, I2v2, I3v2 or I1mv2 — the sku_name must start with \"I\" followed by a digit) and a full ARM resource ID (starts with \"/\")."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : length(p.tags) <= 50 && alltrue([for k, v in p.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "linux_function_apps" {
  description = "Map of Linux function apps keyed by an arbitrary identifier. Each entry creates one azurerm_linux_function_app bound to a service plan via service_plan_key (in-module) or service_plan_id (external). App names should stay within 32 characters — they own the <name>.azurewebsites.net default hostname and double as the functions host ID."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    service_plan_key = optional(string)
    service_plan_id  = optional(string)

    storage_account_name          = string
    storage_account_access_key    = optional(string)
    storage_uses_managed_identity = optional(bool)

    app_settings = optional(map(string), {})
    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})

    functions_extension_version = optional(string)
    zip_deploy_file             = optional(string)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    virtual_network_subnet_id                      = optional(string)
    https_only                                     = optional(bool, false)
    public_network_access_enabled                  = optional(bool, true)
    enabled                                        = optional(bool, true)
    end_to_end_tls_encryption_enabled              = optional(bool, false)
    daily_memory_time_quota                        = optional(number)
    builtin_logging_enabled                        = optional(bool)
    content_share_force_disabled                   = optional(bool)
    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    site_config = object({
      always_on                              = optional(bool, false)
      app_command_line                       = optional(string)
      app_scale_limit                        = optional(number)
      worker_count                           = optional(number)
      use_32_bit_worker                      = optional(bool)
      websockets_enabled                     = optional(bool)
      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      application_stack = optional(object({
        docker_registry_url         = optional(string)
        image_name                  = optional(string)
        image_tag                   = optional(string)
        registry_username           = optional(string)
        registry_password           = optional(string)
        dotnet_version              = optional(string)
        use_dotnet_isolated_runtime = optional(bool)
        java_version                = optional(string)
        node_version                = optional(string)
        python_version              = optional(string)
        powershell_core_version     = optional(string)
        use_custom_runtime          = optional(bool)
      }))
      container_registry_use_managed_identity       = optional(bool)
      container_registry_managed_identity_client_id = optional(string)
      cors = optional(object({
        allowed_origins     = list(string)
        support_credentials = optional(bool, false)
      }))
      ftps_state                        = optional(string, "Disabled")
      http2_enabled                     = optional(bool)
      minimum_tls_version               = optional(string, "1.2")
      scm_minimum_tls_version           = optional(string, "1.2")
      health_check_path                 = optional(string)
      health_check_eviction_time_in_min = optional(number)
      pre_warmed_instance_count         = optional(number)
      elastic_instance_minimum          = optional(number)
      runtime_scale_monitoring_enabled  = optional(bool)
      vnet_route_all_enabled            = optional(bool)
      ip_restriction = optional(map(object({
        name                      = string
        action                    = optional(string, "Allow")
        priority                  = optional(number)
        ip_address                = optional(string)
        service_tag               = optional(string)
        virtual_network_subnet_id = optional(string)
        description               = optional(string)
      })), {})
      ip_restriction_default_action = optional(string)
      scm_ip_restriction = optional(map(object({
        name                      = string
        action                    = optional(string, "Allow")
        priority                  = optional(number)
        ip_address                = optional(string)
        service_tag               = optional(string)
        virtual_network_subnet_id = optional(string)
        description               = optional(string)
      })), {})
      scm_ip_restriction_default_action = optional(string)
    })

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.linux_function_apps) : !can(regex("\\.", key))
    ])
    error_message = "linux_function_apps map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.linux_function_apps : alltrue([
        for cs_key in keys(app.connection_strings) : !can(regex("\\.", cs_key))
      ])
    ])
    error_message = "connection_strings map keys (they double as the connection string name) must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.linux_function_apps : alltrue([
        for ipr_key in concat(keys(app.site_config.ip_restriction), keys(app.site_config.scm_ip_restriction)) : !can(regex("\\.", ipr_key))
      ])
    ])
    error_message = "site_config ip_restriction and scm_ip_restriction map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : length(app.name) >= 1 && length(app.name) <= 60 && can(regex("^[0-9a-zA-Z-]+$", app.name))
    ])
    error_message = "function app name must be 1-60 letters, digits or hyphens (provider-validated format) — prefer 32 characters or fewer: the app name doubles as the functions host ID and longer names are prone to host-ID collisions (docs recommendation)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : length(trimspace(app.name)) > 0 && length(trimspace(app.resource_group_name)) > 0 && length(trimspace(app.location)) > 0 && length(trimspace(app.storage_account_name)) > 0
    ])
    error_message = "name, resource_group_name, location and storage_account_name must not be empty or whitespace."
  }

  validation {
    condition = alltrue(concat(
      flatten([
        for key, app in var.linux_function_apps : [
          for other_key, other in var.linux_function_apps : [key == other_key || lower(app.name) != lower(other.name)]
        ]
      ]),
      flatten([
        for name in [for key, app in var.linux_function_apps : lower(app.name)] : [
          for other in [for key, app in var.windows_function_apps : lower(app.name)] : [name != other]
        ]
      ])
    ))
    error_message = "function app names must be unique case-insensitively, both within the module's Linux apps and against its Windows apps — apps are globally unique in Azure (each owns a default hostname)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : !(app.service_plan_key != null && app.service_plan_id != null)
    ])
    error_message = "a function app takes at most one plan pass-through: set service_plan_key (an existing service_plans map key for an in-module plan) or service_plan_id (a full ARM resource ID), never both — exactly one of the two."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : (app.service_plan_key != null || app.service_plan_id != null) && (app.service_plan_id == null || can(regex("^/", app.service_plan_id)))
    ])
    error_message = "a function app requires exactly one plan: set service_plan_key or service_plan_id, the resource ID form must start with \"/\"."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.service_plan_key == null || contains(keys(var.service_plans), app.service_plan_key)
    ])
    error_message = "linux_function_apps service_plan_key must reference an existing service_plans map key — apps bind to azurerm_service_plan resources by key."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.service_plan_key == null || var.service_plans[app.service_plan_key].os_type == "Linux"
    ])
    error_message = "Linux function apps must bind to a plan with os_type \"Linux\" — Linux and Windows apps are separate resources and cannot share a plan."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.service_plan_key == null || lower(var.service_plans[app.service_plan_key].location) == lower(app.location)
    ])
    error_message = "function apps must live in the referenced plan's region — match the app's location to the plan (case-insensitively)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.service_plan_key == null || !contains(["Y1", "Dynamic"], var.service_plans[app.service_plan_key].sku_name) || app.site_config.always_on != true
    ])
    error_message = "always_on is not supported on Consumption plans (sku_name Y1/Dynamic) — leave site_config.always_on unset or false, or move to a Premium/Dedicated plan."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : (app.storage_account_access_key != null) != (app.storage_uses_managed_identity == true)
    ])
    error_message = "exactly one storage auth path: set storage_account_access_key or storage_uses_managed_identity = true — the provider marks the two conflicting."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.storage_uses_managed_identity != true || app.identity != null
    ])
    error_message = "storage_uses_managed_identity requires an identity block on the app — the identity is what reaches the storage account."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.zip_deploy_file == null || app.webdeploy_publish_basic_authentication_enabled != false
    ])
    error_message = "zip_deploy_file relies on the default publishing profile: leave webdeploy_publish_basic_authentication_enabled unset or true."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : alltrue([
        for key, value in app.app_settings :
        key == "FUNCTIONS_WORKER_RUNTIME" ? app.site_config.application_stack == null : true
      ])
    ])
    error_message = "app_settings must not carry FUNCTIONS_WORKER_RUNTIME when site_config.application_stack is set — the runtime marker belongs to the application stack."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.identity == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], app.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned or \"SystemAssigned, UserAssigned\" (exact casing)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.identity == null || app.identity.type == "SystemAssigned" || length(app.identity.identity_ids) > 0
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — fill it with managed identity resource IDs."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.virtual_network_subnet_id == null || can(regex("^/", app.virtual_network_subnet_id))
    ])
    error_message = "virtual_network_subnet_id, when set, must be a full ARM resource ID (starts with \"/\") of a dedicated subnet for regional VNET integration."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.key_vault_reference_identity_id == null || app.identity != null
    ])
    error_message = "key_vault_reference_identity_id requires an identity block on the app — the referenced user-assigned identity must be assigned to the app first."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : app.daily_memory_time_quota == null || app.daily_memory_time_quota >= 0
    ])
    error_message = "daily_memory_time_quota, when set, must be >= 0 (gigabyte-seconds; meaningful on Consumption plans only)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_function_apps : [
        contains(["AllAllowed", "FtpsOnly", "Disabled"], app.site_config.ftps_state)
      ]
    ]))
    error_message = "site_config ftps_state must be one of AllAllowed, FtpsOnly or Disabled (case-sensitive). The provider defaults this to Disabled where Azure's own default is AllAllowed — set it explicitly for the posture you want."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_function_apps : [
        contains(["Allow", "Deny"], app.site_config.ip_restriction_default_action == null ? "Allow" : app.site_config.ip_restriction_default_action),
        contains(["Allow", "Deny"], app.site_config.scm_ip_restriction_default_action == null ? "Allow" : app.site_config.scm_ip_restriction_default_action)
      ]
    ]))
    error_message = "site_config ip_restriction_default_action and scm_ip_restriction_default_action, when set, must be Allow or Deny (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_function_apps : flatten([
        for ipr in concat(values(app.site_config.ip_restriction), values(app.site_config.scm_ip_restriction)) : [
          contains(["Allow", "Deny"], ipr.action),
          (ipr.ip_address != null ? 1 : 0) + (ipr.service_tag != null ? 1 : 0) + (ipr.virtual_network_subnet_id != null ? 1 : 0) == 1,
          ipr.virtual_network_subnet_id == null || can(regex("^/", ipr.virtual_network_subnet_id))
        ]
      ])
    ]))
    error_message = "each ip_restriction / scm_ip_restriction entry needs exactly one source — ip_address, service_tag or virtual_network_subnet_id, never several — with action Allow or Deny and subnet references as full ARM resource IDs."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_function_apps : [
        app.site_config.minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.minimum_tls_version),
        app.site_config.scm_minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.scm_minimum_tls_version)
      ]
    ]))
    error_message = "site_config minimum_tls_version and scm_minimum_tls_version, when set, must be one of 1.0, 1.1, 1.2 or 1.3."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_function_apps : [
        app.site_config.health_check_eviction_time_in_min == null || length(app.site_config.health_check_path == null ? "" : app.site_config.health_check_path) > 0,
        app.site_config.health_check_eviction_time_in_min == null || (app.site_config.health_check_eviction_time_in_min >= 2 && app.site_config.health_check_eviction_time_in_min <= 10)
      ]
    ]))
    error_message = "site_config health_check_eviction_time_in_min requires a health_check_path and must be between 2 and 10 minutes."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_function_apps : [
        app.site_config.runtime_scale_monitoring_enabled != true || (app.site_config.pre_warmed_instance_count != null && app.site_config.pre_warmed_instance_count >= 1)
      ]
    ]))
    error_message = "site_config runtime_scale_monitoring_enabled requires pre_warmed_instance_count >= 1 and applies to Elastic Premium apps only."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_function_apps : flatten([
        for stack in app.site_config.application_stack != null ? [app.site_config.application_stack] : [] : [
          length(compact([stack.docker_registry_url, stack.image_name])) == 0 || (stack.docker_registry_url != null && stack.image_name != null),
          (stack.registry_username != null) == (stack.registry_password != null),
          length(compact([stack.image_name, stack.dotnet_version, stack.java_version, stack.node_version, stack.python_version, stack.powershell_core_version])) <= 1,
          stack.use_custom_runtime != true || length(compact([stack.image_name, stack.dotnet_version, stack.java_version, stack.node_version, stack.python_version, stack.powershell_core_version])) == 0
        ]
      ])
    ]))
    error_message = "site_config application_stack: a custom image requires both docker_registry_url and image_name, registry_username and registry_password come as a pair (or set container_registry_use_managed_identity and leave both out), at most one language stack may be set per app and use_custom_runtime excludes all explicit stacks — one runtime marker, not several."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_function_apps : flatten([
        for cs in app.connection_strings : contains(["APIHub", "Custom", "DocDb", "EventHub", "MySQL", "NotificationHub", "PostgreSQL", "RedisCache", "ServiceBus", "SQLAzure", "SQLServer"], cs.type)
      ])
    ]))
    error_message = "connection_strings type must be one of the documented values: APIHub, Custom, DocDb, EventHub, MySQL, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure or SQLServer (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_function_apps : length(app.tags) <= 50 && alltrue([for k, v in app.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "windows_function_apps" {
  description = "Map of Windows function apps keyed by an arbitrary identifier. Each entry creates one azurerm_windows_function_app bound to a service plan via service_plan_key (in-module) or service_plan_id (external). App names should stay within 32 characters — they own the <name>.azurewebsites.net default hostname and double as the functions host ID."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    service_plan_key = optional(string)
    service_plan_id  = optional(string)

    storage_account_name          = string
    storage_account_access_key    = optional(string)
    storage_uses_managed_identity = optional(bool)

    app_settings = optional(map(string), {})
    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})

    functions_extension_version = optional(string)
    zip_deploy_file             = optional(string)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    virtual_network_subnet_id                      = optional(string)
    https_only                                     = optional(bool, false)
    public_network_access_enabled                  = optional(bool, true)
    enabled                                        = optional(bool, true)
    end_to_end_tls_encryption_enabled              = optional(bool, false)
    daily_memory_time_quota                        = optional(number)
    builtin_logging_enabled                        = optional(bool)
    content_share_force_disabled                   = optional(bool)
    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    site_config = object({
      always_on                              = optional(bool, false)
      app_command_line                       = optional(string)
      app_scale_limit                        = optional(number)
      worker_count                           = optional(number)
      use_32_bit_worker                      = optional(bool)
      websockets_enabled                     = optional(bool)
      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      application_stack = optional(object({
        dotnet_version              = optional(string)
        use_dotnet_isolated_runtime = optional(bool)
        java_version                = optional(string)
        node_version                = optional(string)
        powershell_core_version     = optional(string)
        use_custom_runtime          = optional(bool)
      }))
      cors = optional(object({
        allowed_origins     = list(string)
        support_credentials = optional(bool, false)
      }))
      ftps_state                        = optional(string, "Disabled")
      http2_enabled                     = optional(bool)
      minimum_tls_version               = optional(string, "1.2")
      scm_minimum_tls_version           = optional(string, "1.2")
      health_check_path                 = optional(string)
      health_check_eviction_time_in_min = optional(number)
      pre_warmed_instance_count         = optional(number)
      elastic_instance_minimum          = optional(number)
      runtime_scale_monitoring_enabled  = optional(bool)
      vnet_route_all_enabled            = optional(bool)
      ip_restriction = optional(map(object({
        name                      = string
        action                    = optional(string, "Allow")
        priority                  = optional(number)
        ip_address                = optional(string)
        service_tag               = optional(string)
        virtual_network_subnet_id = optional(string)
        description               = optional(string)
      })), {})
      ip_restriction_default_action = optional(string)
      scm_ip_restriction = optional(map(object({
        name                      = string
        action                    = optional(string, "Allow")
        priority                  = optional(number)
        ip_address                = optional(string)
        service_tag               = optional(string)
        virtual_network_subnet_id = optional(string)
        description               = optional(string)
      })), {})
      scm_ip_restriction_default_action = optional(string)
    })

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.windows_function_apps) : !can(regex("\\.", key))
    ])
    error_message = "windows_function_apps map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.windows_function_apps : alltrue([
        for cs_key in keys(app.connection_strings) : !can(regex("\\.", cs_key))
      ])
    ])
    error_message = "connection_strings map keys (they double as the connection string name) must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.windows_function_apps : alltrue([
        for ipr_key in concat(keys(app.site_config.ip_restriction), keys(app.site_config.scm_ip_restriction)) : !can(regex("\\.", ipr_key))
      ])
    ])
    error_message = "site_config ip_restriction and scm_ip_restriction map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : length(app.name) >= 1 && length(app.name) <= 60 && can(regex("^[0-9a-zA-Z-]+$", app.name))
    ])
    error_message = "function app name must be 1-60 letters, digits or hyphens (provider-validated format) — prefer 32 characters or fewer: the app name doubles as the functions host ID and longer names are prone to host-ID collisions (docs recommendation)."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : length(trimspace(app.name)) > 0 && length(trimspace(app.resource_group_name)) > 0 && length(trimspace(app.location)) > 0 && length(trimspace(app.storage_account_name)) > 0
    ])
    error_message = "name, resource_group_name, location and storage_account_name must not be empty or whitespace."
  }

  validation {
    condition = alltrue(flatten([
      for key, app in var.windows_function_apps : [
        for other_key, other in var.windows_function_apps : [key == other_key || lower(app.name) != lower(other.name)]
      ]
    ]))
    error_message = "windows function app names must be unique within the module's windows_function_apps map, case-insensitively — the Linux variable checks the cross-family uniqueness (apps are globally unique in Azure, each owns a default hostname)."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : !(app.service_plan_key != null && app.service_plan_id != null)
    ])
    error_message = "a function app takes at most one plan pass-through: set service_plan_key (an existing service_plans map key for an in-module plan) or service_plan_id (a full ARM resource ID), never both — exactly one of the two."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : (app.service_plan_key != null || app.service_plan_id != null) && (app.service_plan_id == null || can(regex("^/", app.service_plan_id)))
    ])
    error_message = "a function app requires exactly one plan: set service_plan_key or service_plan_id, the resource ID form must start with \"/\"."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.service_plan_key == null || contains(keys(var.service_plans), app.service_plan_key)
    ])
    error_message = "windows_function_apps service_plan_key must reference an existing service_plans map key — apps bind to azurerm_service_plan resources by key."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.service_plan_key == null || var.service_plans[app.service_plan_key].os_type == "Windows"
    ])
    error_message = "Windows function apps must bind to a plan with os_type \"Windows\" — Linux and Windows apps are separate resources and cannot share a plan."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.service_plan_key == null || lower(var.service_plans[app.service_plan_key].location) == lower(app.location)
    ])
    error_message = "function apps must live in the referenced plan's region — match the app's location to the plan (case-insensitively)."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.service_plan_key == null || !contains(["Y1", "Dynamic"], var.service_plans[app.service_plan_key].sku_name) || app.site_config.always_on != true
    ])
    error_message = "always_on is not supported on Consumption plans (sku_name Y1/Dynamic) — leave site_config.always_on unset or false, or move to a Premium/Dedicated plan."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : (app.storage_account_access_key != null) != (app.storage_uses_managed_identity == true)
    ])
    error_message = "exactly one storage auth path: set storage_account_access_key or storage_uses_managed_identity = true — the provider marks the two conflicting."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.storage_uses_managed_identity != true || app.identity != null
    ])
    error_message = "storage_uses_managed_identity requires an identity block on the app — the identity is what reaches the storage account."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.zip_deploy_file == null || app.webdeploy_publish_basic_authentication_enabled != false
    ])
    error_message = "zip_deploy_file relies on the default publishing profile: leave webdeploy_publish_basic_authentication_enabled unset or true."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : alltrue([
        for key, value in app.app_settings :
        key == "FUNCTIONS_WORKER_RUNTIME" ? app.site_config.application_stack == null : true
      ])
    ])
    error_message = "app_settings must not carry FUNCTIONS_WORKER_RUNTIME when site_config.application_stack is set — the runtime marker belongs to the application stack."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.identity == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], app.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned or \"SystemAssigned, UserAssigned\" (exact casing)."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.identity == null || app.identity.type == "SystemAssigned" || length(app.identity.identity_ids) > 0
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — fill it with managed identity resource IDs."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.virtual_network_subnet_id == null || can(regex("^/", app.virtual_network_subnet_id))
    ])
    error_message = "virtual_network_subnet_id, when set, must be a full ARM resource ID (starts with \"/\") of a dedicated subnet for regional VNET integration."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.key_vault_reference_identity_id == null || app.identity != null
    ])
    error_message = "key_vault_reference_identity_id requires an identity block on the app — the referenced user-assigned identity must be assigned to the app first."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : app.daily_memory_time_quota == null || app.daily_memory_time_quota >= 0
    ])
    error_message = "daily_memory_time_quota, when set, must be >= 0 (gigabyte-seconds; meaningful on Consumption plans only)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_function_apps : [
        contains(["AllAllowed", "FtpsOnly", "Disabled"], app.site_config.ftps_state)
      ]
    ]))
    error_message = "site_config ftps_state must be one of AllAllowed, FtpsOnly or Disabled (case-sensitive). The provider defaults this to Disabled where Azure's own default is AllAllowed — set it explicitly for the posture you want."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_function_apps : [
        contains(["Allow", "Deny"], app.site_config.ip_restriction_default_action == null ? "Allow" : app.site_config.ip_restriction_default_action),
        contains(["Allow", "Deny"], app.site_config.scm_ip_restriction_default_action == null ? "Allow" : app.site_config.scm_ip_restriction_default_action)
      ]
    ]))
    error_message = "site_config ip_restriction_default_action and scm_ip_restriction_default_action, when set, must be Allow or Deny (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_function_apps : flatten([
        for ipr in concat(values(app.site_config.ip_restriction), values(app.site_config.scm_ip_restriction)) : [
          contains(["Allow", "Deny"], ipr.action),
          (ipr.ip_address != null ? 1 : 0) + (ipr.service_tag != null ? 1 : 0) + (ipr.virtual_network_subnet_id != null ? 1 : 0) == 1,
          ipr.virtual_network_subnet_id == null || can(regex("^/", ipr.virtual_network_subnet_id))
        ]
      ])
    ]))
    error_message = "each ip_restriction / scm_ip_restriction entry needs exactly one source — ip_address, service_tag or virtual_network_subnet_id, never several — with action Allow or Deny and subnet references as full ARM resource IDs."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_function_apps : [
        app.site_config.minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.minimum_tls_version),
        app.site_config.scm_minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.scm_minimum_tls_version)
      ]
    ]))
    error_message = "site_config minimum_tls_version and scm_minimum_tls_version, when set, must be one of 1.0, 1.1, 1.2 or 1.3."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_function_apps : [
        app.site_config.health_check_eviction_time_in_min == null || length(app.site_config.health_check_path == null ? "" : app.site_config.health_check_path) > 0,
        app.site_config.health_check_eviction_time_in_min == null || (app.site_config.health_check_eviction_time_in_min >= 2 && app.site_config.health_check_eviction_time_in_min <= 10)
      ]
    ]))
    error_message = "site_config health_check_eviction_time_in_min requires a health_check_path and must be between 2 and 10 minutes."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_function_apps : [
        app.site_config.runtime_scale_monitoring_enabled != true || (app.site_config.pre_warmed_instance_count != null && app.site_config.pre_warmed_instance_count >= 1)
      ]
    ]))
    error_message = "site_config runtime_scale_monitoring_enabled requires pre_warmed_instance_count >= 1 and applies to Elastic Premium apps only."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_function_apps : flatten([
        for stack in app.site_config.application_stack != null ? [app.site_config.application_stack] : [] : [
          stack.dotnet_version == null || can(regex("^v", stack.dotnet_version)),
          length(compact([stack.dotnet_version, stack.java_version, stack.node_version, stack.powershell_core_version])) <= 1,
          stack.use_custom_runtime != true || length(compact([stack.dotnet_version, stack.java_version, stack.node_version, stack.powershell_core_version])) == 0
        ]
      ])
    ]))
    error_message = "site_config application_stack: dotnet_version uses the \"v\"-prefixed form on Windows apps (v4.0, v6.0, ...), at most one language stack may be set per app and use_custom_runtime excludes all explicit stacks — one runtime marker, not several."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_function_apps : flatten([
        for cs in app.connection_strings : contains(["APIHub", "Custom", "DocDb", "EventHub", "MySQL", "NotificationHub", "PostgreSQL", "RedisCache", "ServiceBus", "SQLAzure", "SQLServer"], cs.type)
      ])
    ]))
    error_message = "connection_strings type must be one of the documented values: APIHub, Custom, DocDb, EventHub, MySQL, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure or SQLServer (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for app in var.windows_function_apps : length(app.tags) <= 50 && alltrue([for k, v in app.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
