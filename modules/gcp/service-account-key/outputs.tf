output "keys" {
  description = "Map of key => object with `name` (resource name ending in keys/{key-id}), `public_key` (base64), `private_key` (base64-encoded credentials JSON — only populated at creation and on rotation via keepers) and the `valid_after`/`valid_before` timestamps. Sensitive: the credential material persists in the Terraform state file like any output."
  value = { for k, key in google_service_account_key.key : k => {
    name         = key.name
    public_key   = key.public_key
    private_key  = key.private_key
    valid_after  = key.valid_after
    valid_before = key.valid_before
  } }
  sensitive = true
}

output "key_names" {
  description = "Map of key => key resource name (projects/{project}/serviceAccounts/{account}/keys/{key-id}). The bare key id is the last path segment; this is the identifier consumers reference."
  value       = { for k, key in google_service_account_key.key : k => key.name }
}
