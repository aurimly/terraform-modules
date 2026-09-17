output "credentials" {
  description = "Map of credential key => object with `username`, `password` (both API-generated, only available at creation), `credential_id`, `host`, `hosts`, `port`, `uri`, `uris`, `http_api_uri`, `http_api_uris`, `management` and `id` (\"{project_id},{region},{instance_id},{credential_id}\", the import ID). Marked sensitive: password and uri are provider-sensitive and the rest rides along with it."
  sensitive   = true
  value = { for k, c in stackit_rabbitmq_credential.credential : k => {
    username      = c.username
    password      = c.password
    credential_id = c.credential_id
    host          = c.host
    hosts         = c.hosts
    port          = c.port
    uri           = c.uri
    uris          = c.uris
    http_api_uri  = c.http_api_uri
    http_api_uris = c.http_api_uris
    management    = c.management
    id            = c.id
  } }
}
