variable "service_plans" {
  description = "Map of App Service Plans keyed by an arbitrary identifier. Apps (Linux and Windows web apps and their slots) bind to plans via service_plan_key."
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
      for p in var.service_plans : p.app_service_environment_id == null || (can(regex("^/", p.app_service_environment_id)) && can(regex("^I[0-9]", p.sku_name)))
    ])
    error_message = "app_service_environment_id, when set, must be a full ARM resource ID of the App Service Environment and sku_name must be an Isolated SKU (I1..I3, I1v2..I3v2 — the sku_name must start with \"I\" followed by a digit)."
  }

  validation {
    condition = alltrue([
      for p in var.service_plans : length(p.tags) <= 50 && alltrue([for k, v in p.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "linux_web_apps" {
  description = "Map of Linux web apps keyed by an arbitrary identifier. Each entry creates one azurerm_linux_web_app bound to a service plan via service_plan_key (in-module) or service_plan_id (external). App names are globally unique across Azure — they own the <name>.azurewebsites.net default hostname."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    service_plan_key = optional(string)
    service_plan_id  = optional(string)

    app_settings = optional(map(string), {})
    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    virtual_network_subnet_id          = optional(string)
    https_only                         = optional(bool, false)
    public_network_access_enabled      = optional(bool, true)
    client_affinity_enabled            = optional(bool, false)
    client_certificate_enabled         = optional(bool, false)
    client_certificate_mode            = optional(string)
    client_certificate_exclusion_paths = optional(string)
    enabled                            = optional(bool, true)
    end_to_end_tls_encryption_enabled  = optional(bool, false)

    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    site_config = object({
      always_on             = optional(bool, true)
      api_definition_url    = optional(string)
      api_management_api_id = optional(string)
      app_command_line      = optional(string)
      application_stack = optional(object({
        docker_image_name        = optional(string)
        docker_registry_url      = optional(string)
        docker_registry_username = optional(string)
        docker_registry_password = optional(string)
        dotnet_version           = optional(string)
        go_version               = optional(string)
        java_server              = optional(string)
        java_server_version      = optional(string)
        java_version             = optional(string)
        node_version             = optional(string)
        php_version              = optional(string)
        python_version           = optional(string)
      }))
      container_registry_use_managed_identity       = optional(bool)
      container_registry_managed_identity_client_id = optional(string)
      cors = optional(object({
        allowed_origins     = list(string)
        support_credentials = optional(bool, false)
      }))
      default_documents                 = optional(list(string), [])
      ftps_state                        = optional(string, "Disabled")
      health_check_path                 = optional(string)
      health_check_eviction_time_in_min = optional(number)
      http2_enabled                     = optional(bool)
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
      load_balancing_mode               = optional(string)
      local_mysql_enabled               = optional(bool)
      minimum_tls_version               = optional(string, "1.2")
      scm_minimum_tls_version           = optional(string, "1.2")
      remote_debugging_enabled          = optional(bool)
      remote_debugging_version          = optional(string)
      scm_use_main_ip_restriction       = optional(bool)
      use_32_bit_worker                 = optional(bool)
      vnet_route_all_enabled            = optional(bool)
      websockets_enabled                = optional(bool)
      worker_count                      = optional(number)
    })

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.linux_web_apps) : !can(regex("\\.", key))
    ])
    error_message = "linux_web_apps map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.linux_web_apps : alltrue([
        for cs_key in keys(app.connection_strings) : !can(regex("\\.", cs_key))
      ])
    ])
    error_message = "connection_strings map keys (they double as the connection string name) must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.linux_web_apps : alltrue([
        for ipr_key in concat(keys(app.site_config.ip_restriction), keys(app.site_config.scm_ip_restriction)) : !can(regex("\\.", ipr_key))
      ])
    ])
    error_message = "site_config ip_restriction and scm_ip_restriction map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : can(regex("^[0-9a-zA-Z-]{1,60}$", app.name))
    ])
    error_message = "web app name must be 1-60 letters, digits or hyphens (provider-validated format) — and it is globally unique across Azure: it owns the <name>.azurewebsites.net default hostname."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : length(trimspace(app.name)) > 0 && length(trimspace(app.resource_group_name)) > 0 && length(trimspace(app.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue(concat(
      flatten([
        for key, app in var.linux_web_apps : [
          for other_key, other in var.linux_web_apps : [key == other_key || lower(app.name) != lower(other.name)]
        ]
      ]),
      flatten([
        for name in [for key, app in var.linux_web_apps : lower(app.name)] : [
          for other in [for key, app in var.windows_web_apps : lower(app.name)] : [name != other]
        ]
      ])
    ))
    error_message = "web app names must be unique case-insensitively, both within the module's Linux apps and against its Windows apps — apps are globally unique in Azure (each owns a default hostname)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : !(app.service_plan_key != null && app.service_plan_id != null)
    ])
    error_message = "a web app takes at most one plan pass-through: set service_plan_key (an existing service_plans map key for an in-module plan) or service_plan_id (a full ARM resource ID), never both — exactly one of the two."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : (app.service_plan_key != null || app.service_plan_id != null) && (app.service_plan_id == null || can(regex("^/", app.service_plan_id)))
    ])
    error_message = "a web app requires exactly one plan: set service_plan_key or service_plan_id, the resource ID form must start with \"/\"."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.service_plan_key == null || contains(keys(var.service_plans), app.service_plan_key)
    ])
    error_message = "linux_web_apps service_plan_key must reference an existing service_plans map key — apps bind to azurerm_service_plan resources by key."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.service_plan_key == null || var.service_plans[app.service_plan_key].os_type == "Linux"
    ])
    error_message = "Linux web apps must bind to a plan with os_type \"Linux\" — Linux and Windows apps are separate resources and cannot share a plan."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.service_plan_key == null || lower(var.service_plans[app.service_plan_key].location) == lower(app.location)
    ])
    error_message = "web apps must live in the referenced plan's region — match the app's location to the plan (case-insensitively)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.service_plan_key == null || !contains(["F1", "D1", "SHARED"], var.service_plans[app.service_plan_key].sku_name) || app.site_config.always_on != true
    ])
    error_message = "always_on is not available on Free/Shared SKUs (F1, D1, SHARED) — set site_config.always_on = false or pick a paid tier."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.identity == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], app.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned or \"SystemAssigned, UserAssigned\" (exact casing)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.identity == null || app.identity.type == "SystemAssigned" || length(app.identity.identity_ids) > 0
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — fill it with managed identity resource IDs."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.virtual_network_subnet_id == null || can(regex("^/", app.virtual_network_subnet_id))
    ])
    error_message = "virtual_network_subnet_id, when set, must be a full ARM resource ID (starts with \"/\") of a dedicated subnet for VNET integration."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.client_certificate_mode == null || app.client_certificate_enabled == true
    ])
    error_message = "client_certificate_mode applies only when client_certificate_enabled is true."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : app.client_certificate_mode == null || contains(["Required", "Optional", "OptionalInteractiveUser"], app.client_certificate_mode)
    ])
    error_message = "client_certificate_mode must be one of Required, Optional or OptionalInteractiveUser (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_apps : [
        for cs in app.connection_strings : contains(["APIHub", "Custom", "DocDb", "EventHub", "MySql", "NotificationHub", "PostgreSQL", "RedisCache", "ServiceBus", "SQLAzure", "SQLServer"], cs.type)
      ]
    ]))
    error_message = "connection_strings type must be one of the documented values: APIHub, Custom, DocDb, EventHub, MySql, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure or SQLServer (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_apps : [
        app.site_config.health_check_eviction_time_in_min == null || length(app.site_config.health_check_path == null ? "" : app.site_config.health_check_path) > 0,
        app.site_config.health_check_eviction_time_in_min == null || (app.site_config.health_check_eviction_time_in_min >= 2 && app.site_config.health_check_eviction_time_in_min <= 10)
      ]
    ]))
    error_message = "site_config health_check_eviction_time_in_min requires a health_check_path and must be between 2 and 10 minutes."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_apps : [
        contains(["AllAllowed", "FtpsOnly", "Disabled"], app.site_config.ftps_state)
      ]
    ]))
    error_message = "site_config ftps_state must be one of AllAllowed, FtpsOnly or Disabled (case-sensitive). The provider defaults this to Disabled where Azure's own default is AllAllowed — set it explicitly for the posture you want."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_apps : [
        contains(["Allow", "Deny"], app.site_config.ip_restriction_default_action == null ? "Allow" : app.site_config.ip_restriction_default_action),
        contains(["Allow", "Deny"], app.site_config.scm_ip_restriction_default_action == null ? "Allow" : app.site_config.scm_ip_restriction_default_action)
      ]
    ]))
    error_message = "site_config ip_restriction_default_action and scm_ip_restriction_default_action, when set, must be Allow or Deny (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_apps : flatten([
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
      for app in var.linux_web_apps : [
        app.site_config.minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.minimum_tls_version),
        app.site_config.scm_minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.scm_minimum_tls_version)
      ]
    ]))
    error_message = "site_config minimum_tls_version and scm_minimum_tls_version, when set, must be one of 1.0, 1.1, 1.2 or 1.3."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_apps : [
        app.site_config.remote_debugging_version == null || contains(["VS2017", "VS2019", "VS2022"], app.site_config.remote_debugging_version)
      ]
    ]))
    error_message = "site_config remote_debugging_version must be one of VS2017, VS2019 or VS2022 (case-sensitive) and pairs with remote_debugging_enabled."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_apps : flatten([
        for stack in app.site_config.application_stack != null ? [app.site_config.application_stack] : [] : [
          stack.docker_image_name == null || stack.docker_registry_url != null,
          (stack.java_server != null) == (stack.java_version != null) && (stack.java_server != null) == (stack.java_server_version != null),
          length(compact([stack.docker_image_name, stack.dotnet_version, stack.go_version, stack.java_server, stack.node_version, stack.php_version, stack.python_version])) <= 1
        ]
      ])
    ]))
    error_message = "site_config application_stack: a docker image requires docker_registry_url; the Java trio (java_server, java_server_version, java_version) is all-or-none; and at most one language stack may be set per app — one image or one language version, not several."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_apps : length(app.tags) <= 50 && alltrue([for k, v in app.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
variable "windows_web_apps" {
  description = "Map of Windows web apps keyed by an arbitrary identifier. Each entry creates one azurerm_windows_web_app bound to a service plan via service_plan_key (in-module) or service_plan_id (external). App names are globally unique across Azure — they own the <name>.azurewebsites.net default hostname."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    service_plan_key = optional(string)
    service_plan_id  = optional(string)

    app_settings = optional(map(string), {})
    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    virtual_network_subnet_id          = optional(string)
    https_only                         = optional(bool, false)
    public_network_access_enabled      = optional(bool, true)
    client_affinity_enabled            = optional(bool, false)
    client_certificate_enabled         = optional(bool, false)
    client_certificate_mode            = optional(string)
    client_certificate_exclusion_paths = optional(string)
    enabled                            = optional(bool, true)
    end_to_end_tls_encryption_enabled  = optional(bool, false)

    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    site_config = object({
      always_on             = optional(bool, true)
      api_definition_url    = optional(string)
      api_management_api_id = optional(string)
      app_command_line      = optional(string)
      application_stack = optional(object({
        current_stack                = optional(string)
        dotnet_version               = optional(string)
        dotnet_core_version          = optional(string)
        tomcat_version               = optional(string)
        java_embedded_server_enabled = optional(bool)
        java_version                 = optional(string)
        node_version                 = optional(string)
        php_version                  = optional(string)
        python                       = optional(bool)
      }))
      cors = optional(object({
        allowed_origins     = list(string)
        support_credentials = optional(bool, false)
      }))
      default_documents                 = optional(list(string), [])
      ftps_state                        = optional(string, "Disabled")
      health_check_path                 = optional(string)
      health_check_eviction_time_in_min = optional(number)
      http2_enabled                     = optional(bool)
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
      load_balancing_mode               = optional(string)
      local_mysql_enabled               = optional(bool)
      minimum_tls_version               = optional(string, "1.2")
      scm_minimum_tls_version           = optional(string, "1.2")
      remote_debugging_enabled          = optional(bool)
      remote_debugging_version          = optional(string)
      scm_use_main_ip_restriction       = optional(bool)
      use_32_bit_worker                 = optional(bool)
      vnet_route_all_enabled            = optional(bool)
      websockets_enabled                = optional(bool)
      worker_count                      = optional(number)
    })

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.windows_web_apps) : !can(regex("\\.", key))
    ])
    error_message = "windows_web_apps map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.windows_web_apps : alltrue([
        for cs_key in keys(app.connection_strings) : !can(regex("\\.", cs_key))
      ])
    ])
    error_message = "connection_strings map keys (they double as the connection string name) must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.windows_web_apps : alltrue([
        for ipr_key in concat(keys(app.site_config.ip_restriction), keys(app.site_config.scm_ip_restriction)) : !can(regex("\\.", ipr_key))
      ])
    ])
    error_message = "site_config ip_restriction and scm_ip_restriction map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : can(regex("^[0-9a-zA-Z-]{1,60}$", app.name))
    ])
    error_message = "web app name must be 1-60 letters, digits or hyphens (provider-validated format) — and it is globally unique across Azure: it owns the <name>.azurewebsites.net default hostname."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : length(trimspace(app.name)) > 0 && length(trimspace(app.resource_group_name)) > 0 && length(trimspace(app.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue(flatten([
      for key, app in var.windows_web_apps : [
        for other_key, other in var.windows_web_apps : [key == other_key || lower(app.name) != lower(other.name)]
      ]
    ]))
    error_message = "windows web app names must be unique within the module's windows_web_apps map, case-insensitively — apps are globally unique in Azure (each owns a default hostname)."
  }


  validation {
    condition = alltrue([
      for app in var.windows_web_apps : !(app.service_plan_key != null && app.service_plan_id != null)
    ])
    error_message = "a web app takes at most one plan pass-through: set service_plan_key (an existing service_plans map key for an in-module plan) or service_plan_id (a full ARM resource ID), never both — exactly one of the two."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : (app.service_plan_key != null || app.service_plan_id != null) && (app.service_plan_id == null || can(regex("^/", app.service_plan_id)))
    ])
    error_message = "a web app requires exactly one plan: set service_plan_key or service_plan_id, the resource ID form must start with \"/\"."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.service_plan_key == null || contains(keys(var.service_plans), app.service_plan_key)
    ])
    error_message = "windows_web_apps service_plan_key must reference an existing service_plans map key — apps bind to azurerm_service_plan resources by key."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.service_plan_key == null || var.service_plans[app.service_plan_key].os_type == "Windows"
    ])
    error_message = "Windows web apps must bind to a plan with os_type \"Windows\" — Linux and Windows apps are separate resources and cannot share a plan."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.service_plan_key == null || lower(var.service_plans[app.service_plan_key].location) == lower(app.location)
    ])
    error_message = "web apps must live in the referenced plan's region — match the app's location to the plan (case-insensitively)."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.service_plan_key == null || !contains(["F1", "D1", "SHARED"], var.service_plans[app.service_plan_key].sku_name) || app.site_config.always_on != true
    ])
    error_message = "always_on is not available on Free/Shared SKUs (F1, D1, SHARED) — set site_config.always_on = false or pick a paid tier."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.identity == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], app.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned or \"SystemAssigned, UserAssigned\" (exact casing)."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.identity == null || app.identity.type == "SystemAssigned" || length(app.identity.identity_ids) > 0
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — fill it with managed identity resource IDs."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.virtual_network_subnet_id == null || can(regex("^/", app.virtual_network_subnet_id))
    ])
    error_message = "virtual_network_subnet_id, when set, must be a full ARM resource ID (starts with \"/\") of a dedicated subnet for VNET integration."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.client_certificate_mode == null || app.client_certificate_enabled == true
    ])
    error_message = "client_certificate_mode applies only when client_certificate_enabled is true."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : app.client_certificate_mode == null || contains(["Required", "Optional", "OptionalInteractiveUser"], app.client_certificate_mode)
    ])
    error_message = "client_certificate_mode must be one of Required, Optional or OptionalInteractiveUser (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_apps : [
        for cs in app.connection_strings : contains(["APIHub", "Custom", "DocDb", "EventHub", "MySql", "NotificationHub", "PostgreSQL", "RedisCache", "ServiceBus", "SQLAzure", "SQLServer"], cs.type)
      ]
    ]))
    error_message = "connection_strings type must be one of the documented values: APIHub, Custom, DocDb, EventHub, MySql, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure or SQLServer (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_apps : [
        app.site_config.health_check_eviction_time_in_min == null || length(app.site_config.health_check_path == null ? "" : app.site_config.health_check_path) > 0,
        app.site_config.health_check_eviction_time_in_min == null || (app.site_config.health_check_eviction_time_in_min >= 2 && app.site_config.health_check_eviction_time_in_min <= 10)
      ]
    ]))
    error_message = "site_config health_check_eviction_time_in_min requires a health_check_path and must be between 2 and 10 minutes."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_apps : [
        contains(["AllAllowed", "FtpsOnly", "Disabled"], app.site_config.ftps_state)
      ]
    ]))
    error_message = "site_config ftps_state must be one of AllAllowed, FtpsOnly or Disabled (case-sensitive). The provider defaults this to Disabled where Azure's own default is AllAllowed — set it explicitly for the posture you want."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_apps : [
        contains(["Allow", "Deny"], app.site_config.ip_restriction_default_action == null ? "Allow" : app.site_config.ip_restriction_default_action),
        contains(["Allow", "Deny"], app.site_config.scm_ip_restriction_default_action == null ? "Allow" : app.site_config.scm_ip_restriction_default_action)
      ]
    ]))
    error_message = "site_config ip_restriction_default_action and scm_ip_restriction_default_action, when set, must be Allow or Deny (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_apps : flatten([
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
      for app in var.windows_web_apps : [
        app.site_config.minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.minimum_tls_version),
        app.site_config.scm_minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.scm_minimum_tls_version)
      ]
    ]))
    error_message = "site_config minimum_tls_version and scm_minimum_tls_version, when set, must be one of 1.0, 1.1, 1.2 or 1.3."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_apps : [
        app.site_config.remote_debugging_version == null || contains(["VS2017", "VS2019", "VS2022"], app.site_config.remote_debugging_version)
      ]
    ]))
    error_message = "site_config remote_debugging_version must be one of VS2017, VS2019 or VS2022 (case-sensitive) and pairs with remote_debugging_enabled."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_apps : flatten([
        for stack in app.site_config.application_stack != null ? [app.site_config.application_stack] : [] : [
          length(compact([stack.current_stack, stack.dotnet_version, stack.dotnet_core_version, stack.tomcat_version, stack.java_version, stack.node_version, stack.php_version])) == 0 || stack.current_stack != null,
          stack.current_stack == null || contains(["dotnet", "dotnetcore", "node", "python", "php", "java"], stack.current_stack)
        ]
      ])
    ]))
    error_message = "site_config application_stack: current_stack (one of dotnet, dotnetcore, node, python, php or java, case-sensitive) is required when any version field is set — set current_stack first, then its version attribute."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_apps : length(app.tags) <= 50 && alltrue([for k, v in app.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
variable "linux_web_app_slots" {
  description = "Map of Linux deployment slots keyed by an arbitrary identifier; slot output keys compose as `<app_key>.<slot_key>`. Each entry creates one azurerm_linux_web_app_slot under the parent Linux web app via app_key, optionally overriding the parent's plan with service_plan_id."
  type = map(object({
    name    = string
    app_key = string

    service_plan_id = optional(string)

    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    virtual_network_subnet_id          = optional(string)
    https_only                         = optional(bool, false)
    public_network_access_enabled      = optional(bool, true)
    client_affinity_enabled            = optional(bool, false)
    client_certificate_enabled         = optional(bool, false)
    client_certificate_mode            = optional(string)
    client_certificate_exclusion_paths = optional(string)
    enabled                            = optional(bool, true)
    end_to_end_tls_encryption_enabled  = optional(bool, false)

    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    app_settings = optional(map(string), {})

    site_config = object({
      always_on             = optional(bool, true)
      api_definition_url    = optional(string)
      api_management_api_id = optional(string)
      app_command_line      = optional(string)
      application_stack = optional(object({
        docker_image_name        = optional(string)
        docker_registry_url      = optional(string)
        docker_registry_username = optional(string)
        docker_registry_password = optional(string)
        dotnet_version           = optional(string)
        go_version               = optional(string)
        java_server              = optional(string)
        java_server_version      = optional(string)
        java_version             = optional(string)
        node_version             = optional(string)
        php_version              = optional(string)
        python_version           = optional(string)
      }))
      container_registry_use_managed_identity       = optional(bool)
      container_registry_managed_identity_client_id = optional(string)
      cors = optional(object({
        allowed_origins     = list(string)
        support_credentials = optional(bool, false)
      }))
      default_documents                 = optional(list(string), [])
      ftps_state                        = optional(string, "Disabled")
      health_check_path                 = optional(string)
      health_check_eviction_time_in_min = optional(number)
      http2_enabled                     = optional(bool)
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
      load_balancing_mode               = optional(string)
      local_mysql_enabled               = optional(bool)
      minimum_tls_version               = optional(string, "1.2")
      scm_minimum_tls_version           = optional(string, "1.2")
      remote_debugging_enabled          = optional(bool)
      remote_debugging_version          = optional(string)
      scm_use_main_ip_restriction       = optional(bool)
      use_32_bit_worker                 = optional(bool)
      vnet_route_all_enabled            = optional(bool)
      websockets_enabled                = optional(bool)
      worker_count                      = optional(number)
      auto_swap_slot_name               = optional(string)
    })

    tags = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for key in keys(var.linux_web_app_slots) : !can(regex("\\.", key))
    ])
    error_message = "linux_web_app_slots map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.linux_web_app_slots : alltrue([
        for cs_key in keys(app.connection_strings) : !can(regex("\\.", cs_key))
      ])
    ])
    error_message = "connection_strings map keys (they double as the connection string name) must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.linux_web_app_slots : alltrue([
        for ipr_key in concat(keys(app.site_config.ip_restriction), keys(app.site_config.scm_ip_restriction)) : !can(regex("\\.", ipr_key))
      ])
    ])
    error_message = "site_config ip_restriction and scm_ip_restriction map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_app_slots : can(regex("^[0-9a-zA-Z-]{1,60}$", app.name))
    ])
    error_message = "slot name must be 1-60 letters, digits or hyphens (provider-validated format, same charset as app names) and is unique within its app."
  }

  validation {
    condition = alltrue([
      for slot in var.linux_web_app_slots : length(trimspace(slot.name)) > 0
    ])
    error_message = "slot name must not be empty or whitespace."
  }
  validation {
    condition = alltrue([
      for app in var.linux_web_app_slots : app.identity == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], app.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned or \"SystemAssigned, UserAssigned\" (exact casing)."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_app_slots : app.identity == null || app.identity.type == "SystemAssigned" || length(app.identity.identity_ids) > 0
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — fill it with managed identity resource IDs."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_app_slots : app.virtual_network_subnet_id == null || can(regex("^/", app.virtual_network_subnet_id))
    ])
    error_message = "virtual_network_subnet_id, when set, must be a full ARM resource ID (starts with \"/\") of a dedicated subnet for VNET integration."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_app_slots : app.client_certificate_mode == null || app.client_certificate_enabled == true
    ])
    error_message = "client_certificate_mode applies only when client_certificate_enabled is true."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_app_slots : app.client_certificate_mode == null || contains(["Required", "Optional", "OptionalInteractiveUser"], app.client_certificate_mode)
    ])
    error_message = "client_certificate_mode must be one of Required, Optional or OptionalInteractiveUser (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_app_slots : [
        for cs in app.connection_strings : contains(["APIHub", "Custom", "DocDb", "EventHub", "MySql", "NotificationHub", "PostgreSQL", "RedisCache", "ServiceBus", "SQLAzure", "SQLServer"], cs.type)
      ]
    ]))
    error_message = "connection_strings type must be one of the documented values: APIHub, Custom, DocDb, EventHub, MySql, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure or SQLServer (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_app_slots : [
        app.site_config.health_check_eviction_time_in_min == null || length(app.site_config.health_check_path == null ? "" : app.site_config.health_check_path) > 0,
        app.site_config.health_check_eviction_time_in_min == null || (app.site_config.health_check_eviction_time_in_min >= 2 && app.site_config.health_check_eviction_time_in_min <= 10)
      ]
    ]))
    error_message = "site_config health_check_eviction_time_in_min requires a health_check_path and must be between 2 and 10 minutes."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_app_slots : [
        contains(["AllAllowed", "FtpsOnly", "Disabled"], app.site_config.ftps_state)
      ]
    ]))
    error_message = "site_config ftps_state must be one of AllAllowed, FtpsOnly or Disabled (case-sensitive). The provider defaults this to Disabled where Azure's own default is AllAllowed — set it explicitly for the posture you want."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_app_slots : [
        contains(["Allow", "Deny"], app.site_config.ip_restriction_default_action == null ? "Allow" : app.site_config.ip_restriction_default_action),
        contains(["Allow", "Deny"], app.site_config.scm_ip_restriction_default_action == null ? "Allow" : app.site_config.scm_ip_restriction_default_action)
      ]
    ]))
    error_message = "site_config ip_restriction_default_action and scm_ip_restriction_default_action, when set, must be Allow or Deny (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_app_slots : flatten([
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
      for app in var.linux_web_app_slots : [
        app.site_config.minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.minimum_tls_version),
        app.site_config.scm_minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.scm_minimum_tls_version)
      ]
    ]))
    error_message = "site_config minimum_tls_version and scm_minimum_tls_version, when set, must be one of 1.0, 1.1, 1.2 or 1.3."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_app_slots : [
        app.site_config.remote_debugging_version == null || contains(["VS2017", "VS2019", "VS2022"], app.site_config.remote_debugging_version)
      ]
    ]))
    error_message = "site_config remote_debugging_version must be one of VS2017, VS2019 or VS2022 (case-sensitive) and pairs with remote_debugging_enabled."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.linux_web_app_slots : flatten([
        for stack in app.site_config.application_stack != null ? [app.site_config.application_stack] : [] : [
          stack.docker_image_name == null || stack.docker_registry_url != null,
          (stack.java_server != null) == (stack.java_version != null) && (stack.java_server != null) == (stack.java_server_version != null),
          length(compact([stack.docker_image_name, stack.dotnet_version, stack.go_version, stack.java_server, stack.node_version, stack.php_version, stack.python_version])) <= 1
        ]
      ])
    ]))
    error_message = "site_config application_stack: a docker image requires docker_registry_url; the Java trio (java_server, java_server_version, java_version) is all-or-none; and at most one language stack may be set per app — one image or one language version, not several."
  }

  validation {
    condition = alltrue([
      for app in var.linux_web_app_slots : length(app.tags) <= 50 && alltrue([for k, v in app.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
  validation {
    condition = alltrue([
      for slot in var.linux_web_app_slots : contains(keys(var.linux_web_apps), slot.app_key)
    ])
    error_message = "slot app_key must reference an existing linux_web_apps map key — slots live under their parent azurerm_linux_web_app."
  }

  validation {
    condition = alltrue([
      for slot in var.linux_web_app_slots : length(trimspace(slot.app_key)) > 0
    ])
    error_message = "app_key must not be empty or whitespace."
  }


  validation {
    condition = alltrue(flatten([
      for app_key in keys(var.linux_web_app_slots) : [
        for names in [[for slot in var.linux_web_app_slots : slot.name if slot.app_key == app_key]] : [
          for a in range(length(names)) : alltrue([
            for b in range(length(names)) : a == b || lower(names[a]) != lower(names[b])
          ])
        ]
      ]
    ]))
    error_message = "slot names must be unique within their app (case-insensitively) — a web app cannot carry two slots sharing a name."
  }
}

variable "windows_web_app_slots" {
  description = "Map of Windows deployment slots keyed by an arbitrary identifier; slot output keys compose as `<app_key>.<slot_key>`. Each entry creates one azurerm_windows_web_app_slot under the parent Windows web app via app_key, optionally overriding the parent's plan with service_plan_id."
  type = map(object({
    name    = string
    app_key = string

    service_plan_id = optional(string)

    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    virtual_network_subnet_id          = optional(string)
    https_only                         = optional(bool, false)
    public_network_access_enabled      = optional(bool, true)
    client_affinity_enabled            = optional(bool, false)
    client_certificate_enabled         = optional(bool, false)
    client_certificate_mode            = optional(string)
    client_certificate_exclusion_paths = optional(string)
    enabled                            = optional(bool, true)
    end_to_end_tls_encryption_enabled  = optional(bool, false)

    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    app_settings = optional(map(string), {})

    site_config = object({
      always_on             = optional(bool, true)
      api_definition_url    = optional(string)
      api_management_api_id = optional(string)
      app_command_line      = optional(string)
      application_stack = optional(object({
        current_stack                = optional(string)
        dotnet_version               = optional(string)
        dotnet_core_version          = optional(string)
        tomcat_version               = optional(string)
        java_embedded_server_enabled = optional(bool)
        java_version                 = optional(string)
        node_version                 = optional(string)
        php_version                  = optional(string)
        python                       = optional(bool)
      }))
      cors = optional(object({
        allowed_origins     = list(string)
        support_credentials = optional(bool, false)
      }))
      default_documents                 = optional(list(string), [])
      ftps_state                        = optional(string, "Disabled")
      health_check_path                 = optional(string)
      health_check_eviction_time_in_min = optional(number)
      http2_enabled                     = optional(bool)
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
      load_balancing_mode               = optional(string)
      local_mysql_enabled               = optional(bool)
      minimum_tls_version               = optional(string, "1.2")
      scm_minimum_tls_version           = optional(string, "1.2")
      remote_debugging_enabled          = optional(bool)
      remote_debugging_version          = optional(string)
      scm_use_main_ip_restriction       = optional(bool)
      use_32_bit_worker                 = optional(bool)
      vnet_route_all_enabled            = optional(bool)
      websockets_enabled                = optional(bool)
      worker_count                      = optional(number)
      auto_swap_slot_name               = optional(string)
    })

    tags = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for key in keys(var.windows_web_app_slots) : !can(regex("\\.", key))
    ])
    error_message = "windows_web_app_slots map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.windows_web_app_slots : alltrue([
        for cs_key in keys(app.connection_strings) : !can(regex("\\.", cs_key))
      ])
    ])
    error_message = "connection_strings map keys (they double as the connection string name) must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for key, app in var.windows_web_app_slots : alltrue([
        for ipr_key in concat(keys(app.site_config.ip_restriction), keys(app.site_config.scm_ip_restriction)) : !can(regex("\\.", ipr_key))
      ])
    ])
    error_message = "site_config ip_restriction and scm_ip_restriction map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_app_slots : can(regex("^[0-9a-zA-Z-]{1,60}$", app.name))
    ])
    error_message = "slot name must be 1-60 letters, digits or hyphens (provider-validated format, same charset as app names) and is unique within its app."
  }

  validation {
    condition = alltrue([
      for slot in var.windows_web_app_slots : length(trimspace(slot.name)) > 0
    ])
    error_message = "slot name must not be empty or whitespace."
  }
  validation {
    condition = alltrue([
      for app in var.windows_web_app_slots : app.identity == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], app.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned or \"SystemAssigned, UserAssigned\" (exact casing)."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_app_slots : app.identity == null || app.identity.type == "SystemAssigned" || length(app.identity.identity_ids) > 0
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — fill it with managed identity resource IDs."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_app_slots : app.virtual_network_subnet_id == null || can(regex("^/", app.virtual_network_subnet_id))
    ])
    error_message = "virtual_network_subnet_id, when set, must be a full ARM resource ID (starts with \"/\") of a dedicated subnet for VNET integration."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_app_slots : app.client_certificate_mode == null || app.client_certificate_enabled == true
    ])
    error_message = "client_certificate_mode applies only when client_certificate_enabled is true."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_app_slots : app.client_certificate_mode == null || contains(["Required", "Optional", "OptionalInteractiveUser"], app.client_certificate_mode)
    ])
    error_message = "client_certificate_mode must be one of Required, Optional or OptionalInteractiveUser (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_app_slots : [
        for cs in app.connection_strings : contains(["APIHub", "Custom", "DocDb", "EventHub", "MySql", "NotificationHub", "PostgreSQL", "RedisCache", "ServiceBus", "SQLAzure", "SQLServer"], cs.type)
      ]
    ]))
    error_message = "connection_strings type must be one of the documented values: APIHub, Custom, DocDb, EventHub, MySql, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure or SQLServer (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_app_slots : [
        app.site_config.health_check_eviction_time_in_min == null || length(app.site_config.health_check_path == null ? "" : app.site_config.health_check_path) > 0,
        app.site_config.health_check_eviction_time_in_min == null || (app.site_config.health_check_eviction_time_in_min >= 2 && app.site_config.health_check_eviction_time_in_min <= 10)
      ]
    ]))
    error_message = "site_config health_check_eviction_time_in_min requires a health_check_path and must be between 2 and 10 minutes."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_app_slots : [
        contains(["AllAllowed", "FtpsOnly", "Disabled"], app.site_config.ftps_state)
      ]
    ]))
    error_message = "site_config ftps_state must be one of AllAllowed, FtpsOnly or Disabled (case-sensitive). The provider defaults this to Disabled where Azure's own default is AllAllowed — set it explicitly for the posture you want."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_app_slots : [
        contains(["Allow", "Deny"], app.site_config.ip_restriction_default_action == null ? "Allow" : app.site_config.ip_restriction_default_action),
        contains(["Allow", "Deny"], app.site_config.scm_ip_restriction_default_action == null ? "Allow" : app.site_config.scm_ip_restriction_default_action)
      ]
    ]))
    error_message = "site_config ip_restriction_default_action and scm_ip_restriction_default_action, when set, must be Allow or Deny (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_app_slots : flatten([
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
      for app in var.windows_web_app_slots : [
        app.site_config.minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.minimum_tls_version),
        app.site_config.scm_minimum_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], app.site_config.scm_minimum_tls_version)
      ]
    ]))
    error_message = "site_config minimum_tls_version and scm_minimum_tls_version, when set, must be one of 1.0, 1.1, 1.2 or 1.3."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_app_slots : [
        app.site_config.remote_debugging_version == null || contains(["VS2017", "VS2019", "VS2022"], app.site_config.remote_debugging_version)
      ]
    ]))
    error_message = "site_config remote_debugging_version must be one of VS2017, VS2019 or VS2022 (case-sensitive) and pairs with remote_debugging_enabled."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.windows_web_app_slots : flatten([
        for stack in app.site_config.application_stack != null ? [app.site_config.application_stack] : [] : [
          length(compact([stack.current_stack, stack.dotnet_version, stack.dotnet_core_version, stack.tomcat_version, stack.java_version, stack.node_version, stack.php_version])) == 0 || stack.current_stack != null,
          stack.current_stack == null || contains(["dotnet", "dotnetcore", "node", "python", "php", "java"], stack.current_stack)
        ]
      ])
    ]))
    error_message = "site_config application_stack: current_stack (one of dotnet, dotnetcore, node, python, php or java, case-sensitive) is required when any version field is set — set current_stack first, then its version attribute."
  }

  validation {
    condition = alltrue([
      for app in var.windows_web_app_slots : length(app.tags) <= 50 && alltrue([for k, v in app.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
  validation {
    condition = alltrue([
      for slot in var.windows_web_app_slots : contains(keys(var.windows_web_apps), slot.app_key)
    ])
    error_message = "slot app_key must reference an existing windows_web_apps map key — slots live under their parent azurerm_windows_web_app."
  }

  validation {
    condition = alltrue([
      for slot in var.windows_web_app_slots : length(trimspace(slot.app_key)) > 0
    ])
    error_message = "app_key must not be empty or whitespace."
  }


  validation {
    condition = alltrue(flatten([
      for app_key in keys(var.windows_web_app_slots) : [
        for names in [[for slot in var.windows_web_app_slots : slot.name if slot.app_key == app_key]] : [
          for a in range(length(names)) : alltrue([
            for b in range(length(names)) : a == b || lower(names[a]) != lower(names[b])
          ])
        ]
      ]
    ]))
    error_message = "slot names must be unique within their app (case-insensitively) — a web app cannot carry two slots sharing a name."
  }
}
