output "users" {
  description = "Map of user key => object with `username`, `password` (API-generated, only available at creation), `user_id` and `id` (\"{project_id},{region},{instance_id},{user_id}\", the import ID). Marked sensitive: password is provider-sensitive and the rest rides along with it."
  sensitive   = true
  value = { for k, u in stackit_postgresflex_user.user : k => {
    username = u.username
    password = u.password
    user_id  = u.user_id
    id       = u.id
  } }
}
