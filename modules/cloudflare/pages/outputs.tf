output "project_names" {
  description = "Map of project key => project name."
  value       = { for key, project in cloudflare_pages_project.project : key => project.name }
}

output "project_subdomains" {
  description = "Map of project key => <project>.pages.dev subdomain."
  value       = { for key, project in cloudflare_pages_project.project : key => project.subdomain }
}

output "project_domains" {
  description = "Map of project key => all domains serving the project (including the pages.dev subdomain)."
  value       = { for key, project in cloudflare_pages_project.project : key => project.domains }
}

output "domain_statuses" {
  description = "Map of composite domain key (project key/domain) => domain status."
  value       = { for key, domain in cloudflare_pages_domain.domain : key => domain.status }
}
