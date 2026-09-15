output "server_backup_schedules" {
  description = "Map of schedule key => object with `backup_schedule_id` and `id` (\"{project_id},{region},{server_id},{backup_schedule_id}\", the import ID)."
  value = { for k, s in stackit_server_backup_schedule.this : k => {
    backup_schedule_id = s.backup_schedule_id
    id                 = s.id
  } }
}
