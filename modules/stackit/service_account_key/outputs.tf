output "service_account_keys" {
  description = "Map of service account key key => object with `key_id`, `id` (\"{project_id},{service_account_email},{key_id}\", the provider's resource identifier) and `json` (credentials JSON, only available at creation). Marked sensitive: json is provider-sensitive and the rest rides along with it."
  sensitive   = true
  value = { for k, key in stackit_service_account_key.service_account_key : k => {
    key_id = key.key_id
    id     = key.id
    json   = key.json
  } }
}
