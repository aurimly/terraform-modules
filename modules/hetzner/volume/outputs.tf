output "volumes" {
  description = "Map of volume key => object with `id` (string of the numeric volume ID, also the import ID), `name`, `size`, `location`, `server_id`, `linux_device`, `delete_protection` and `labels`."
  value = { for k, v in hcloud_volume.volume : k => {
    id                = tostring(v.id)
    name              = v.name
    size              = v.size
    location          = v.location
    server_id         = v.server_id
    linux_device      = v.linux_device
    delete_protection = v.delete_protection
    labels            = v.labels
  } }
}
