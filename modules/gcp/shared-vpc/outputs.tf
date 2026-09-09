output "host_project_ids" {
  description = "Map of host project key => host project id (the project enabled as Shared VPC host)."
  value       = { for k, h in google_compute_shared_vpc_host_project.host : k => h.project }
}

output "attached_service_projects" {
  description = "Map of composite key (host project key/service project id) => attached service project id."
  value       = { for k, s in google_compute_shared_vpc_service_project.service : k => s.service_project }
}

output "service_project_hosts" {
  description = "Map of composite key (host project key/service project id) => host project id the service project is attached to."
  value       = { for k, s in google_compute_shared_vpc_service_project.service : k => s.host_project }
}
