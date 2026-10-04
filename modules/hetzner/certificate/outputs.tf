output "certificates" {
  description = "Map of certificate key => object with `id` (string of the numeric certificate ID, also the import ID), `name`, `type` (`managed` or `uploaded`), `certificate` (public PEM), `domain_names`, `fingerprint`, `created`, `not_valid_before`, `not_valid_after` and `labels`."
  value = merge(
    { for k, cert in hcloud_managed_certificate.managed : k => {
      id               = tostring(cert.id)
      name             = cert.name
      type             = cert.type
      certificate      = cert.certificate
      domain_names     = cert.domain_names
      fingerprint      = cert.fingerprint
      created          = cert.created
      not_valid_before = cert.not_valid_before
      not_valid_after  = cert.not_valid_after
      labels           = cert.labels
    } },
    { for k, cert in hcloud_uploaded_certificate.uploaded : k => {
      id               = tostring(cert.id)
      name             = cert.name
      type             = cert.type
      certificate      = cert.certificate
      domain_names     = cert.domain_names
      fingerprint      = cert.fingerprint
      created          = cert.created
      not_valid_before = cert.not_valid_before
      not_valid_after  = cert.not_valid_after
      labels           = cert.labels
    } }
  )
}
