output "certificate_ids" {
  description = "Map of certificate key => certificate id."
  value       = { for k, c in google_compute_managed_ssl_certificate.certificate : k => c.id }
}

output "certificate_self_links" {
  description = "Map of certificate key => self link (feeds ssl_certificates on target HTTPS proxies in gcp/load-balancer)."
  value       = { for k, c in google_compute_managed_ssl_certificate.certificate : k => c.self_link }
}

output "certificate_names" {
  description = "Map of certificate key => certificate name."
  value       = { for k, c in google_compute_managed_ssl_certificate.certificate : k => c.name }
}

output "certificate_domains" {
  description = "Map of certificate key => managed domains list."
  value       = { for k, c in google_compute_managed_ssl_certificate.certificate : k => c.managed[0].domains }
}

output "certificate_expire_time" {
  description = "Map of certificate key => expire time (RFC3339) of the most recently generated certificate."
  value       = { for k, c in google_compute_managed_ssl_certificate.certificate : k => c.expire_time }
}

output "certificate_subject_alternative_names" {
  description = "Map of certificate key => subject alternative names list of the most recently generated certificate."
  value       = { for k, c in google_compute_managed_ssl_certificate.certificate : k => c.subject_alternative_names }
}
