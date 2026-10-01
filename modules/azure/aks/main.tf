locals {
  node_pools = { for pool_key, pool in var.node_pools : "${pool.cluster_key}.${pool_key}" => merge(pool, { pool_key = pool_key }) }
}

resource "azurerm_kubernetes_cluster" "cluster" {
  for_each = var.clusters

  name                       = each.value.name
  location                   = each.value.location
  resource_group_name        = each.value.resource_group_name
  sku_tier                   = each.value.sku_tier
  support_plan               = each.value.support_plan
  kubernetes_version         = each.value.kubernetes_version
  dns_prefix                 = each.value.dns_prefix
  dns_prefix_private_cluster = each.value.dns_prefix_private_cluster

  node_provisioning_profile {
    mode               = try(each.value.node_provisioning_profile.mode, "Manual")
    default_node_pools = try(each.value.node_provisioning_profile.default_node_pools, "Auto")
  }

  default_node_pool {
    name                         = each.value.default_node_pool.name
    vm_size                      = each.value.default_node_pool.vm_size
    node_count                   = each.value.default_node_pool.node_count
    auto_scaling_enabled         = each.value.default_node_pool.auto_scaling_enabled
    min_count                    = each.value.default_node_pool.min_count
    max_count                    = each.value.default_node_pool.max_count
    max_pods                     = each.value.default_node_pool.max_pods
    os_disk_size_gb              = each.value.default_node_pool.os_disk_size_gb
    os_disk_type                 = each.value.default_node_pool.os_disk_type
    os_sku                       = each.value.default_node_pool.os_sku
    vnet_subnet_id               = each.value.default_node_pool.vnet_subnet_id
    pod_subnet_id                = each.value.default_node_pool.pod_subnet_id
    zones                        = each.value.default_node_pool.zones
    node_labels                  = each.value.default_node_pool.node_labels
    only_critical_addons_enabled = each.value.default_node_pool.only_critical_addons_enabled
    ultra_ssd_enabled            = each.value.default_node_pool.ultra_ssd_enabled
    fips_enabled                 = each.value.default_node_pool.fips_enabled
    host_encryption_enabled      = each.value.default_node_pool.host_encryption_enabled
    node_public_ip_enabled       = each.value.default_node_pool.node_public_ip_enabled
    scale_down_mode              = each.value.default_node_pool.scale_down_mode
    temporary_name_for_rotation  = each.value.default_node_pool.temporary_name_for_rotation

    dynamic "upgrade_settings" {
      for_each = each.value.default_node_pool.upgrade_settings != null ? [each.value.default_node_pool.upgrade_settings] : []

      content {
        max_surge                     = upgrade_settings.value.max_surge
        drain_timeout_in_minutes      = upgrade_settings.value.drain_timeout_in_minutes
        node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
      }
    }

    tags = each.value.default_node_pool.tags
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "service_principal" {
    for_each = each.value.service_principal != null ? [each.value.service_principal] : []

    content {
      client_id     = service_principal.value.client_id
      client_secret = service_principal.value.client_secret
    }
  }

  dynamic "network_profile" {
    for_each = each.value.network_profile != null ? [each.value.network_profile] : []

    content {
      network_plugin      = network_profile.value.network_plugin
      network_plugin_mode = network_profile.value.network_plugin_mode
      network_mode        = network_profile.value.network_mode
      network_policy      = network_profile.value.network_policy
      network_data_plane  = network_profile.value.network_data_plane
      dns_service_ip      = network_profile.value.dns_service_ip
      service_cidr        = network_profile.value.service_cidr
      service_cidrs       = network_profile.value.service_cidrs
      pod_cidr            = network_profile.value.pod_cidr
      pod_cidrs           = network_profile.value.pod_cidrs
      outbound_type       = network_profile.value.outbound_type
      load_balancer_sku   = network_profile.value.load_balancer_sku

      dynamic "load_balancer_profile" {
        for_each = network_profile.value.load_balancer_profile != null ? [network_profile.value.load_balancer_profile] : []

        content {
          managed_outbound_ip_count   = load_balancer_profile.value.managed_outbound_ip_count
          managed_outbound_ipv6_count = load_balancer_profile.value.managed_outbound_ipv6_count
          outbound_ip_address_ids     = load_balancer_profile.value.outbound_ip_address_ids
          outbound_ip_prefix_ids      = load_balancer_profile.value.outbound_ip_prefix_ids
          idle_timeout_in_minutes     = load_balancer_profile.value.idle_timeout_in_minutes
          backend_pool_type           = load_balancer_profile.value.backend_pool_type
        }
      }

      dynamic "nat_gateway_profile" {
        for_each = network_profile.value.nat_gateway_profile != null ? [network_profile.value.nat_gateway_profile] : []

        content {
          idle_timeout_in_minutes   = nat_gateway_profile.value.idle_timeout_in_minutes
          managed_outbound_ip_count = nat_gateway_profile.value.managed_outbound_ip_count
        }
      }
    }
  }

  private_cluster_enabled             = each.value.private_cluster_enabled
  private_dns_zone_id                 = each.value.private_dns_zone_id
  private_cluster_public_fqdn_enabled = each.value.private_cluster_public_fqdn_enabled

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = each.value.azure_active_directory_role_based_access_control != null ? [each.value.azure_active_directory_role_based_access_control] : []

    content {
      tenant_id              = azure_active_directory_role_based_access_control.value.tenant_id
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
    }
  }

  role_based_access_control_enabled = each.value.role_based_access_control_enabled
  local_account_disabled            = each.value.local_account_disabled

  dynamic "api_server_access_profile" {
    for_each = each.value.api_server_access_profile != null ? [each.value.api_server_access_profile] : []

    content {
      authorized_ip_ranges                = api_server_access_profile.value.authorized_ip_ranges
      subnet_id                           = api_server_access_profile.value.subnet_id
      virtual_network_integration_enabled = api_server_access_profile.value.virtual_network_integration_enabled
    }
  }

  dynamic "auto_scaler_profile" {
    for_each = each.value.auto_scaler_profile != null ? [each.value.auto_scaler_profile] : []

    content {
      expander                                      = auto_scaler_profile.value.expander
      scan_interval                                 = auto_scaler_profile.value.scan_interval
      scale_down_delay_after_add                    = auto_scaler_profile.value.scale_down_delay_after_add
      scale_down_delay_after_delete                 = auto_scaler_profile.value.scale_down_delay_after_delete
      scale_down_delay_after_failure                = auto_scaler_profile.value.scale_down_delay_after_failure
      scale_down_unneeded                           = auto_scaler_profile.value.scale_down_unneeded
      scale_down_unready                            = auto_scaler_profile.value.scale_down_unready
      scale_down_utilization_threshold              = auto_scaler_profile.value.scale_down_utilization_threshold
      max_graceful_termination_sec                  = auto_scaler_profile.value.max_graceful_termination_sec
      max_node_provisioning_time                    = auto_scaler_profile.value.max_node_provisioning_time
      max_unready_nodes                             = auto_scaler_profile.value.max_unready_nodes
      max_unready_percentage                        = auto_scaler_profile.value.max_unready_percentage
      new_pod_scale_up_delay                        = auto_scaler_profile.value.new_pod_scale_up_delay
      empty_bulk_delete_max                         = auto_scaler_profile.value.empty_bulk_delete_max
      balance_similar_node_groups                   = auto_scaler_profile.value.balance_similar_node_groups
      daemonset_eviction_for_empty_nodes_enabled    = auto_scaler_profile.value.daemonset_eviction_for_empty_nodes_enabled
      daemonset_eviction_for_occupied_nodes_enabled = auto_scaler_profile.value.daemonset_eviction_for_occupied_nodes_enabled
      ignore_daemonsets_utilization_enabled         = auto_scaler_profile.value.ignore_daemonsets_utilization_enabled
      skip_nodes_with_local_storage                 = auto_scaler_profile.value.skip_nodes_with_local_storage
      skip_nodes_with_system_pods                   = auto_scaler_profile.value.skip_nodes_with_system_pods
    }
  }

  dynamic "maintenance_window" {
    for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []

    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed

        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }

      dynamic "not_allowed" {
        for_each = maintenance_window.value.not_allowed

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  dynamic "maintenance_window_auto_upgrade" {
    for_each = each.value.maintenance_window_auto_upgrade != null ? [each.value.maintenance_window_auto_upgrade] : []

    content {
      frequency    = maintenance_window_auto_upgrade.value.frequency
      interval     = maintenance_window_auto_upgrade.value.interval
      duration     = maintenance_window_auto_upgrade.value.duration
      day_of_week  = maintenance_window_auto_upgrade.value.day_of_week
      day_of_month = maintenance_window_auto_upgrade.value.day_of_month
      week_index   = maintenance_window_auto_upgrade.value.week_index
      start_time   = maintenance_window_auto_upgrade.value.start_time
      utc_offset   = maintenance_window_auto_upgrade.value.utc_offset
      start_date   = maintenance_window_auto_upgrade.value.start_date

      dynamic "not_allowed" {
        for_each = maintenance_window_auto_upgrade.value.not_allowed

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  dynamic "maintenance_window_node_os" {
    for_each = each.value.maintenance_window_node_os != null ? [each.value.maintenance_window_node_os] : []

    content {
      frequency    = maintenance_window_node_os.value.frequency
      interval     = maintenance_window_node_os.value.interval
      duration     = maintenance_window_node_os.value.duration
      day_of_week  = maintenance_window_node_os.value.day_of_week
      day_of_month = maintenance_window_node_os.value.day_of_month
      week_index   = maintenance_window_node_os.value.week_index
      start_time   = maintenance_window_node_os.value.start_time
      utc_offset   = maintenance_window_node_os.value.utc_offset
      start_date   = maintenance_window_node_os.value.start_date

      dynamic "not_allowed" {
        for_each = maintenance_window_node_os.value.not_allowed

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  dynamic "microsoft_defender" {
    for_each = each.value.microsoft_defender != null ? [each.value.microsoft_defender] : []

    content {
      log_analytics_workspace_id = microsoft_defender.value.log_analytics_workspace_id
    }
  }

  dynamic "monitor_metrics" {
    for_each = each.value.monitor_metrics != null ? [each.value.monitor_metrics] : []

    content {
      annotations_allowed = monitor_metrics.value.annotations_allowed
      labels_allowed      = monitor_metrics.value.labels_allowed
    }
  }

  dynamic "key_management_service" {
    for_each = each.value.key_management_service != null ? [each.value.key_management_service] : []

    content {
      key_vault_key_id         = key_management_service.value.key_vault_key_id
      key_vault_network_access = key_management_service.value.key_vault_network_access
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = each.value.key_vault_secrets_provider != null ? [each.value.key_vault_secrets_provider] : []

    content {
      secret_rotation_enabled  = key_vault_secrets_provider.value.secret_rotation_enabled
      secret_rotation_interval = key_vault_secrets_provider.value.secret_rotation_interval
    }
  }

  azure_policy_enabled         = each.value.azure_policy_enabled
  cost_analysis_enabled        = each.value.cost_analysis_enabled
  image_cleaner_enabled        = each.value.image_cleaner_enabled
  image_cleaner_interval_hours = each.value.image_cleaner_interval_hours
  disk_encryption_set_id       = each.value.disk_encryption_set_id
  node_resource_group          = each.value.node_resource_group
  edge_zone                    = each.value.edge_zone
  automatic_upgrade_channel    = each.value.automatic_upgrade_channel
  node_os_upgrade_channel      = each.value.node_os_upgrade_channel
  run_command_enabled          = each.value.run_command_enabled

  oidc_issuer_enabled       = each.value.oidc_issuer_enabled
  workload_identity_enabled = each.value.workload_identity_enabled

  tags = each.value.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
  for_each = local.node_pools

  kubernetes_cluster_id       = azurerm_kubernetes_cluster.cluster[each.value.cluster_key].id
  name                        = each.value.name
  vm_size                     = each.value.vm_size
  mode                        = each.value.mode
  os_type                     = each.value.os_type
  os_sku                      = each.value.os_sku
  node_count                  = each.value.node_count
  auto_scaling_enabled        = each.value.auto_scaling_enabled
  min_count                   = each.value.min_count
  max_count                   = each.value.max_count
  max_pods                    = each.value.max_pods
  os_disk_size_gb             = each.value.os_disk_size_gb
  os_disk_type                = each.value.os_disk_type
  vnet_subnet_id              = each.value.vnet_subnet_id
  pod_subnet_id               = each.value.pod_subnet_id
  zones                       = each.value.zones
  node_labels                 = each.value.node_labels
  node_taints                 = each.value.node_taints
  priority                    = each.value.priority
  spot_max_price              = each.value.spot_max_price
  eviction_policy             = each.value.eviction_policy
  scale_down_mode             = each.value.scale_down_mode
  orchestrator_version        = each.value.orchestrator_version
  fips_enabled                = each.value.fips_enabled
  host_encryption_enabled     = each.value.host_encryption_enabled
  node_public_ip_enabled      = each.value.node_public_ip_enabled
  ultra_ssd_enabled           = each.value.ultra_ssd_enabled
  kubelet_disk_type           = each.value.kubelet_disk_type
  temporary_name_for_rotation = each.value.temporary_name_for_rotation

  dynamic "upgrade_settings" {
    for_each = each.value.upgrade_settings != null ? [each.value.upgrade_settings] : []

    content {
      max_surge                     = upgrade_settings.value.max_surge
      max_unavailable               = upgrade_settings.value.max_unavailable
      drain_timeout_in_minutes      = upgrade_settings.value.drain_timeout_in_minutes
      node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
    }
  }

  tags = each.value.tags
}
