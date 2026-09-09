resource "google_compute_ssl_policy" "policy" {
  for_each = var.ssl_policies

  name                      = each.value.name
  project                   = each.value.project_id
  description               = each.value.description
  profile                   = each.value.profile
  min_tls_version           = each.value.min_tls_version
  post_quantum_key_exchange = each.value.post_quantum_key_exchange
  custom_features           = each.value.custom_features
}
