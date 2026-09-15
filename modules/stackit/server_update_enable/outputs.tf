output "server_update_enables" {
  description = "Map of enable key => object with `enabled` (bool, API-reported) and `id` (\"{project_id},{server_id},{region}\")."
  value = { for k, e in stackit_server_update_enable.this : k => {
    enabled = e.enabled
    id      = e.id
  } }
}
