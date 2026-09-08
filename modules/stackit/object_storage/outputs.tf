output "buckets" {
  description = "Map of bucket key => object with `url_path_style`, `url_virtual_hosted_style` and `id` (\"{project_id},{region},{name}\", the import ID)."
  value = { for k, b in stackit_objectstorage_bucket.bucket : k => {
    url_path_style           = b.url_path_style
    url_virtual_hosted_style = b.url_virtual_hosted_style
    id                       = b.id
  } }
}

output "credentials_groups" {
  description = "Map of credentials group key => object with `credentials_group_id` (UUID), `urn` and `id` (\"{project_id},{region},{credentials_group_id}\", the import ID)."
  value = { for k, g in stackit_objectstorage_credentials_group.credentials_group : k => {
    credentials_group_id = g.credentials_group_id
    urn                  = g.urn
    id                   = g.id
  } }
}

output "credentials" {
  description = "Map of credential key => object with `access_key`, `secret_access_key` (both API-generated), `credential_id`, `name` (API-generated) and `id` (\"{project_id},{region},{credentials_group_id},{credential_id}\", the import ID). Marked sensitive: secret_access_key is provider-sensitive and access_key rides along with it."
  sensitive   = true
  value = { for k, c in stackit_objectstorage_credential.credential : k => {
    access_key        = c.access_key
    secret_access_key = c.secret_access_key
    credential_id     = c.credential_id
    name              = c.name
    id                = c.id
  } }
}
