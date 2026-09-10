output "volumes" {
  description = "Map of volume key => object with `volume_id` (UUID), `server_id` (server the volume is attached to, if any), `size` (resolved gigabytes), `encrypted` (whether the volume is encrypted) and `id` (\"{project_id},{region},{volume_id}\", the import ID)."
  value = { for k, v in stackit_volume.volume : k => {
    volume_id = v.volume_id
    server_id = v.server_id
    size      = v.size
    encrypted = v.encrypted
    id        = v.id
  } }
}
