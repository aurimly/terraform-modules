output "credentials" {
  description = "Map of credential key => object with `username` (API-generated, only available at creation) and `name` (read-only, MariaDB-specific, only available at creation), `password` (API-generated, only available at creation), `credential_id`, `host`, `hosts`, `port`, `uri` (only available at creation) and `id` (\"{project_id},{region},{instance_id},{credential_id}\", the import ID). Marked sensitive: password and uri are provider-sensitive and the rest rides along with it."
  sensitive   = true
  value = { for k, c in stackit_mariadb_credential.credential : k => {
    username      = c.username
    name          = c.name
    password      = c.password
    credential_id = c.credential_id
    host          = c.host
    hosts         = c.hosts
    port          = c.port
    uri           = c.uri
    id            = c.id
  } }
}
