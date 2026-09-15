output "users" {
  description = "Map of user key => object with `username`, `password` (API-generated, only available at creation), `user_id`, `host`, `port`, `uri` (API-generated, only available at creation) and `id` (\"{project_id},{region},{instance_id},{user_id}\", the import ID). Marked sensitive: password and uri are provider-sensitive and the rest rides along with it."
  sensitive   = true
  value = { for k, u in stackit_mongodbflex_user.user : k => {
    username = u.username
    password = u.password
    user_id  = u.user_id
    host     = u.host
    port     = u.port
    uri      = u.uri
    id       = u.id
  } }
}
