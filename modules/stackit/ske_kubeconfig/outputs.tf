output "kubeconfigs" {
  description = "Map of kubeconfig key => object with `kube_config` (the raw admin kubeconfig), `expires_at`, `kube_config_id`, `creation_time` and `id` (\"{project_id},{cluster_name},{kube_config_id}\", the import ID). Marked sensitive: kube_config is a short-lived admin credential."
  sensitive   = true
  value = { for k, kc in stackit_ske_kubeconfig.kubeconfig : k => {
    kube_config    = kc.kube_config
    expires_at     = kc.expires_at
    kube_config_id = kc.kube_config_id
    creation_time  = kc.creation_time
    id             = kc.id
  } }
}
