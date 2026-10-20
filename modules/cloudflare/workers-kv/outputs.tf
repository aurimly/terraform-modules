output "namespace_ids" {
  description = "Map of namespace key => namespace ID."
  value       = { for key, namespace in cloudflare_workers_kv_namespace.namespace : key => namespace.id }
}

output "namespace_titles" {
  description = "Map of namespace key => namespace title."
  value       = { for key, namespace in cloudflare_workers_kv_namespace.namespace : key => namespace.title }
}
