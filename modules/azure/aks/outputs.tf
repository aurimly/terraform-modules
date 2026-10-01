output "cluster_ids" {
  description = "Map of cluster key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.ContainerService/managedClusters/<name>\")."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => c.id }
}

output "cluster_names" {
  description = "Map of cluster key => cluster name."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => c.name }
}

output "cluster_fqdns" {
  description = "Map of cluster key => auto-generated FQDN of the API server (public clusters and private clusters with public FQDN enabled)."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => c.fqdn }
}

output "cluster_private_fqdns" {
  description = "Map of cluster key => private FQDN of the API server on private clusters."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => try(c.private_fqdn, null) }
}

output "cluster_kube_config_raw" {
  description = "Map of cluster key => YAML kube config with cluster credentials. Sensitive. Only populated when local accounts are enabled."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => c.kube_config_raw }
  sensitive   = true
}

output "cluster_kube_admin_config_raw" {
  description = "Map of cluster key => YAML kube admin config (bypasses RBAC). Sensitive. Only populated for Azure AD-integrated clusters when local accounts are enabled."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => try(c.kube_admin_config_raw, null) }
  sensitive   = true
}

output "cluster_client_certificates" {
  description = "Map of cluster key => client certificate from the kube config. Sensitive."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => try(c.kube_config[0].client_certificate, null) }
  sensitive   = true
}

output "cluster_oidc_issuer_urls" {
  description = "Map of cluster key => OIDC issuer URL on clusters with oidc_issuer_enabled — feeds workload identity federation wiring in the consumer (federated credentials on user-assigned identities)."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => try(c.oidc_issuer_url, null) }
}

output "cluster_identity_principal_ids" {
  description = "Map of cluster key => principal ID of the cluster's managed identity (system-assigned or user-assigned) — feeds role assignments toward the resources the cluster manages."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => try(c.identity[0].principal_id, null) }
}

output "cluster_identity_object_ids" {
  description = "Map of cluster key => object ID of the cluster's managed identity."
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => try(c.identity[0].object_id, null) }
}

output "cluster_kubelet_identities" {
  description = "Map of cluster key => { client_id, object_id, user_assigned_identity_id } of the kubelet identity assigned by the cluster."
  value = {
    for k, c in azurerm_kubernetes_cluster.cluster : k => {
      client_id                 = try(c.kubelet_identity[0].client_id, null)
      object_id                 = try(c.kubelet_identity[0].object_id, null)
      user_assigned_identity_id = try(c.kubelet_identity[0].user_assigned_identity_id, null)
    }
  }
}

output "node_pool_names" {
  description = "Map of \"<cluster_key>.<pool_key>\" => node pool name."
  value       = { for k, p in azurerm_kubernetes_cluster_node_pool.node_pool : k => p.name }
}

output "node_pool_ids" {
  description = "Map of \"<cluster_key>.<pool_key>\" => full ARM resource ID of the node pool."
  value       = { for k, p in azurerm_kubernetes_cluster_node_pool.node_pool : k => p.id }
}
