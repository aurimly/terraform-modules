variable "clusters" {
  description = "Map of GKE clusters keyed by an arbitrary identifier. Each entry creates one google_container_cluster plus optional node pools and backup plans."
  type = map(object({
    name                      = string
    location                  = string
    project_id                = optional(string)
    description               = optional(string)
    deletion_protection       = optional(bool)
    enable_autopilot          = optional(bool)
    resource_labels           = optional(map(string))
    default_max_pods_per_node = optional(number)
    min_master_version        = optional(string)
    release_channel = optional(object({
      channel = string
    }))
    gateway_api_channel = optional(string)
    workload_identity   = optional(bool)
    daily_maintenance_window = optional(object({
      start_time = string
    }))
    recurring_maintenance_window = optional(object({
      start_time = string
      end_time   = string
      recurrence = string
    }))
    network    = optional(string)
    subnetwork = optional(string)
    ip_allocation_policy = optional(object({
      cluster_secondary_range_name  = optional(string)
      services_secondary_range_name = optional(string)
    }))
    master_authorized_networks_config = optional(object({
      cidr_blocks = optional(list(object({
        cidr_block   = string
        display_name = optional(string)
      })), [])
    }))
    private_cluster_config = optional(object({
      enable_private_nodes    = optional(bool)
      enable_private_endpoint = optional(bool)
      master_ipv4_cidr_block  = optional(string)
      master_global_access_config = optional(object({
        enabled = optional(bool)
      }))
    }))
    network_policy = optional(object({
      enabled  = optional(bool)
      provider = optional(string)
    }))
    addons_config = optional(object({
      horizontal_pod_autoscaling = optional(object({
        disabled = optional(bool)
      }))
      http_load_balancing = optional(object({
        disabled = optional(bool)
      }))
      gcs_fuse_csi_driver_config = optional(object({
        enabled = optional(bool)
      }))
      gcp_filestore_csi_driver_config = optional(object({
        enabled = optional(bool)
      }))
      gke_backup_agent_config = optional(object({
        enabled = optional(bool)
      }))
    }))
    vertical_pod_autoscaling = optional(object({
      enabled = bool
    }))
    datapath_provider                        = optional(string)
    enable_shielded_nodes                    = optional(bool)
    enable_intranode_visibility              = optional(bool)
    enable_l4_ilb_subsetting                 = optional(bool)
    enable_fqdn_network_policy               = optional(bool)
    enable_multi_networking                  = optional(bool)
    enable_cilium_clusterwide_network_policy = optional(bool)
    disable_l4_lb_firewall_reconciliation    = optional(bool)
    logging_service                          = optional(string)
    logging_config = optional(object({
      enable_components = list(string)
    }))
    monitoring_service = optional(string)
    monitoring_config = optional(object({
      enable_components = optional(list(string))
      managed_prometheus = optional(object({
        enabled = bool
      }))
      advanced_datapath_observability_config = optional(object({
        enable_metrics = optional(bool)
        enable_relay   = optional(bool)
      }))
    }))
    dns_config = optional(object({
      cluster_dns                   = optional(string)
      cluster_dns_scope             = optional(string)
      cluster_dns_domain            = optional(string)
      additive_vpc_scope_dns_domain = optional(string)
    }))
    security_posture_config = optional(object({
      mode               = optional(string)
      vulnerability_mode = optional(string)
    }))
    binary_authorization = optional(object({
      evaluation_mode = string
    }))
    confidential_nodes = optional(object({
      enabled = bool
    }))
    service_external_ips_config = optional(object({
      enabled = bool
    }))
    authenticator_groups_config = optional(object({
      security_group = string
    }))
    notification_config = optional(object({
      pubsub = object({
        enabled = bool
        topic   = optional(string)
        filter = optional(object({
          event_type = optional(list(string))
        }))
      })
    }))
    cost_management_config = optional(object({
      enabled = bool
    }))
    database_encryption = optional(object({
      state    = string
      key_name = optional(string)
    }))
    resource_usage_export_config = optional(object({
      enable_network_egress_metering       = optional(bool)
      enable_resource_consumption_metering = optional(bool)
      bigquery_destination = object({
        dataset_id = string
      })
    }))
    node_pool_auto_config = optional(object({
      network_tags = optional(object({
        tags = optional(list(string))
      }))
      resource_manager_tags = optional(map(string))
      node_kubelet_config = optional(object({
        insecure_kubelet_readonly_port_enabled = optional(string)
      }))
      linux_node_config = optional(object({
        cgroup_mode = optional(string)
      }))
    }))
    node_pool_defaults = optional(object({
      node_config_defaults = optional(object({
        insecure_kubelet_readonly_port_enabled = optional(string)
        logging_variant                        = optional(string)
        gcfs_config = optional(object({
          enabled = bool
        }))
      }))
    }))
    cluster_autoscaling = optional(object({
      enabled = bool
      resource_limits = optional(list(object({
        resource_type = string
        minimum       = optional(number)
        maximum       = optional(number)
      })), [])
      auto_provisioning_defaults = optional(object({
        service_account = optional(string)
      }))
    }))
    secret_manager_config = optional(object({
      enabled = optional(bool, true)
      rotation_config = optional(object({
        enabled           = optional(bool, true)
        rotation_interval = optional(string, "120s")
      }))
    }))
    fleet = optional(object({
      project = optional(string)
    }))
    control_plane_endpoints_config = optional(object({
      dns_endpoint_config = optional(object({
        allow_external_traffic = optional(bool)
      }))
    }))
    node_pools = optional(list(object({
      name              = string
      node_count        = optional(number)
      node_locations    = optional(list(string))
      max_pods_per_node = optional(number)
      autoscaling = optional(object({
        min_node_count       = optional(number)
        max_node_count       = optional(number)
        total_min_node_count = optional(number)
        total_max_node_count = optional(number)
        location_policy      = optional(string)
      }))
      management = optional(object({
        auto_repair  = optional(bool)
        auto_upgrade = optional(bool)
      }))
      upgrade_settings = optional(object({
        max_surge       = number
        max_unavailable = number
      }))
      node_config = optional(object({
        image_type       = optional(string)
        machine_type     = optional(string)
        min_cpu_platform = optional(string)
        disk_size_gb     = optional(number)
        disk_type        = optional(string)
        preemptible      = optional(bool)
        spot             = optional(bool)
        service_account  = optional(string)
        oauth_scopes     = optional(list(string))
        tags             = optional(list(string))
        labels           = optional(map(string))
        metadata         = optional(map(string))
        taints = optional(list(object({
          key    = string
          value  = string
          effect = string
        })), [])
        shielded_instance_config = optional(object({
          enable_secure_boot          = optional(bool)
          enable_integrity_monitoring = optional(bool)
        }))
        workload_metadata_config = optional(object({
          mode = string
        }))
        guest_accelerators = optional(list(object({
          type               = string
          count              = number
          gpu_partition_size = optional(string)
          gpu_driver_installation_config = optional(object({
            gpu_driver_version = string
          }))
          gpu_sharing_config = optional(object({
            gpu_sharing_strategy       = string
            max_shared_clients_per_gpu = optional(number)
          }))
        })), [])
      }))
    })), [])
    backup_plans = optional(list(object({
      name        = string
      description = optional(string)
      deactivated = optional(bool)
      labels      = optional(map(string))
      retention_policy = optional(object({
        backup_delete_lock_days = optional(number)
        backup_retain_days      = optional(number)
        locked                  = optional(bool)
      }))
      backup_schedule = optional(object({
        cron_schedule = optional(string)
        paused        = optional(bool)
        rpo_config = optional(object({
          target_rpo_minutes = number
          exclusion_windows = optional(list(object({
            duration = string
            start_time = optional(object({
              hours   = optional(number)
              minutes = optional(number)
              seconds = optional(number)
              nanos   = optional(number)
            }))
            single_occurrence_date = optional(object({
              day   = optional(number)
              month = optional(number)
              year  = optional(number)
            }))
            days_of_week = optional(object({
              days_of_week = list(string)
            }))
          })), [])
        }))
      }))
      backup_config = optional(object({
        include_volume_data = optional(bool)
        include_secrets     = optional(bool)
        all_namespaces      = optional(bool)
        permissive_mode     = optional(bool)
        encryption_key = optional(object({
          gcp_kms_encryption_key = string
        }))
        selected_namespaces = optional(object({
          namespaces = list(string)
        }))
        selected_applications = optional(object({
          namespaced_names = list(object({
            name      = string
            namespace = string
          }))
        }))
      }))
    })), [])
  }))

  validation {
    condition     = alltrue([for k, c in var.clusters : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", c.name))])
    error_message = "clusters.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : can(regex("^[a-z]+-[a-z]+[0-9]+(-[a-z])?$", c.location))])
    error_message = "clusters.location must be a GCP region (e.g. us-central1) for a regional cluster or a zone (e.g. us-central1-a) for a zonal cluster."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", c.project_id))])
    error_message = "clusters.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : !c.workload_identity || c.project_id != null])
    error_message = "clusters.project_id is required when workload_identity is true; the workload pool ({project}.svc.id.goog) is built from it."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.min_master_version == null || c.release_channel == null])
    error_message = "clusters.min_master_version and clusters.release_channel are mutually exclusive; version pinning is incompatible with a release channel."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.release_channel == null || contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], c.release_channel.channel)])
    error_message = "clusters.release_channel.channel must be one of UNSPECIFIED, RAPID, REGULAR or STABLE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.gateway_api_channel == null || contains(["CHANNEL_STANDARD", "CHANNEL_DISABLED"], c.gateway_api_channel)])
    error_message = "clusters.gateway_api_channel must be CHANNEL_STANDARD or CHANNEL_DISABLED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.daily_maintenance_window == null || c.recurring_maintenance_window == null])
    error_message = "clusters.daily_maintenance_window and clusters.recurring_maintenance_window are mutually exclusive."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.daily_maintenance_window == null || can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", c.daily_maintenance_window.start_time))])
    error_message = "clusters.daily_maintenance_window.start_time must be in HH:MM format (e.g. 03:00), UTC."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.recurring_maintenance_window == null || (c.recurring_maintenance_window.start_time != "" && c.recurring_maintenance_window.end_time != "" && c.recurring_maintenance_window.recurrence != "")])
    error_message = "clusters.recurring_maintenance_window.start_time, end_time and recurrence must be non-empty; start_time and end_time are RFC3339 timestamps (e.g. 2099-01-01T00:00:00Z), recurrence is an RFC5545 RRULE (e.g. FREQ=WEEKLY;BYDAY=SA,SU)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.datapath_provider == null || contains(["LEGACY_DATAPATH", "ADVANCED_DATAPATH"], c.datapath_provider)])
    error_message = "clusters.datapath_provider must be LEGACY_DATAPATH or ADVANCED_DATAPATH (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : !(c.datapath_provider == "ADVANCED_DATAPATH" && c.network_policy != null)])
    error_message = "clusters.network_policy must not be set when datapath_provider is ADVANCED_DATAPATH; Dataplane V2 uses Cilium for network policy enforcement."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : !(c.enable_fqdn_network_policy == true && c.datapath_provider != "ADVANCED_DATAPATH")])
    error_message = "clusters.enable_fqdn_network_policy = true requires datapath_provider = ADVANCED_DATAPATH."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.enable_autopilot != true || length(c.node_pools) == 0])
    error_message = "clusters.node_pools must be empty when enable_autopilot is true; autopilot manages all node pools itself."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.network_policy == null || c.network_policy.provider == null || contains(["PROVIDER_UNSPECIFIED", "CALICO"], c.network_policy.provider)])
    error_message = "clusters.network_policy.provider must be PROVIDER_UNSPECIFIED or CALICO (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.logging_config == null || c.logging_service == null])
    error_message = "clusters.logging_config and clusters.logging_service are mutually exclusive; prefer logging_config."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.monitoring_config == null || c.monitoring_service == null])
    error_message = "clusters.monitoring_config and clusters.monitoring_service are mutually exclusive; prefer monitoring_config."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.master_authorized_networks_config == null || alltrue([for b in c.master_authorized_networks_config.cidr_blocks : can(cidrnetmask(b.cidr_block))])])
    error_message = "clusters.master_authorized_networks_config.cidr_blocks[].cidr_block must be a valid IPv4 CIDR (e.g. 10.0.0.0/8)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.private_cluster_config == null || !(c.private_cluster_config.enable_private_nodes == true && (c.private_cluster_config.master_ipv4_cidr_block == null || !can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/28$", c.private_cluster_config.master_ipv4_cidr_block))))])
    error_message = "clusters.private_cluster_config.master_ipv4_cidr_block is required (a /28 CIDR, e.g. 172.16.0.0/28) when enable_private_nodes is true."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.private_cluster_config == null || !(c.private_cluster_config.enable_private_endpoint == true && c.private_cluster_config.enable_private_nodes != true)])
    error_message = "clusters.private_cluster_config.enable_private_endpoint = true requires enable_private_nodes = true."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.dns_config == null || (c.dns_config.cluster_dns == null || contains(["PROVIDER_UNSPECIFIED", "PLATFORM_DEFAULT", "CLOUD_DNS", "KUBE_DNS"], c.dns_config.cluster_dns)) && (c.dns_config.cluster_dns_scope == null || contains(["DNS_SCOPE_UNSPECIFIED", "CLUSTER_SCOPE", "VPC_SCOPE"], c.dns_config.cluster_dns_scope))])
    error_message = "clusters.dns_config.cluster_dns must be one of PROVIDER_UNSPECIFIED, PLATFORM_DEFAULT, CLOUD_DNS or KUBE_DNS; cluster_dns_scope must be one of DNS_SCOPE_UNSPECIFIED, CLUSTER_SCOPE or VPC_SCOPE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.security_posture_config == null || (c.security_posture_config.mode == null || contains(["DISABLED", "BASIC", "ENTERPRISE"], c.security_posture_config.mode)) && (c.security_posture_config.vulnerability_mode == null || contains(["VULNERABILITY_DISABLED", "VULNERABILITY_BASIC", "VULNERABILITY_ENTERPRISE"], c.security_posture_config.vulnerability_mode))])
    error_message = "clusters.security_posture_config.mode must be one of DISABLED, BASIC or ENTERPRISE; vulnerability_mode must be one of VULNERABILITY_DISABLED, VULNERABILITY_BASIC or VULNERABILITY_ENTERPRISE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.binary_authorization == null || contains(["DISABLED", "PROJECT_SINGLETON_POLICY_ENFORCE"], c.binary_authorization.evaluation_mode)])
    error_message = "clusters.binary_authorization.evaluation_mode must be DISABLED or PROJECT_SINGLETON_POLICY_ENFORCE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.database_encryption == null || contains(["ENCRYPTED", "DECRYPTED"], c.database_encryption.state)])
    error_message = "clusters.database_encryption.state must be ENCRYPTED or DECRYPTED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.notification_config == null || c.notification_config.pubsub.filter == null || c.notification_config.pubsub.filter.event_type == null || alltrue([for e in c.notification_config.pubsub.filter.event_type : contains(["UPGRADE_AVAILABLE_EVENT", "UPGRADE_EVENT", "SECURITY_BULLETIN_EVENT", "UPGRADE_INFO_EVENT"], e)])])
    error_message = "clusters.notification_config.pubsub.filter.event_type entries must be one of UPGRADE_AVAILABLE_EVENT, UPGRADE_EVENT, SECURITY_BULLETIN_EVENT or UPGRADE_INFO_EVENT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.node_pool_defaults == null || c.node_pool_defaults.node_config_defaults == null || c.node_pool_defaults.node_config_defaults.logging_variant == null || contains(["DEFAULT", "MAX_THROUGHPUT"], c.node_pool_defaults.node_config_defaults.logging_variant)])
    error_message = "clusters.node_pool_defaults.node_config_defaults.logging_variant must be DEFAULT or MAX_THROUGHPUT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : (c.node_pool_auto_config == null || c.node_pool_auto_config.node_kubelet_config == null || c.node_pool_auto_config.node_kubelet_config.insecure_kubelet_readonly_port_enabled == null || contains(["TRUE", "FALSE"], c.node_pool_auto_config.node_kubelet_config.insecure_kubelet_readonly_port_enabled)) && (c.node_pool_defaults == null || c.node_pool_defaults.node_config_defaults == null || c.node_pool_defaults.node_config_defaults.insecure_kubelet_readonly_port_enabled == null || contains(["TRUE", "FALSE"], c.node_pool_defaults.node_config_defaults.insecure_kubelet_readonly_port_enabled))])
    error_message = "insecure_kubelet_readonly_port_enabled fields (node_pool_auto_config.node_kubelet_config and node_pool_defaults.node_config_defaults) must be the strings TRUE or FALSE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : c.cluster_autoscaling == null || alltrue([for r in c.cluster_autoscaling.resource_limits : r.resource_type != ""])])
    error_message = "clusters.cluster_autoscaling.resource_limits[].resource_type must be non-empty (e.g. cpu, memory)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])])
    error_message = "clusters.node_pools[].name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : length(distinct([for p in c.node_pools : p.name])) == length(c.node_pools)])
    error_message = "clusters.node_pools[].name must be unique within a cluster entry; node pool keys are built as <cluster_key>/<pool_name>."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : (p.autoscaling != null && p.node_count == null) || (p.autoscaling == null && p.node_count != null && p.node_count >= 1)])])
    error_message = "clusters.node_pools[]: exactly one of node_count (>= 1) or autoscaling must be set; zero-size pools are only valid with autoscaling."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : p.node_locations == null || alltrue([for z in p.node_locations : can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", z))])])])
    error_message = "clusters.node_pools[].node_locations entries must be GCP zones (e.g. us-central1-a)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : p.autoscaling == null || (contains(["BALANCED", "ANY"], coalesce(p.autoscaling.location_policy, "BALANCED"))) && ((p.autoscaling.min_node_count == null && p.autoscaling.max_node_count == null) || (p.autoscaling.total_min_node_count == null && p.autoscaling.total_max_node_count == null)) && (p.autoscaling.min_node_count == null || p.autoscaling.max_node_count == null || p.autoscaling.min_node_count <= p.autoscaling.max_node_count) && (p.autoscaling.total_min_node_count == null || p.autoscaling.total_max_node_count == null || p.autoscaling.total_min_node_count <= p.autoscaling.total_max_node_count)])])
    error_message = "clusters.node_pools[].autoscaling: use per-zone limits (min_node_count/max_node_count) or total limits (total_min_node_count/total_max_node_count), not both; min must be <= max; location_policy must be BALANCED or ANY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : p.upgrade_settings == null || (p.upgrade_settings.max_surge >= 0 && p.upgrade_settings.max_unavailable >= 0)])])
    error_message = "clusters.node_pools[].upgrade_settings.max_surge and max_unavailable must be >= 0."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : p.node_config == null || !(p.node_config.spot == true && p.node_config.preemptible == true)])])
    error_message = "clusters.node_pools[].node_config: spot and preemptible are mutually exclusive; use spot for Spot VMs."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : p.node_config == null || p.node_config.oauth_scopes == null || length(p.node_config.oauth_scopes) > 0])])
    error_message = "clusters.node_pools[].node_config.oauth_scopes must contain at least one scope when set (e.g. [\"https://www.googleapis.com/auth/cloud-platform\"])."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : p.node_config == null || alltrue([for t in p.node_config.taints : contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], t.effect)])])])
    error_message = "clusters.node_pools[].node_config.taints[].effect must be one of NO_SCHEDULE, PREFER_NO_SCHEDULE or NO_EXECUTE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : p.node_config == null || p.node_config.workload_metadata_config == null || contains(["GCE_METADATA", "GKE_METADATA"], p.node_config.workload_metadata_config.mode)])])
    error_message = "clusters.node_pools[].node_config.workload_metadata_config.mode must be GCE_METADATA or GKE_METADATA (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for p in c.node_pools : p.node_config == null || alltrue([for g in p.node_config.guest_accelerators : (g.count >= 1) && (g.gpu_driver_installation_config == null || contains(["DEFAULT", "LATEST"], g.gpu_driver_installation_config.gpu_driver_version)) && (g.gpu_sharing_config == null || contains(["TIME_SHARING", "MPS"], g.gpu_sharing_config.gpu_sharing_strategy))])])])
    error_message = "clusters.node_pools[].node_config.guest_accelerators[]: count must be >= 1, gpu_driver_installation_config.gpu_driver_version must be DEFAULT or LATEST, and gpu_sharing_config.gpu_sharing_strategy must be TIME_SHARING or MPS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for b in c.backup_plans : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", b.name))])])
    error_message = "clusters.backup_plans[].name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : length(distinct([for b in c.backup_plans : b.name])) == length(c.backup_plans)])
    error_message = "clusters.backup_plans[].name must be unique within a cluster entry; backup plan keys are built as <cluster_key>/<plan_name>."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for b in c.backup_plans : b.retention_policy == null || (b.retention_policy.backup_delete_lock_days == null || (b.retention_policy.backup_delete_lock_days >= 0 && b.retention_policy.backup_delete_lock_days <= 90)) && (b.retention_policy.backup_retain_days == null || (b.retention_policy.backup_retain_days >= 0 && b.retention_policy.backup_retain_days <= 365)) && (b.retention_policy.backup_delete_lock_days == null || b.retention_policy.backup_retain_days == null || b.retention_policy.backup_delete_lock_days <= b.retention_policy.backup_retain_days)])])
    error_message = "clusters.backup_plans[].retention_policy: backup_delete_lock_days must be 0-90, backup_retain_days must be 0-365 and backup_delete_lock_days must not exceed backup_retain_days."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for b in c.backup_plans : b.backup_schedule == null || (b.backup_schedule.cron_schedule == null) != (b.backup_schedule.rpo_config == null)])])
    error_message = "clusters.backup_plans[].backup_schedule: exactly one of cron_schedule or rpo_config must be set."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for b in c.backup_plans : b.backup_schedule == null || b.backup_schedule.rpo_config == null || (b.backup_schedule.rpo_config.target_rpo_minutes >= 60 && b.backup_schedule.rpo_config.target_rpo_minutes <= 86400) && alltrue([for w in b.backup_schedule.rpo_config.exclusion_windows : w.duration != ""])])])
    error_message = "clusters.backup_plans[].backup_schedule.rpo_config: target_rpo_minutes must be 60-86400 and exclusion_windows[].duration must be non-empty (e.g. 3600s)."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for b in c.backup_plans : b.backup_config == null || length(compact([b.backup_config.all_namespaces == true ? "a" : "", b.backup_config.selected_namespaces != null ? "s" : "", b.backup_config.selected_applications != null ? "p" : ""])) == 1])])
    error_message = "clusters.backup_plans[].backup_config: exactly one of all_namespaces, selected_namespaces or selected_applications must be set."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for b in c.backup_plans : b.backup_config == null || b.backup_config.selected_namespaces == null || length(b.backup_config.selected_namespaces.namespaces) > 0])])
    error_message = "clusters.backup_plans[].backup_config.selected_namespaces.namespaces must contain at least one namespace."
  }

  validation {
    condition     = alltrue([for k, c in var.clusters : alltrue([for b in c.backup_plans : b.backup_config == null || b.backup_config.selected_applications == null || alltrue([for n in b.backup_config.selected_applications.namespaced_names : n.name != "" && n.namespace != ""])])])
    error_message = "clusters.backup_plans[].backup_config.selected_applications.namespaced_names entries must have both name and namespace set."
  }
}
