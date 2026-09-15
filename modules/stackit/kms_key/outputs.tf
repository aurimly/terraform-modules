output "keys" {
  description = "Map of key key => object with `key_id` and `id` (\"{project_id},{region},{keyring_id},{key_id}\", the import ID)."
  value = { for k, key in stackit_kms_key.key : k => {
    key_id = key.key_id
    id     = key.id
  } }
}
