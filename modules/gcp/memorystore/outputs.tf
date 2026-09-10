output "instance_ids" {
  description = "Map of instance key => full resource path (projects/<project>/locations/<region>/instances/<name>)."
  value       = { for k, i in google_redis_instance.instance : k => i.id }
}

output "instance_hosts" {
  description = "Map of instance key => instance host (an internal IP under PRIVATE_SERVICE_ACCESS or DIRECT_PEERING, an external IP otherwise)."
  value       = { for k, i in google_redis_instance.instance : k => i.host }
}

output "instance_ports" {
  description = "Map of instance key => instance port."
  value       = { for k, i in google_redis_instance.instance : k => i.port }
}

output "instance_current_location_ids" {
  description = "Map of instance key => the zone GCP actually placed the instance in (may differ from location_id when omitted)."
  value       = { for k, i in google_redis_instance.instance : k => i.current_location_id }
}
