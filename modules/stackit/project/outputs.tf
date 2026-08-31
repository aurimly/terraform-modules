output "projects" {
  description = "Map of project key => object with `container_id` (user-friendly ID, also the import ID) and `project_id` (project UUID, used by most other STACKIT resources)."
  value = { for k, p in stackit_resourcemanager_project.project : k => {
    container_id = p.container_id
    project_id   = p.project_id
  } }
}
