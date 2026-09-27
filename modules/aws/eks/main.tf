locals {
  node_groups = { for k, v in var.node_groups : "${v.cluster_key}.${k}" => v }

  addons = { for k, v in var.addons : "${v.cluster_key}.${k}" => v }

  access_entries = { for k, v in var.access_entries : "${v.cluster_key}.${k}" => v }

  access_policy_associations = { for k, v in var.access_policy_associations : "${v.cluster_key}.${k}" => v }

  oidc_provider_clusters = {
    for k, c in var.clusters : k => c
    if c.create_oidc_provider
  }
}

resource "aws_eks_cluster" "cluster" {
  for_each = var.clusters

  name                          = each.value.name
  role_arn                      = each.value.role_arn
  version                       = each.value.version
  deletion_protection           = each.value.deletion_protection
  force_update_version          = each.value.force_update_version
  bootstrap_self_managed_addons = each.value.bootstrap_self_managed_addons

  enabled_cluster_log_types = each.value.enabled_cluster_log_types

  dynamic "encryption_config" {
    for_each = each.value.encryption_config != null ? [each.value.encryption_config] : []

    content {
      resources = encryption_config.value.resources

      provider {
        key_arn = encryption_config.value.key_arn
      }
    }
  }

  dynamic "kubernetes_network_config" {
    for_each = each.value.kubernetes_network_config != null ? [each.value.kubernetes_network_config] : []

    content {
      ip_family         = kubernetes_network_config.value.ip_family
      service_ipv4_cidr = kubernetes_network_config.value.service_ipv4_cidr

      dynamic "elastic_load_balancing" {
        for_each = kubernetes_network_config.value.elastic_load_balancing != null ? [kubernetes_network_config.value.elastic_load_balancing] : []

        content {
          enabled = elastic_load_balancing.value.enabled
        }
      }
    }
  }

  dynamic "access_config" {
    for_each = each.value.access_config != null ? [each.value.access_config] : []

    content {
      authentication_mode                         = access_config.value.authentication_mode
      bootstrap_cluster_creator_admin_permissions = access_config.value.bootstrap_cluster_creator_admin_permissions
    }
  }

  dynamic "upgrade_policy" {
    for_each = each.value.upgrade_policy != null ? [each.value.upgrade_policy] : []

    content {
      support_type = upgrade_policy.value.support_type
    }
  }

  dynamic "zonal_shift_config" {
    for_each = each.value.zonal_shift_config != null ? [each.value.zonal_shift_config] : []

    content {
      enabled = zonal_shift_config.value.enabled
    }
  }

  dynamic "compute_config" {
    for_each = each.value.compute_config != null ? [each.value.compute_config] : []

    content {
      enabled       = compute_config.value.enabled
      node_pools    = compute_config.value.node_pools
      node_role_arn = compute_config.value.node_role_arn
    }
  }

  dynamic "storage_config" {
    for_each = each.value.storage_config != null ? [each.value.storage_config] : []

    content {
      dynamic "block_storage" {
        for_each = storage_config.value.block_storage != null ? [storage_config.value.block_storage] : []

        content {
          enabled = block_storage.value.enabled
        }
      }
    }
  }

  vpc_config {
    subnet_ids              = each.value.vpc_config.subnet_ids
    security_group_ids      = each.value.vpc_config.security_group_ids
    endpoint_private_access = each.value.vpc_config.endpoint_private_access
    endpoint_public_access  = each.value.vpc_config.endpoint_public_access
    public_access_cidrs     = each.value.vpc_config.public_access_cidrs
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_iam_openid_connect_provider" "cluster" {
  for_each = local.oidc_provider_clusters

  url             = aws_eks_cluster.cluster[each.key].identity[0].oidc[0].issuer
  client_id_list  = each.value.oidc_client_id_list
  thumbprint_list = each.value.oidc_thumbprint_list

  tags = each.value.tags
}

resource "aws_eks_node_group" "node_group" {
  for_each = local.node_groups

  cluster_name    = aws_eks_cluster.cluster[each.value.cluster_key].name
  node_group_name = each.value.name
  node_role_arn   = each.value.node_role_arn
  subnet_ids      = each.value.subnet_ids

  instance_types       = each.value.instance_types
  ami_type             = each.value.ami_type
  capacity_type        = each.value.capacity_type
  disk_size            = each.value.disk_size
  labels               = each.value.labels
  version              = each.value.version
  release_version      = each.value.release_version
  force_update_version = each.value.force_update_version

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    min_size     = each.value.scaling_config.min_size
    max_size     = each.value.scaling_config.max_size
  }

  dynamic "taint" {
    for_each = each.value.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  dynamic "remote_access" {
    for_each = each.value.remote_access != null ? [each.value.remote_access] : []

    content {
      ec2_ssh_key               = remote_access.value.ec2_ssh_key
      source_security_group_ids = remote_access.value.source_security_group_ids
    }
  }

  dynamic "launch_template" {
    for_each = each.value.launch_template != null ? [each.value.launch_template] : []

    content {
      id      = launch_template.value.id
      name    = launch_template.value.name
      version = launch_template.value.version
    }
  }

  dynamic "update_config" {
    for_each = each.value.update_config != null ? [each.value.update_config] : []

    content {
      max_unavailable            = update_config.value.max_unavailable
      max_unavailable_percentage = update_config.value.max_unavailable_percentage
      update_strategy            = update_config.value.update_strategy
    }
  }

  dynamic "node_repair_config" {
    for_each = each.value.node_repair_config != null ? [each.value.node_repair_config] : []

    content {
      enabled                                 = node_repair_config.value.enabled
      max_parallel_nodes_repaired_count       = node_repair_config.value.max_parallel_nodes_repaired_count
      max_parallel_nodes_repaired_percentage  = node_repair_config.value.max_parallel_nodes_repaired_percentage
      max_unhealthy_node_threshold_count      = node_repair_config.value.max_unhealthy_node_threshold_count
      max_unhealthy_node_threshold_percentage = node_repair_config.value.max_unhealthy_node_threshold_percentage
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(var.clusters), each.value.cluster_key)
      error_message = "node_group \"${each.key}\": cluster_key \"${each.value.cluster_key}\" is not a key of the clusters map."
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_eks_addon" "addon" {
  for_each = local.addons

  cluster_name                = aws_eks_cluster.cluster[each.value.cluster_key].name
  addon_name                  = each.value.addon_name
  addon_version               = each.value.addon_version
  service_account_role_arn    = each.value.service_account_role_arn
  preserve                    = each.value.preserve
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  configuration_values        = each.value.configuration_values

  dynamic "pod_identity_association" {
    for_each = each.value.pod_identity_association

    content {
      role_arn        = pod_identity_association.value.role_arn
      service_account = pod_identity_association.value.service_account
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(var.clusters), each.value.cluster_key)
      error_message = "addon \"${each.key}\": cluster_key \"${each.value.cluster_key}\" is not a key of the clusters map."
    }
  }

  tags = each.value.tags
}

resource "aws_eks_access_entry" "access_entry" {
  for_each = local.access_entries

  cluster_name      = aws_eks_cluster.cluster[each.value.cluster_key].name
  principal_arn     = each.value.principal_arn
  type              = each.value.type
  user_name         = each.value.user_name
  kubernetes_groups = each.value.kubernetes_groups

  lifecycle {
    precondition {
      condition     = contains(keys(var.clusters), each.value.cluster_key)
      error_message = "access_entry \"${each.key}\": cluster_key \"${each.value.cluster_key}\" is not a key of the clusters map."
    }
  }

  tags = each.value.tags
}

resource "aws_eks_access_policy_association" "association" {
  for_each = local.access_policy_associations

  cluster_name  = aws_eks_cluster.cluster[each.value.cluster_key].name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope.type
    namespaces = each.value.access_scope.namespaces
  }

  lifecycle {
    precondition {
      condition     = contains(keys(var.clusters), each.value.cluster_key)
      error_message = "access_policy_association \"${each.key}\": cluster_key \"${each.value.cluster_key}\" is not a key of the clusters map."
    }
  }
}
