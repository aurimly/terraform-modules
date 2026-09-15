output "keyrings" {
  description = "Map of keyring key => object with `keyring_id` (UUID) and `id` (\"{project_id},{region},{keyring_id}\", the import ID)."
  value = { for k, kr in stackit_kms_keyring.keyring : k => {
    keyring_id = kr.keyring_id
    id         = kr.id
  } }
}
