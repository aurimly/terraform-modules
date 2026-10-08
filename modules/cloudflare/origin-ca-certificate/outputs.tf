output "certificate_ids" {
  description = "Origin CA certificate IDs, keyed by input certificate key."
  value       = { for k, cert in cloudflare_origin_ca_certificate.certificate : k => cert.id }
}

output "certificates" {
  description = "Issued Origin CA PEM certificates, keyed by input certificate key. Public certificates, but any output value lands in state; rotate certificates before deploying them to origins if state access is broader than origin access."
  value       = { for k, cert in cloudflare_origin_ca_certificate.certificate : k => cert.certificate }
}

output "certificate_expiries" {
  description = "Certificate expiry timestamps (RFC 3339), keyed by input certificate key."
  value       = { for k, cert in cloudflare_origin_ca_certificate.certificate : k => cert.expires_on }
}
