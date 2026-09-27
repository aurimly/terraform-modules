output "cluster_names" {
  description = "Map of cluster key => cluster name."
  value       = { for k, c in aws_eks_cluster.cluster : k => c.name }
}

output "cluster_arns" {
  description = "Map of cluster key => cluster ARN."
  value       = { for k, c in aws_eks_cluster.cluster : k => c.arn }
}

output "cluster_endpoints" {
  description = "Map of cluster key => Kubernetes API server endpoint (feed the kubeconfig and kubernetes/helm provider configs)."
  value       = { for k, c in aws_eks_cluster.cluster : k => c.endpoint }
}

output "cluster_certificate_authorities" {
  description = "Map of cluster key => base64-encoded cluster CA data (certificate-authority-data in the kubeconfig)."
  value       = { for k, c in aws_eks_cluster.cluster : k => c.certificate_authority[0].data }
}

output "cluster_versions" {
  description = "Map of cluster key => resolved Kubernetes version."
  value       = { for k, c in aws_eks_cluster.cluster : k => c.version }
}

output "cluster_platform_versions" {
  description = "Map of cluster key => resolved platform version."
  value       = { for k, c in aws_eks_cluster.cluster : k => c.platform_version }
}

output "cluster_statuses" {
  description = "Map of cluster key => cluster status (CREATING, ACTIVE, DELETING, FAILED)."
  value       = { for k, c in aws_eks_cluster.cluster : k => c.status }
}

output "cluster_oidc_issuer_urls" {
  description = "Map of cluster key => OIDC issuer URL (present for every cluster)."
  value       = { for k, c in aws_eks_cluster.cluster : k => c.identity[0].oidc[0].issuer }
}

output "oidc_provider_arns" {
  description = "Map of cluster key => OIDC provider ARN, only for clusters with create_oidc_provider = true (pair with aws/iam-role IRSA trust conditions)."
  value       = { for k, o in aws_iam_openid_connect_provider.cluster : k => o.arn }
}

output "node_group_names" {
  description = "Map of composite \"clusterKey.groupKey\" key => node group name."
  value       = { for k, g in aws_eks_node_group.node_group : k => g.node_group_name }
}

output "node_group_arns" {
  description = "Map of composite \"clusterKey.groupKey\" key => node group ARN."
  value       = { for k, g in aws_eks_node_group.node_group : k => g.arn }
}

output "node_group_statuses" {
  description = "Map of composite \"clusterKey.groupKey\" key => node group status."
  value       = { for k, g in aws_eks_node_group.node_group : k => g.status }
}

output "node_group_asg_names" {
  description = "Map of composite \"clusterKey.groupKey\" key => list of underlying Auto Scaling Group names (ASG/instance-consumer wiring)."
  value       = { for k, g in aws_eks_node_group.node_group : k => [for a in try(g.resources[0].autoscaling_groups, []) : a.name] }
}

output "addon_arns" {
  description = "Map of composite \"clusterKey.addonKey\" key => add-on ARN."
  value       = { for k, a in aws_eks_addon.addon : k => a.arn }
}

output "addon_ids" {
  description = "Map of composite \"clusterKey.addonKey\" key => add-on ID (cluster_name:addon_name)."
  value       = { for k, a in aws_eks_addon.addon : k => a.id }
}

output "access_entry_arns" {
  description = "Map of composite \"clusterKey.entryKey\" key => access entry ARN."
  value       = { for k, e in aws_eks_access_entry.access_entry : k => e.access_entry_arn }
}

output "access_policy_association_ids" {
  description = "Map of composite \"clusterKey.assocKey\" key => association ID (cluster_name#principal_arn#policy_arn)."
  value       = { for k, a in aws_eks_access_policy_association.association : k => a.id }
}
