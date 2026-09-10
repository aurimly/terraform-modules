output "key_pairs" {
  description = "Map of key pair key => object with `fingerprint` and `id` (the key pair name, which is also the import ID)."
  value = { for k, kp in stackit_key_pair.key_pair : k => {
    fingerprint = kp.fingerprint
    id          = kp.id
  } }
}
