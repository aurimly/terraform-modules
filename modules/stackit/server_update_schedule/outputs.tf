output "server_update_schedules" {
  description = "Map of schedule key => object with `update_schedule_id` and `id` (\"{project_id},{region},{server_id},{update_schedule_id}\", the import ID)."
  value = { for k, s in stackit_server_update_schedule.this : k => {
    update_schedule_id = s.update_schedule_id
    id                 = s.id
  } }
}
