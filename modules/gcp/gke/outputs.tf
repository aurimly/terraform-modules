output "cluster_names" {
  description = "Map of cluster key => cluster name."
  value       = { for k, c in google_container_cluster.cluster : k => c.name }
}

output "cluster_self_links" {
  description = "Map of cluster key => cluster self link."
  value       = { for k, c in google_container_cluster.cluster : k => c.self_link }
}

output "cluster_ids" {
  description = "Map of cluster key => cluster ID (projects/{project}/locations/{location}/clusters/{name})."
  value       = { for k, c in google_container_cluster.cluster : k => c.id }
}

output "cluster_endpoints" {
  description = "Map of cluster key => cluster endpoint (API server address)."
  value       = { for k, c in google_container_cluster.cluster : k => c.endpoint }
}

output "cluster_locations" {
  description = "Map of cluster key => location (region for regional clusters, zone for zonal clusters)."
  value       = { for k, c in google_container_cluster.cluster : k => c.location }
}

output "node_pool_names" {
  description = "Map of node pool key => node pool name. Keys are \"<cluster_key>/<pool_name>\"; pool names contain no \"/\", so the last \"/\" splits the key."
  value       = { for k, p in google_container_node_pool.node_pool : k => p.name }
}

output "node_pool_ids" {
  description = "Map of node pool key => node pool ID (projects/{project}/locations/{location}/clusters/{cluster}/nodePools/{name}). Keys are \"<cluster_key>/<pool_name>\"."
  value       = { for k, p in google_container_node_pool.node_pool : k => p.id }
}

output "node_pool_instance_group_urls" {
  description = "Map of node pool key => list of instance group URLs (one per zone), usable as load-balancer backend service groups. Keys are \"<cluster_key>/<pool_name>\"."
  value       = { for k, p in google_container_node_pool.node_pool : k => [for u in p.instance_group_urls : replace(u, "instanceGroupManagers", "instanceGroups")] }
}

output "backup_plan_names" {
  description = "Map of backup plan key => backup plan name. Keys are \"<cluster_key>/<plan_name>\"."
  value       = { for k, b in google_gke_backup_backup_plan.backup_plan : k => b.name }
}

output "backup_plan_ids" {
  description = "Map of backup plan key => backup plan ID (projects/{project}/locations/{location}/backupPlans/{name}). Keys are \"<cluster_key>/<plan_name>\"."
  value       = { for k, b in google_gke_backup_backup_plan.backup_plan : k => b.id }
}
