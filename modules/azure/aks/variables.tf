variable "clusters" {
  description = "Map of Azure AKS clusters keyed by an arbitrary identifier. Each entry creates one azurerm_kubernetes_cluster. Exactly one of the identity or service_principal attribute must be set, and exactly one of dns_prefix or dns_prefix_private_cluster. Additional node pools are defined separately in the node_pools variable."
  type = map(object({
    name                       = string
    location                   = string
    resource_group_name        = string
    dns_prefix                 = optional(string)
    dns_prefix_private_cluster = optional(string)
    kubernetes_version         = optional(string)
    sku_tier                   = optional(string, "Free")
    support_plan               = optional(string, "KubernetesOfficial")
    node_provisioning_profile = optional(object({
      mode               = optional(string, "Manual")
      default_node_pools = optional(string, "Auto")
    }))
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    service_principal = optional(object({
      client_id     = string
      client_secret = string
    }))
    default_node_pool = object({
      name                         = string
      vm_size                      = optional(string)
      node_count                   = optional(number)
      auto_scaling_enabled         = optional(bool, false)
      min_count                    = optional(number)
      max_count                    = optional(number)
      max_pods                     = optional(number)
      os_disk_size_gb              = optional(number)
      os_disk_type                 = optional(string, "Managed")
      os_sku                       = optional(string)
      vnet_subnet_id               = optional(string)
      pod_subnet_id                = optional(string)
      zones                        = optional(list(string), [])
      node_labels                  = optional(map(string), {})
      only_critical_addons_enabled = optional(bool)
      ultra_ssd_enabled            = optional(bool, false)
      fips_enabled                 = optional(bool, false)
      host_encryption_enabled      = optional(bool, false)
      node_public_ip_enabled       = optional(bool, false)
      scale_down_mode              = optional(string, "Delete")
      temporary_name_for_rotation  = optional(string)
      upgrade_settings = optional(object({
        max_surge                     = string
        drain_timeout_in_minutes      = optional(number)
        node_soak_duration_in_minutes = optional(number)
      }))
      tags = optional(map(string), {})
    })
    network_profile = optional(object({
      network_plugin      = string
      network_plugin_mode = optional(string)
      network_mode        = optional(string)
      network_policy      = optional(string)
      network_data_plane  = optional(string)
      dns_service_ip      = optional(string)
      service_cidr        = optional(string)
      service_cidrs       = optional(list(string))
      pod_cidr            = optional(string)
      pod_cidrs           = optional(list(string))
      outbound_type       = optional(string, "loadBalancer")
      load_balancer_sku   = optional(string, "standard")
      load_balancer_profile = optional(object({
        managed_outbound_ip_count   = optional(number)
        managed_outbound_ipv6_count = optional(number)
        outbound_ip_address_ids     = optional(list(string))
        outbound_ip_prefix_ids      = optional(list(string))
        idle_timeout_in_minutes     = optional(number)
        backend_pool_type           = optional(string)
      }))
      nat_gateway_profile = optional(object({
        idle_timeout_in_minutes   = optional(number)
        managed_outbound_ip_count = optional(number)
      }))
    }))
    private_cluster_enabled             = optional(bool, false)
    private_dns_zone_id                 = optional(string)
    private_cluster_public_fqdn_enabled = optional(bool, false)
    oidc_issuer_enabled                 = optional(bool)
    workload_identity_enabled           = optional(bool, false)
    role_based_access_control_enabled   = optional(bool, true)
    local_account_disabled              = optional(bool)
    azure_active_directory_role_based_access_control = optional(object({
      tenant_id              = optional(string)
      admin_group_object_ids = optional(list(string))
      azure_rbac_enabled     = optional(bool)
    }))
    api_server_access_profile = optional(object({
      authorized_ip_ranges                = optional(list(string), [])
      subnet_id                           = optional(string)
      virtual_network_integration_enabled = optional(bool)
    }))
    auto_scaler_profile = optional(object({
      expander                                      = optional(string)
      scan_interval                                 = optional(string)
      scale_down_delay_after_add                    = optional(string)
      scale_down_delay_after_delete                 = optional(string)
      scale_down_delay_after_failure                = optional(string)
      scale_down_unneeded                           = optional(string)
      scale_down_unready                            = optional(string)
      scale_down_utilization_threshold              = optional(string)
      max_graceful_termination_sec                  = optional(string)
      max_node_provisioning_time                    = optional(string)
      max_unready_nodes                             = optional(number)
      max_unready_percentage                        = optional(number)
      new_pod_scale_up_delay                        = optional(string)
      empty_bulk_delete_max                         = optional(number)
      balance_similar_node_groups                   = optional(bool)
      daemonset_eviction_for_empty_nodes_enabled    = optional(bool)
      daemonset_eviction_for_occupied_nodes_enabled = optional(bool)
      ignore_daemonsets_utilization_enabled         = optional(bool)
      skip_nodes_with_local_storage                 = optional(bool)
      skip_nodes_with_system_pods                   = optional(bool)
    }))
    maintenance_window = optional(object({
      allowed     = optional(map(object({ day = string, hours = list(number) })), {})
      not_allowed = optional(map(object({ start = string, end = string })), {})
    }))
    maintenance_window_auto_upgrade = optional(object({
      frequency    = string
      interval     = number
      duration     = number
      day_of_week  = optional(string)
      day_of_month = optional(number)
      week_index   = optional(string)
      start_time   = optional(string)
      utc_offset   = optional(string)
      start_date   = optional(string)
      not_allowed  = optional(map(object({ start = string, end = string })), {})
    }))
    maintenance_window_node_os = optional(object({
      frequency    = string
      interval     = number
      duration     = number
      day_of_week  = optional(string)
      day_of_month = optional(number)
      week_index   = optional(string)
      start_time   = optional(string)
      utc_offset   = optional(string)
      start_date   = optional(string)
      not_allowed  = optional(map(object({ start = string, end = string })), {})
    }))
    microsoft_defender = optional(object({
      log_analytics_workspace_id = string
    }))
    monitor_metrics = optional(object({
      annotations_allowed = optional(string)
      labels_allowed      = optional(string)
    }))
    key_management_service = optional(object({
      key_vault_key_id         = string
      key_vault_network_access = optional(string, "Public")
    }))
    key_vault_secrets_provider = optional(object({
      secret_rotation_enabled  = optional(bool)
      secret_rotation_interval = optional(string)
    }))
    azure_policy_enabled         = optional(bool)
    cost_analysis_enabled        = optional(bool)
    image_cleaner_enabled        = optional(bool)
    image_cleaner_interval_hours = optional(number)
    disk_encryption_set_id       = optional(string)
    node_resource_group          = optional(string)
    edge_zone                    = optional(string)
    automatic_upgrade_channel    = optional(string)
    node_os_upgrade_channel      = optional(string)
    run_command_enabled          = optional(bool)
    tags                         = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key in keys(var.clusters) : !can(regex("\\.", key))
    ])
    error_message = "clusters map keys must not contain \".\" — keys are composed into node pool identifiers of the form \"<cluster_key>.<pool_key>\" and a dot would make outputs ambiguous and flattened keys collision-prone."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : length(cluster.name) > 0 && length(cluster.name) <= 63 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*$", cluster.name))
    ])
    error_message = "cluster name must be 1-63 characters starting with a letter or digit, letters/digits/hyphens/underscores only — the AKS managed cluster name limit, plus location and resource_group_name must be non-empty."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters :
      (cluster.dns_prefix == null || length(trimspace(cluster.dns_prefix)) == 0) !=
      (cluster.dns_prefix_private_cluster == null || length(trimspace(cluster.dns_prefix_private_cluster)) == 0)
    ])
    error_message = "exactly one of dns_prefix or dns_prefix_private_cluster must be set — the Azure API accepts either, not both, not neither."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.dns_prefix == null || can(regex("^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,52})?[a-zA-Z0-9]|[a-zA-Z0-9])$", cluster.dns_prefix)
      )
    ])
    error_message = "dns_prefix must be 1-54 characters starting and ending with a letter or digit, letters/digits/hyphens only (Azure-enforced)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.dns_prefix_private_cluster == null || can(regex("^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,52})?[a-zA-Z0-9]|[a-zA-Z0-9])$", cluster.dns_prefix_private_cluster)
      )
    ])
    error_message = "dns_prefix_private_cluster must be 1-54 characters starting and ending with a letter or digit, letters/digits/hyphens only (Azure-enforced)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : contains(["Free", "Standard", "Premium"], cluster.sku_tier)
    ])
    error_message = "sku_tier must be one of Free, Standard or Premium (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : contains(["KubernetesOfficial", "AKSLongTermSupport"], cluster.support_plan)
    ])
    error_message = "support_plan must be one of KubernetesOfficial or AKSLongTermSupport (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.node_provisioning_profile == null || (
        (cluster.node_provisioning_profile.mode == null || contains(["Auto", "Manual"], cluster.node_provisioning_profile.mode)) &&
        (cluster.node_provisioning_profile.default_node_pools == null || contains(["Auto", "None"], cluster.node_provisioning_profile.default_node_pools))
      )
    ])
    error_message = "node_provisioning_profile mode must be Auto or Manual, default_node_pools Auto or None (case-sensitive), and at least one of the two must be set (Azure rejects the block otherwise)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : (cluster.identity != null) != (cluster.service_principal != null)
    ])
    error_message = "exactly one of identity or service_principal must be set — the provider requires either a managed identity block or a service principal, not both, not neither (service_principal is deprecated by Azure)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.identity == null || contains(["SystemAssigned", "UserAssigned"], cluster.identity.type)
    ])
    error_message = "identity.type must be one of SystemAssigned or UserAssigned (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.identity == null || cluster.identity.type != "UserAssigned" || length(coalesce(cluster.identity.identity_ids, [])) == 1
    ])
    error_message = "identity with type UserAssigned requires exactly one identity ID (only one user-assigned identity is supported per cluster) — pair with the azure/managed-identity module."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.default_node_pool.auto_scaling_enabled ? (cluster.default_node_pool.min_count != null && cluster.default_node_pool.max_count != null) : (cluster.default_node_pool.min_count == null && cluster.default_node_pool.max_count == null)
    ])
    error_message = "default_node_pool with auto_scaling_enabled requires min_count and max_count; with autoscaling disabled both must be null (Azure rejects the mixed configurations)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || contains(["azure", "kubenet", "none"], cluster.network_profile.network_plugin)
    ])
    error_message = "network_profile.network_plugin must be one of azure, kubenet or none (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.network_policy == null || contains(["calico", "azure", "cilium"], cluster.network_profile.network_policy)
    ])
    error_message = "network_profile.network_policy must be one of calico, azure or cilium (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.network_policy != "azure" || cluster.network_profile.network_plugin == "azure"
    ])
    error_message = "network_policy azure requires network_plugin azure."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.network_policy != "cilium" || cluster.network_profile.network_data_plane == "cilium"
    ])
    error_message = "network_policy cilium requires network_data_plane cilium."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.network_data_plane == null || contains(["azure", "cilium"], cluster.network_profile.network_data_plane)
    ])
    error_message = "network_profile.network_data_plane must be one of azure or cilium (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.network_data_plane != "cilium" || (cluster.network_profile.network_plugin == "azure" && (cluster.network_profile.network_plugin_mode == "overlay" || cluster.default_node_pool.pod_subnet_id != null))
    ])
    error_message = "network_data_plane cilium requires network_plugin azure and either network_plugin_mode overlay or a pod subnet on the default node pool."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.pod_cidr == null || cluster.network_profile.network_plugin == "kubenet" || cluster.network_profile.network_plugin_mode == "overlay"
    ])
    error_message = "network_profile.pod_cidr can only be set with network_plugin kubenet or network_plugin_mode overlay."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.outbound_type == null || contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway", "none"], cluster.network_profile.outbound_type)
    ])
    error_message = "network_profile.outbound_type must be one of loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway or none (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.load_balancer_profile == null || cluster.network_profile.load_balancer_sku == "standard"
    ])
    error_message = "network_profile.load_balancer_profile can only be set with load_balancer_sku standard."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.nat_gateway_profile == null || (cluster.network_profile.load_balancer_sku == "standard" && contains(["managedNATGateway", "userAssignedNATGateway"], coalesce(cluster.network_profile.outbound_type, "loadBalancer")))
    ])
    error_message = "network_profile.nat_gateway_profile can only be set with load_balancer_sku standard and outbound_type managedNATGateway or userAssignedNATGateway."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.load_balancer_profile == null || length([
        for source in [
          cluster.network_profile.load_balancer_profile.managed_outbound_ip_count,
          cluster.network_profile.load_balancer_profile.outbound_ip_address_ids,
          cluster.network_profile.load_balancer_profile.outbound_ip_prefix_ids,
        ] : source != null
      ]) == 1
    ])
    error_message = "network_profile.load_balancer_profile needs exactly one of managed_outbound_ip_count, outbound_ip_address_ids or outbound_ip_prefix_ids — the fields are mutually exclusive and at least one bounds the outbound pool."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.network_profile == null || cluster.network_profile.load_balancer_profile == null || cluster.network_profile.load_balancer_profile.idle_timeout_in_minutes == null || (cluster.network_profile.load_balancer_profile.idle_timeout_in_minutes >= 4 && cluster.network_profile.load_balancer_profile.idle_timeout_in_minutes <= 100)
    ])
    error_message = "network_profile.load_balancer_profile.idle_timeout_in_minutes must be between 4 and 100 inclusive."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : !cluster.workload_identity_enabled || (cluster.oidc_issuer_enabled != null ? cluster.oidc_issuer_enabled : true)
    ])
    error_message = "workload_identity_enabled requires oidc_issuer_enabled to be true (or omitted, which enables the OIDC issuer by default)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : !contains([true], cluster.cost_analysis_enabled != null && cluster.cost_analysis_enabled) || contains(["Standard", "Premium"], cluster.sku_tier)
    ])
    error_message = "cost_analysis_enabled requires sku_tier Standard or Premium."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.maintenance_window_auto_upgrade == null || (cluster.maintenance_window_auto_upgrade.duration >= 4 && cluster.maintenance_window_auto_upgrade.duration <= 24)
    ])
    error_message = "maintenance_window_auto_upgrade.duration must be between 4 and 24 hours."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.maintenance_window_node_os == null || (cluster.maintenance_window_node_os.duration >= 4 && cluster.maintenance_window_node_os.duration <= 24)
    ])
    error_message = "maintenance_window_node_os.duration must be between 4 and 24 hours."
  }

  validation {
    condition = alltrue(flatten([
      for cluster in var.clusters : [
        for window in concat(cluster.maintenance_window_auto_upgrade != null ? [cluster.maintenance_window_auto_upgrade] : [], cluster.maintenance_window_node_os != null ? [cluster.maintenance_window_node_os] : []) :
        contains(["Daily", "Weekly", "AbsoluteMonthly", "RelativeMonthly"], window.frequency)
      ]
    ]))
    error_message = "maintenance window frequency must be one of Daily, Weekly, AbsoluteMonthly or RelativeMonthly (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.automatic_upgrade_channel == null || contains(["patch", "rapid", "node-image", "stable"], cluster.automatic_upgrade_channel)
    ])
    error_message = "automatic_upgrade_channel must be one of patch, rapid, node-image or stable (case-sensitive, lowercase)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.node_os_upgrade_channel == null || contains(["Unmanaged", "SecurityPatch", "NodeImage", "None"], cluster.node_os_upgrade_channel)
    ])
    error_message = "node_os_upgrade_channel must be one of Unmanaged, SecurityPatch, NodeImage or None (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.key_management_service == null || contains(["Public", "Private"], coalesce(cluster.key_management_service.key_vault_network_access, "Public"))
    ])
    error_message = "key_management_service.key_vault_network_access must be one of Public or Private (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.private_dns_zone_id == null || cluster.private_dns_zone_id == "System" || cluster.private_dns_zone_id == "None" || can(regex("^/subscriptions/", cluster.private_dns_zone_id))
    ])
    error_message = "private_dns_zone_id must be the literal System, the literal None, or a full ARM private DNS zone resource ID (starts with \"/subscriptions/\")."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : cluster.default_node_pool.upgrade_settings == null || length(trimspace(coalesce(cluster.default_node_pool.upgrade_settings.max_surge, ""))) > 0
    ])
    error_message = "default_node_pool upgrade_settings.max_surge is required — a number or percentage of nodes added during surge upgrades."
  }

  validation {
    condition = alltrue([
      for cluster in var.clusters : length(cluster.tags) <= 50 && alltrue([for k, v in cluster.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "cluster tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "node_pools" {
  description = "Map of additional AKS node pools keyed by an arbitrary identifier. Each entry creates one azurerm_kubernetes_cluster_node_pool attached to the cluster identified by cluster_key. Target cluster keys must reference keys of the clusters variable."
  type = map(object({
    cluster_key                 = string
    name                        = string
    vm_size                     = string
    mode                        = optional(string, "User")
    os_type                     = optional(string, "Linux")
    os_sku                      = optional(string)
    node_count                  = optional(number)
    auto_scaling_enabled        = optional(bool, false)
    min_count                   = optional(number)
    max_count                   = optional(number)
    max_pods                    = optional(number)
    os_disk_size_gb             = optional(number)
    os_disk_type                = optional(string, "Managed")
    vnet_subnet_id              = optional(string)
    pod_subnet_id               = optional(string)
    zones                       = optional(list(string), [])
    node_labels                 = optional(map(string), {})
    node_taints                 = optional(list(string), [])
    priority                    = optional(string, "Regular")
    spot_max_price              = optional(number)
    eviction_policy             = optional(string)
    scale_down_mode             = optional(string, "Delete")
    orchestrator_version        = optional(string)
    fips_enabled                = optional(bool, false)
    host_encryption_enabled     = optional(bool, false)
    node_public_ip_enabled      = optional(bool, false)
    ultra_ssd_enabled           = optional(bool, false)
    kubelet_disk_type           = optional(string)
    temporary_name_for_rotation = optional(string)
    upgrade_settings = optional(object({
      max_surge                     = optional(string)
      max_unavailable               = optional(string)
      drain_timeout_in_minutes      = optional(number)
      node_soak_duration_in_minutes = optional(number)
    }))
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key in keys(var.node_pools) : !can(regex("\\.", key))
    ])
    error_message = "node_pools map keys must not contain \".\" — keys are composed into resource identifiers of the form \"<cluster_key>.<pool_key>\"."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : contains(keys(var.clusters), pool.cluster_key)
    ])
    error_message = "node_pools cluster_key must reference an existing clusters map key — pools bind to azurerm_kubernetes_cluster resources by key."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : length(pool.name) >= 1 && length(pool.name) <= 12 && can(regex("^[a-z][a-z0-9-]{0,11}$", pool.name)) && !can(regex("-$", pool.name))
    ])
    error_message = "node pool name must be 1-12 lowercase alphanumeric characters starting with a letter, ending with a letter or digit (hyphens allowed in between, not at the edges)."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : pool.os_type != "Windows" || length(pool.name) <= 6
    ])
    error_message = "Windows node pool names are limited to 6 characters — the AKS Windows agent pool name lengths rule."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : contains(["System", "User"], pool.mode)
    ])
    error_message = "node pool mode must be one of System or User (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : contains(["Linux", "Windows"], pool.os_type)
    ])
    error_message = "node pool os_type must be one of Linux or Windows (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : contains(["Regular", "Spot"], pool.priority)
    ])
    error_message = "node pool priority must be one of Regular or Spot (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : pool.priority != "Regular" || (pool.spot_max_price == null && pool.eviction_policy == null)
    ])
    error_message = "spot_max_price and eviction_policy only apply to spot node pools (priority Spot) — the API rejects them on Regular pools."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : pool.eviction_policy == null || contains(["Deallocate", "Delete"], pool.eviction_policy)
    ])
    error_message = "node pool eviction_policy must be one of Deallocate or Delete (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for pool in var.node_pools : pool.auto_scaling_enabled ? [pool.min_count != null && pool.max_count != null && pool.min_count <= pool.max_count] : [true]
    ]))
    error_message = "node pools with auto_scaling_enabled require min_count <= max_count; with autoscaling disabled both must be null."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : pool.auto_scaling_enabled || (pool.min_count == null && pool.max_count == null)
    ])
    error_message = "node pools with auto_scaling_enabled disabled must leave min_count and max_count null (Azure rejects the mixed configurations)."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : pool.upgrade_settings == null || pool.upgrade_settings.drain_timeout_in_minutes == null || (pool.upgrade_settings.drain_timeout_in_minutes >= 0 && pool.upgrade_settings.drain_timeout_in_minutes <= 1440)
    ])
    error_message = "upgrade_settings.drain_timeout_in_minutes must be between 0 and 1440 minutes (one day)."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : length(pool.tags) <= 50 && alltrue([for k, v in pool.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "node pool tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
