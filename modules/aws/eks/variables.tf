variable "clusters" {
  description = "Map of EKS clusters keyed by an arbitrary identifier. Each entry creates one aws_eks_cluster plus an optional aws_iam_openid_connect_provider for IRSA. Stock cluster and node group roles are pass-through (pair with the aws/iam-role module)."
  type = map(object({
    name                          = string
    role_arn                      = string
    version                       = optional(string)
    enabled_cluster_log_types     = optional(list(string), [])
    deletion_protection           = optional(bool)
    force_update_version          = optional(bool)
    bootstrap_self_managed_addons = optional(bool)
    create_oidc_provider          = optional(bool, false)
    oidc_client_id_list           = optional(list(string), ["sts.amazonaws.com"])
    oidc_thumbprint_list          = optional(list(string))
    access_config = optional(object({
      authentication_mode                         = optional(string)
      bootstrap_cluster_creator_admin_permissions = optional(bool)
    }))
    encryption_config = optional(object({
      resources = list(string)
      key_arn   = string
    }))
    kubernetes_network_config = optional(object({
      ip_family         = optional(string)
      service_ipv4_cidr = optional(string)
      elastic_load_balancing = optional(object({
        enabled = optional(bool)
      }))
    }))
    compute_config = optional(object({
      enabled       = optional(bool)
      node_pools    = optional(list(string))
      node_role_arn = optional(string)
    }))
    storage_config = optional(object({
      block_storage = optional(object({
        enabled = optional(bool)
      }))
    }))
    upgrade_policy = optional(object({
      support_type = optional(string)
    }))
    zonal_shift_config = optional(object({
      enabled = optional(bool)
    }))
    vpc_config = object({
      subnet_ids              = list(string)
      security_group_ids      = optional(list(string), [])
      endpoint_private_access = optional(bool)
      endpoint_public_access  = optional(bool)
      public_access_cidrs     = optional(list(string))
    })
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = length(var.clusters) == 0 || alltrue([for k in keys(var.clusters) : !can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\" — the dot character is reserved for the composite node group/addon/access entry keys."
  }

  validation {
    condition     = alltrue([for c in var.clusters : length(c.name) >= 1 && length(c.name) <= 100 && can(regex("^[0-9A-Za-z][A-Za-z0-9_-]*$", c.name))])
    error_message = "name must be 1-100 characters, starting with a letter or digit, containing only letters, digits, hyphens and underscores (EKS cluster naming rules)."
  }

  validation {
    condition = alltrue([
      for c in var.clusters : alltrue([
        for t in c.enabled_cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)
      ])
    ])
    error_message = "enabled_cluster_log_types entries must be one of api, audit, authenticator, controllerManager or scheduler (case-sensitive, EKS control plane logging types)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : length(c.vpc_config.subnet_ids) >= 2])
    error_message = "vpc_config.subnet_ids must contain at least two subnet IDs (EKS requires subnets spanning at least two availability zones)."
  }

  validation {
    condition = alltrue([
      for c in var.clusters : alltrue([
        for cidr in coalesce(c.vpc_config.public_access_cidrs, []) : can(cidrnetmask(cidr))
      ])
    ])
    error_message = "vpc_config.public_access_cidrs entries must be valid netmask CIDR notation (e.g. 10.0.0.0/16)."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.kubernetes_network_config == null || c.kubernetes_network_config.service_ipv4_cidr == null || can(cidrnetmask(c.kubernetes_network_config.service_ipv4_cidr))])
    error_message = "kubernetes_network_config.service_ipv4_cidr must be valid netmask CIDR notation."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.kubernetes_network_config == null || c.kubernetes_network_config.ip_family == null || contains(["ipv4", "ipv6"], c.kubernetes_network_config.ip_family)])
    error_message = "kubernetes_network_config.ip_family must be one of ipv4 or ipv6."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.access_config == null || c.access_config.authentication_mode == null || contains(["CONFIG_MAP", "API", "API_AND_CONFIG_MAP"], c.access_config.authentication_mode)])
    error_message = "access_config.authentication_mode must be one of CONFIG_MAP, API or API_AND_CONFIG_MAP."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.upgrade_policy == null || c.upgrade_policy.support_type == null || contains(["EXTENDED", "STANDARD"], c.upgrade_policy.support_type)])
    error_message = "upgrade_policy.support_type must be one of EXTENDED or STANDARD."
  }

  validation {
    condition     = alltrue([for c in var.clusters : c.encryption_config == null || length([for r in c.encryption_config.resources : r if r != "secrets"]) == 0])
    error_message = "encryption_config.resources entries must all be \"secrets\" (the only valid resource type for EKS envelope encryption)."
  }

  validation {
    condition = alltrue([
      for c in var.clusters :
      c.compute_config == null
      || c.compute_config.enabled != true
      || (
        c.bootstrap_self_managed_addons == false
        && coalesce(try(c.kubernetes_network_config.elastic_load_balancing.enabled, false), false)
        && coalesce(try(c.storage_config.block_storage.enabled, false), false)
      )
    ])
    error_message = "Auto Mode (compute_config.enabled = true) requires kubernetes_network_config.elastic_load_balancing.enabled = true, storage_config.block_storage.enabled = true and bootstrap_self_managed_addons = false (the EKS API rejects the mixed configuration)."
  }

  validation {
    condition = alltrue([
      for c in var.clusters :
      (c.compute_config != null && c.compute_config.enabled == true)
      || (!coalesce(try(c.kubernetes_network_config.elastic_load_balancing.enabled, false), false) && !coalesce(try(c.storage_config.block_storage.enabled, false), false))
    ])
    error_message = "kubernetes_network_config.elastic_load_balancing.enabled = true and storage_config.block_storage.enabled = true are Auto Mode capabilities — they require compute_config.enabled = true (the EKS API requires all three flags set together)."
  }

  validation {
    condition = alltrue([
      for c in var.clusters :
      c.compute_config == null
      || ((length(coalesce(c.compute_config.node_pools, [])) > 0) == (c.compute_config.node_role_arn != null))
    ])
    error_message = "compute_config: node_pools and node_role_arn must be set together — a non-empty node_pools list requires node_role_arn, and node_role_arn is only valid when node_pools is non-empty (an empty node_pools list disables the built-in node pools)."
  }

  validation {
    condition = alltrue([
      for c in var.clusters : alltrue([
        for p in coalesce(try(c.compute_config.node_pools, []), []) : contains(["general-purpose", "system"], p)
      ])
    ])
    error_message = "compute_config.node_pools entries must be one of general-purpose or system."
  }
}

variable "node_groups" {
  description = "Map of EKS managed node groups keyed by an arbitrary identifier. Each entry creates one aws_eks_node_group on the referenced cluster. Node group roles are pass-through (pair with the aws/iam-role module)."
  type = map(object({
    cluster_key          = string
    name                 = string
    node_role_arn        = string
    subnet_ids           = list(string)
    instance_types       = optional(list(string))
    ami_type             = optional(string)
    capacity_type        = optional(string)
    disk_size            = optional(number)
    labels               = optional(map(string), {})
    version              = optional(string)
    release_version      = optional(string)
    force_update_version = optional(bool)
    scaling_config = object({
      desired_size = number
      min_size     = number
      max_size     = number
    })
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    remote_access = optional(object({
      ec2_ssh_key               = optional(string)
      source_security_group_ids = optional(list(string), [])
    }))
    launch_template = optional(object({
      id      = optional(string)
      name    = optional(string)
      version = string
    }))
    update_config = optional(object({
      max_unavailable            = optional(number)
      max_unavailable_percentage = optional(number)
      update_strategy            = optional(string)
    }))
    node_repair_config = optional(object({
      enabled                                 = optional(bool)
      max_parallel_nodes_repaired_count       = optional(number)
      max_parallel_nodes_repaired_percentage  = optional(number)
      max_unhealthy_node_threshold_count      = optional(number)
      max_unhealthy_node_threshold_percentage = optional(number)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.node_groups) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\" — the dot character is reserved in the composite \"clusterKey.groupKey\" resource keys."
  }

  validation {
    condition     = alltrue([for g in var.node_groups : length(g.name) <= 63 && can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", g.name))])
    error_message = "name must be at most 63 characters, starting with a letter or digit, containing only letters, digits, hyphens and underscores (EKS node group naming rules)."
  }

  validation {
    condition     = alltrue([for g in var.node_groups : g.capacity_type == null || contains(["ON_DEMAND", "SPOT"], g.capacity_type)])
    error_message = "capacity_type must be one of ON_DEMAND or SPOT."
  }

  validation {
    condition     = alltrue([for g in var.node_groups : g.scaling_config.min_size <= g.scaling_config.desired_size && g.scaling_config.desired_size <= g.scaling_config.max_size])
    error_message = "scaling_config requires min_size <= desired_size <= max_size."
  }

  validation {
    condition = alltrue([
      for g in var.node_groups : alltrue([
        for t in g.taints : contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], t.effect)
      ])
    ])
    error_message = "taints effect must be one of NO_SCHEDULE, NO_EXECUTE or PREFER_NO_SCHEDULE."
  }

  validation {
    condition = alltrue([
      for g in var.node_groups : g.update_config == null
      || (
        (g.update_config.max_unavailable == null) != (g.update_config.max_unavailable_percentage == null)
        && (g.update_config.update_strategy == null || contains(["MINIMAL", "DEFAULT"], g.update_config.update_strategy))
      )
    ])
    error_message = "update_config requires exactly one of max_unavailable or max_unavailable_percentage (the EKS API rejects or misreads configurations where both or neither is set); update_strategy must be MINIMAL or DEFAULT."
  }

  validation {
    condition = alltrue([
      for g in var.node_groups : g.node_repair_config == null
      || ((g.node_repair_config.max_parallel_nodes_repaired_count == null) != (g.node_repair_config.max_parallel_nodes_repaired_percentage == null)
      && (g.node_repair_config.max_unhealthy_node_threshold_count == null) != (g.node_repair_config.max_unhealthy_node_threshold_percentage == null))
    ])
    error_message = "node_repair_config requires exactly one of max_parallel_nodes_repaired_count or max_parallel_nodes_repaired_percentage, and exactly one of max_unhealthy_node_threshold_count or max_unhealthy_node_threshold_percentage (the EKS API rejects both members of either pair together)."
  }

  validation {
    condition = alltrue([
      for g in var.node_groups :
      !((g.remote_access != null) && (g.launch_template != null))
      && (g.launch_template == null || ((g.launch_template.id != null) != (g.launch_template.name != null)))
    ])
    error_message = "launch_template conflicts with remote_access (the EKS API rejects both); launch_template requires exactly one of id or name, and always a version."
  }

  validation {
    condition     = length(var.node_groups) == length(distinct([for g in var.node_groups : "${g.cluster_key}.${g.name}"]))
    error_message = "Node group names must be unique within a cluster (the EKS API rejects a second node group with the same name on one cluster)."
  }
}

variable "addons" {
  description = "Map of EKS add-ons keyed by an arbitrary identifier. Each entry creates one aws_eks_addon on the referenced cluster."
  type = map(object({
    cluster_key                 = string
    addon_name                  = string
    addon_version               = optional(string)
    resolve_conflicts_on_create = optional(string)
    resolve_conflicts_on_update = optional(string)
    service_account_role_arn    = optional(string)
    preserve                    = optional(bool)
    configuration_values        = optional(string)
    pod_identity_association = optional(list(object({
      role_arn        = string
      service_account = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.addons) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\" — the dot character is reserved in the composite \"clusterKey.addonKey\" resource keys."
  }

  validation {
    condition     = alltrue([for a in var.addons : a.resolve_conflicts_on_create == null || contains(["NONE", "OVERWRITE"], a.resolve_conflicts_on_create)])
    error_message = "resolve_conflicts_on_create must be one of NONE or OVERWRITE."
  }

  validation {
    condition     = alltrue([for a in var.addons : a.resolve_conflicts_on_update == null || contains(["NONE", "OVERWRITE", "PRESERVE"], a.resolve_conflicts_on_update)])
    error_message = "resolve_conflicts_on_update must be one of NONE, OVERWRITE or PRESERVE."
  }

  validation {
    condition     = length(var.addons) == length(distinct([for a in var.addons : "${a.cluster_key}.${a.addon_name}"]))
    error_message = "Add-on names must be unique within a cluster (the EKS API rejects a second add-on with the same addon_name on one cluster)."
  }
}

variable "access_entries" {
  description = "Map of EKS access entries keyed by an arbitrary identifier. Each entry creates one aws_eks_access_entry on the referenced cluster, granting the principal cluster access."
  type = map(object({
    cluster_key       = string
    principal_arn     = string
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    kubernetes_groups = optional(list(string), [])
    tags              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.access_entries) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\" — the dot character is reserved in the composite \"clusterKey.entryKey\" resource keys."
  }

  validation {
    condition     = alltrue([for e in var.access_entries : contains(["STANDARD", "EC2_LINUX", "EC2_WINDOWS", "FARGATE_LINUX"], e.type)])
    error_message = "type must be one of STANDARD, EC2_LINUX, EC2_WINDOWS or FARGATE_LINUX."
  }

  validation {
    condition     = alltrue([for e in var.access_entries : e.type == "STANDARD" || (e.user_name == null && length(e.kubernetes_groups) == 0)])
    error_message = "user_name and kubernetes_groups can only be set on STANDARD access entries (the EKS API rejects them for EC2 or Fargate entries)."
  }

  validation {
    condition     = length(var.access_entries) == length(distinct([for e in var.access_entries : "${e.cluster_key}.${e.principal_arn}"]))
    error_message = "Principal ARNs must be unique within a cluster (the EKS API rejects a second access entry with the same principal_arn on one cluster)."
  }
}

variable "access_policy_associations" {
  description = "Map of EKS access policy associations keyed by an arbitrary identifier. Each entry associates one cluster access policy with a principal on the referenced cluster."
  type = map(object({
    cluster_key   = string
    principal_arn = string
    policy_arn    = string
    access_scope = object({
      type       = string
      namespaces = optional(list(string), [])
    })
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.access_policy_associations) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\" — the dot character is reserved in the composite \"clusterKey.assocKey\" resource keys."
  }

  validation {
    condition     = alltrue([for a in var.access_policy_associations : contains(["cluster", "namespace"], a.access_scope.type)])
    error_message = "access_scope.type must be one of cluster or namespace."
  }

  validation {
    condition     = alltrue([for a in var.access_policy_associations : a.access_scope.type != "namespace" || length(a.access_scope.namespaces) > 0])
    error_message = "access_scope.type = namespace requires at least one namespace in access_scope.namespaces (the EKS API rejects an empty namespace list with namespace scope)."
  }
}
