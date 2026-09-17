output "credentials" {
  description = "Map of credential key => object with `username`, `password` (both API-generated, only available at creation) and `id` (\"{project_id},{instance_id},{username}\"). Marked sensitive: password is provider-sensitive and the rest rides along with it."
  sensitive   = true
  value = { for k, c in stackit_observability_credential.credential : k => {
    username = c.username
    password = c.password
    id       = c.id
  } }
}
