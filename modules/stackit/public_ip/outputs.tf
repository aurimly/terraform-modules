output "public_ips" {
  description = "Map of public IP key => object with `public_ip_id` (UUID), `ip` (the allocated address) and `id` (\"{project_id},{region},{public_ip_id}\", the import ID)."
  value = { for k, p in stackit_public_ip.public_ip : k => {
    public_ip_id = p.public_ip_id
    ip           = p.ip
    id           = p.id
  } }
}
