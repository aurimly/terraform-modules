resource "google_service_account_key" "key" {
  for_each = var.service_account_keys

  service_account_id = each.value.service_account
  key_algorithm      = each.value.key_algorithm
  public_key_type    = each.value.public_key_type
  private_key_type   = each.value.private_key_type
  public_key_data    = each.value.public_key_data
  keepers            = each.value.keepers
  deletion_policy    = each.value.deletion_policy
}
