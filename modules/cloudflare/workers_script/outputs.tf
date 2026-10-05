output "worker_ids" {
  description = "Map of worker key => immutable Worker ID (the ID the import needs)."
  value       = { for key, worker in cloudflare_worker.worker : key => worker.id }
}

output "worker_names" {
  description = "Map of worker key => Worker name."
  value       = { for key, worker in cloudflare_worker.worker : key => worker.name }
}

output "worker_deployed_ons" {
  description = "Map of worker key => last deployment timestamp. Null until wrangler's first deploy of the Worker."
  value       = { for key, worker in cloudflare_worker.worker : key => worker.deployed_on }
}
