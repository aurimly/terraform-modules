locals {
  linux_slots = { for slot_key, slot in var.linux_web_app_slots : "${slot.app_key}.${slot_key}" => merge(slot, { app_id = azurerm_linux_web_app.linux_web_app[slot.app_key].id, slot_key = slot_key }) }

  windows_slots = { for slot_key, slot in var.windows_web_app_slots : "${slot.app_key}.${slot_key}" => merge(slot, { app_id = azurerm_windows_web_app.windows_web_app[slot.app_key].id, slot_key = slot_key }) }
}

resource "azurerm_service_plan" "service_plan" {
  for_each = var.service_plans

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name

  worker_count                    = each.value.worker_count
  maximum_elastic_worker_count    = each.value.maximum_elastic_worker_count
  premium_plan_auto_scale_enabled = each.value.premium_plan_auto_scale_enabled
  per_site_scaling_enabled        = each.value.per_site_scaling_enabled
  zone_balancing_enabled          = each.value.zone_balancing_enabled

  app_service_environment_id = each.value.app_service_environment_id

  tags = each.value.tags
}

resource "azurerm_linux_web_app" "linux_web_app" {
  for_each = var.linux_web_apps

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  service_plan_id = each.value.service_plan_key != null ? azurerm_service_plan.service_plan[each.value.service_plan_key].id : each.value.service_plan_id

  app_settings = each.value.app_settings

  dynamic "connection_string" {
    for_each = each.value.connection_strings

    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  key_vault_reference_identity_id = each.value.key_vault_reference_identity_id

  https_only                         = each.value.https_only
  public_network_access_enabled      = each.value.public_network_access_enabled
  client_affinity_enabled            = each.value.client_affinity_enabled
  client_certificate_enabled         = each.value.client_certificate_enabled
  client_certificate_mode            = each.value.client_certificate_mode
  client_certificate_exclusion_paths = each.value.client_certificate_exclusion_paths
  enabled                            = each.value.enabled
  end_to_end_tls_encryption_enabled  = each.value.end_to_end_tls_encryption_enabled

  ftp_publish_basic_authentication_enabled       = each.value.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled

  site_config {
    always_on             = each.value.site_config.always_on
    api_definition_url    = each.value.site_config.api_definition_url
    api_management_api_id = each.value.site_config.api_management_api_id
    app_command_line      = each.value.site_config.app_command_line

    container_registry_use_managed_identity       = each.value.site_config.container_registry_use_managed_identity
    container_registry_managed_identity_client_id = each.value.site_config.container_registry_managed_identity_client_id

    default_documents = each.value.site_config.default_documents

    ftps_state                        = each.value.site_config.ftps_state
    health_check_path                 = each.value.site_config.health_check_path
    health_check_eviction_time_in_min = each.value.site_config.health_check_eviction_time_in_min
    http2_enabled                     = each.value.site_config.http2_enabled

    load_balancing_mode     = each.value.site_config.load_balancing_mode
    local_mysql_enabled     = each.value.site_config.local_mysql_enabled
    minimum_tls_version     = each.value.site_config.minimum_tls_version
    scm_minimum_tls_version = each.value.site_config.scm_minimum_tls_version

    remote_debugging_enabled = each.value.site_config.remote_debugging_enabled
    remote_debugging_version = each.value.site_config.remote_debugging_version

    scm_use_main_ip_restriction = each.value.site_config.scm_use_main_ip_restriction
    use_32_bit_worker           = each.value.site_config.use_32_bit_worker
    vnet_route_all_enabled      = each.value.site_config.vnet_route_all_enabled
    websockets_enabled          = each.value.site_config.websockets_enabled
    worker_count                = each.value.site_config.worker_count

    dynamic "cors" {
      for_each = each.value.site_config.cors != null ? [each.value.site_config.cors] : []

      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = each.value.site_config.ip_restriction

      content {
        name                      = ip_restriction.value.name
        action                    = ip_restriction.value.action
        priority                  = ip_restriction.value.priority
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
        description               = ip_restriction.value.description
      }
    }

    ip_restriction_default_action = each.value.site_config.ip_restriction_default_action

    dynamic "scm_ip_restriction" {
      for_each = each.value.site_config.scm_ip_restriction

      content {
        name                      = scm_ip_restriction.value.name
        action                    = scm_ip_restriction.value.action
        priority                  = scm_ip_restriction.value.priority
        ip_address                = scm_ip_restriction.value.ip_address
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
        description               = scm_ip_restriction.value.description
      }
    }

    scm_ip_restriction_default_action = each.value.site_config.scm_ip_restriction_default_action

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack != null ? [each.value.site_config.application_stack] : []

      content {
        docker_image_name        = application_stack.value.docker_image_name
        docker_registry_url      = application_stack.value.docker_registry_url
        docker_registry_username = application_stack.value.docker_registry_username
        docker_registry_password = application_stack.value.docker_registry_password
        dotnet_version           = application_stack.value.dotnet_version
        go_version               = application_stack.value.go_version
        java_server              = application_stack.value.java_server
        java_server_version      = application_stack.value.java_server_version
        java_version             = application_stack.value.java_version
        node_version             = application_stack.value.node_version
        php_version              = application_stack.value.php_version
        python_version           = application_stack.value.python_version
      }
    }
  }

  virtual_network_subnet_id = each.value.virtual_network_subnet_id

  tags = each.value.tags
}

resource "azurerm_windows_web_app" "windows_web_app" {
  for_each = var.windows_web_apps

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  service_plan_id = each.value.service_plan_key != null ? azurerm_service_plan.service_plan[each.value.service_plan_key].id : each.value.service_plan_id

  app_settings = each.value.app_settings

  dynamic "connection_string" {
    for_each = each.value.connection_strings

    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  key_vault_reference_identity_id = each.value.key_vault_reference_identity_id

  https_only                         = each.value.https_only
  public_network_access_enabled      = each.value.public_network_access_enabled
  client_affinity_enabled            = each.value.client_affinity_enabled
  client_certificate_enabled         = each.value.client_certificate_enabled
  client_certificate_mode            = each.value.client_certificate_mode
  client_certificate_exclusion_paths = each.value.client_certificate_exclusion_paths
  enabled                            = each.value.enabled
  end_to_end_tls_encryption_enabled  = each.value.end_to_end_tls_encryption_enabled

  ftp_publish_basic_authentication_enabled       = each.value.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled

  site_config {
    always_on             = each.value.site_config.always_on
    api_definition_url    = each.value.site_config.api_definition_url
    api_management_api_id = each.value.site_config.api_management_api_id
    app_command_line      = each.value.site_config.app_command_line

    default_documents = each.value.site_config.default_documents

    ftps_state                        = each.value.site_config.ftps_state
    health_check_path                 = each.value.site_config.health_check_path
    health_check_eviction_time_in_min = each.value.site_config.health_check_eviction_time_in_min
    http2_enabled                     = each.value.site_config.http2_enabled

    load_balancing_mode     = each.value.site_config.load_balancing_mode
    local_mysql_enabled     = each.value.site_config.local_mysql_enabled
    minimum_tls_version     = each.value.site_config.minimum_tls_version
    scm_minimum_tls_version = each.value.site_config.scm_minimum_tls_version

    remote_debugging_enabled = each.value.site_config.remote_debugging_enabled
    remote_debugging_version = each.value.site_config.remote_debugging_version

    scm_use_main_ip_restriction = each.value.site_config.scm_use_main_ip_restriction
    use_32_bit_worker           = each.value.site_config.use_32_bit_worker
    vnet_route_all_enabled      = each.value.site_config.vnet_route_all_enabled
    websockets_enabled          = each.value.site_config.websockets_enabled
    worker_count                = each.value.site_config.worker_count

    dynamic "cors" {
      for_each = each.value.site_config.cors != null ? [each.value.site_config.cors] : []

      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = each.value.site_config.ip_restriction

      content {
        name                      = ip_restriction.value.name
        action                    = ip_restriction.value.action
        priority                  = ip_restriction.value.priority
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
        description               = ip_restriction.value.description
      }
    }

    ip_restriction_default_action = each.value.site_config.ip_restriction_default_action

    dynamic "scm_ip_restriction" {
      for_each = each.value.site_config.scm_ip_restriction

      content {
        name                      = scm_ip_restriction.value.name
        action                    = scm_ip_restriction.value.action
        priority                  = scm_ip_restriction.value.priority
        ip_address                = scm_ip_restriction.value.ip_address
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
        description               = scm_ip_restriction.value.description
      }
    }

    scm_ip_restriction_default_action = each.value.site_config.scm_ip_restriction_default_action

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack != null ? [each.value.site_config.application_stack] : []

      content {
        current_stack                = application_stack.value.current_stack
        dotnet_version               = application_stack.value.dotnet_version
        dotnet_core_version          = application_stack.value.dotnet_core_version
        tomcat_version               = application_stack.value.tomcat_version
        java_embedded_server_enabled = application_stack.value.java_embedded_server_enabled
        java_version                 = application_stack.value.java_version
        node_version                 = application_stack.value.node_version
        php_version                  = application_stack.value.php_version
        python                       = application_stack.value.python
      }
    }
  }

  virtual_network_subnet_id = each.value.virtual_network_subnet_id

  tags = each.value.tags
}

resource "azurerm_linux_web_app_slot" "linux_slot" {
  for_each = local.linux_slots

  name           = each.value.name
  app_service_id = each.value.app_id

  service_plan_id = each.value.service_plan_id

  https_only                         = each.value.https_only
  public_network_access_enabled      = each.value.public_network_access_enabled
  client_affinity_enabled            = each.value.client_affinity_enabled
  client_certificate_enabled         = each.value.client_certificate_enabled
  client_certificate_mode            = each.value.client_certificate_mode
  client_certificate_exclusion_paths = each.value.client_certificate_exclusion_paths
  enabled                            = each.value.enabled
  end_to_end_tls_encryption_enabled  = each.value.end_to_end_tls_encryption_enabled

  ftp_publish_basic_authentication_enabled       = each.value.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled

  app_settings = each.value.app_settings

  dynamic "connection_string" {
    for_each = each.value.connection_strings

    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  key_vault_reference_identity_id = each.value.key_vault_reference_identity_id

  site_config {
    always_on             = each.value.site_config.always_on
    api_definition_url    = each.value.site_config.api_definition_url
    api_management_api_id = each.value.site_config.api_management_api_id
    app_command_line      = each.value.site_config.app_command_line

    container_registry_use_managed_identity       = each.value.site_config.container_registry_use_managed_identity
    container_registry_managed_identity_client_id = each.value.site_config.container_registry_managed_identity_client_id

    default_documents = each.value.site_config.default_documents

    ftps_state                        = each.value.site_config.ftps_state
    health_check_path                 = each.value.site_config.health_check_path
    health_check_eviction_time_in_min = each.value.site_config.health_check_eviction_time_in_min
    http2_enabled                     = each.value.site_config.http2_enabled

    load_balancing_mode     = each.value.site_config.load_balancing_mode
    local_mysql_enabled     = each.value.site_config.local_mysql_enabled
    minimum_tls_version     = each.value.site_config.minimum_tls_version
    scm_minimum_tls_version = each.value.site_config.scm_minimum_tls_version

    remote_debugging_enabled = each.value.site_config.remote_debugging_enabled
    remote_debugging_version = each.value.site_config.remote_debugging_version

    scm_use_main_ip_restriction = each.value.site_config.scm_use_main_ip_restriction
    use_32_bit_worker           = each.value.site_config.use_32_bit_worker
    vnet_route_all_enabled      = each.value.site_config.vnet_route_all_enabled
    websockets_enabled          = each.value.site_config.websockets_enabled
    worker_count                = each.value.site_config.worker_count

    auto_swap_slot_name = each.value.site_config.auto_swap_slot_name

    dynamic "cors" {
      for_each = each.value.site_config.cors != null ? [each.value.site_config.cors] : []

      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = each.value.site_config.ip_restriction

      content {
        name                      = ip_restriction.value.name
        action                    = ip_restriction.value.action
        priority                  = ip_restriction.value.priority
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
        description               = ip_restriction.value.description
      }
    }

    ip_restriction_default_action = each.value.site_config.ip_restriction_default_action

    dynamic "scm_ip_restriction" {
      for_each = each.value.site_config.scm_ip_restriction

      content {
        name                      = scm_ip_restriction.value.name
        action                    = scm_ip_restriction.value.action
        priority                  = scm_ip_restriction.value.priority
        ip_address                = scm_ip_restriction.value.ip_address
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
        description               = scm_ip_restriction.value.description
      }
    }

    scm_ip_restriction_default_action = each.value.site_config.scm_ip_restriction_default_action

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack != null ? [each.value.site_config.application_stack] : []

      content {
        docker_image_name        = application_stack.value.docker_image_name
        docker_registry_url      = application_stack.value.docker_registry_url
        docker_registry_username = application_stack.value.docker_registry_username
        docker_registry_password = application_stack.value.docker_registry_password
        dotnet_version           = application_stack.value.dotnet_version
        go_version               = application_stack.value.go_version
        java_server              = application_stack.value.java_server
        java_server_version      = application_stack.value.java_server_version
        java_version             = application_stack.value.java_version
        node_version             = application_stack.value.node_version
        php_version              = application_stack.value.php_version
        python_version           = application_stack.value.python_version
      }
    }
  }

  virtual_network_subnet_id = each.value.virtual_network_subnet_id

  tags = each.value.tags
}

resource "azurerm_windows_web_app_slot" "windows_slot" {
  for_each = local.windows_slots

  name           = each.value.name
  app_service_id = each.value.app_id

  service_plan_id = each.value.service_plan_id

  https_only                         = each.value.https_only
  public_network_access_enabled      = each.value.public_network_access_enabled
  client_affinity_enabled            = each.value.client_affinity_enabled
  client_certificate_enabled         = each.value.client_certificate_enabled
  client_certificate_mode            = each.value.client_certificate_mode
  client_certificate_exclusion_paths = each.value.client_certificate_exclusion_paths
  enabled                            = each.value.enabled
  end_to_end_tls_encryption_enabled  = each.value.end_to_end_tls_encryption_enabled

  ftp_publish_basic_authentication_enabled       = each.value.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled

  app_settings = each.value.app_settings

  dynamic "connection_string" {
    for_each = each.value.connection_strings

    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  key_vault_reference_identity_id = each.value.key_vault_reference_identity_id

  site_config {
    always_on             = each.value.site_config.always_on
    api_definition_url    = each.value.site_config.api_definition_url
    api_management_api_id = each.value.site_config.api_management_api_id
    app_command_line      = each.value.site_config.app_command_line

    default_documents = each.value.site_config.default_documents

    ftps_state                        = each.value.site_config.ftps_state
    health_check_path                 = each.value.site_config.health_check_path
    health_check_eviction_time_in_min = each.value.site_config.health_check_eviction_time_in_min
    http2_enabled                     = each.value.site_config.http2_enabled

    load_balancing_mode     = each.value.site_config.load_balancing_mode
    local_mysql_enabled     = each.value.site_config.local_mysql_enabled
    minimum_tls_version     = each.value.site_config.minimum_tls_version
    scm_minimum_tls_version = each.value.site_config.scm_minimum_tls_version

    remote_debugging_enabled = each.value.site_config.remote_debugging_enabled
    remote_debugging_version = each.value.site_config.remote_debugging_version

    scm_use_main_ip_restriction = each.value.site_config.scm_use_main_ip_restriction
    use_32_bit_worker           = each.value.site_config.use_32_bit_worker
    vnet_route_all_enabled      = each.value.site_config.vnet_route_all_enabled
    websockets_enabled          = each.value.site_config.websockets_enabled
    worker_count                = each.value.site_config.worker_count

    auto_swap_slot_name = each.value.site_config.auto_swap_slot_name

    dynamic "cors" {
      for_each = each.value.site_config.cors != null ? [each.value.site_config.cors] : []

      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = each.value.site_config.ip_restriction

      content {
        name                      = ip_restriction.value.name
        action                    = ip_restriction.value.action
        priority                  = ip_restriction.value.priority
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
        description               = ip_restriction.value.description
      }
    }

    ip_restriction_default_action = each.value.site_config.ip_restriction_default_action

    dynamic "scm_ip_restriction" {
      for_each = each.value.site_config.scm_ip_restriction

      content {
        name                      = scm_ip_restriction.value.name
        action                    = scm_ip_restriction.value.action
        priority                  = scm_ip_restriction.value.priority
        ip_address                = scm_ip_restriction.value.ip_address
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
        description               = scm_ip_restriction.value.description
      }
    }

    scm_ip_restriction_default_action = each.value.site_config.scm_ip_restriction_default_action

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack != null ? [each.value.site_config.application_stack] : []

      content {
        current_stack                = application_stack.value.current_stack
        dotnet_version               = application_stack.value.dotnet_version
        dotnet_core_version          = application_stack.value.dotnet_core_version
        tomcat_version               = application_stack.value.tomcat_version
        java_embedded_server_enabled = application_stack.value.java_embedded_server_enabled
        java_version                 = application_stack.value.java_version
        node_version                 = application_stack.value.node_version
        php_version                  = application_stack.value.php_version
        python                       = application_stack.value.python
      }
    }
  }

  virtual_network_subnet_id = each.value.virtual_network_subnet_id

  tags = each.value.tags
}
