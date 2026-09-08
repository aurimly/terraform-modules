output "clusters" {
  description = "Map of cluster key => object with `name`, `kubernetes_version_used`, `egress_address_ranges`, `pod_address_ranges`, `service_account_issuer`, `node_pools` (map of node pool name => resolved `os_version_used`) and `id` (\"{project_id},{region},{name}\", the import ID)."
  value = { for k, c in stackit_ske_cluster.cluster : k => {
    name                    = c.name
    kubernetes_version_used = c.kubernetes_version_used
    egress_address_ranges   = c.egress_address_ranges
    pod_address_ranges      = c.pod_address_ranges
    service_account_issuer  = c.service_account_issuer
    node_pools              = { for np in c.node_pools : np.name => np.os_version_used }
    id                      = c.id
  } }
}

output "kubeconfigs" {
  description = "Map of cluster key => object with `kube_config` (the raw admin kubeconfig), `expires_at`, `kube_config_id`, `creation_time` and `id` (\"{project_id},{cluster_name},{kube_config_id}\", the import ID). Only present for entries with a `kubeconfig` block. Marked sensitive: kube_config is a short-lived admin credential."
  sensitive   = true
  value = { for k, kc in stackit_ske_kubeconfig.kubeconfig : k => {
    kube_config    = kc.kube_config
    expires_at     = kc.expires_at
    kube_config_id = kc.kube_config_id
    creation_time  = kc.creation_time
    id             = kc.id
  } }
}
