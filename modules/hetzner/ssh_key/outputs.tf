output "ssh_keys" {
  description = "Map of SSH key key => object with `id` (string of the numeric SSH key ID, also the import ID), `name`, `public_key`, `fingerprint` and `labels`."
  value = { for k, key in hcloud_ssh_key.ssh_key : k => {
    id          = tostring(key.id)
    name        = key.name
    public_key  = key.public_key
    fingerprint = key.fingerprint
    labels      = key.labels
  } }
}
