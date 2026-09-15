output "server_backup_enables" {
  description = "Map of enable key => object with `enabled` (bool, API-reported) and `id` (\"{project_id},{server_id},{region}\")."
  value = { for k, e in stackit_server_backup_enable.this : k => {
    enabled = e.enabled
    id      = e.id
  } }
}
