output "public_ip_associates" {
  description = "Map of public IP association key => object with `ip` (the associated address) and `id` (\"{project_id},{region},{public_ip_id},{network_interface_id}\", the import ID)."
  value = { for k, a in stackit_public_ip_associate.public_ip_associate : k => {
    ip = a.ip
    id = a.id
  } }
}
