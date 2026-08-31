output "folders" {
  description = "Map of folder key => object with `container_id` (user-friendly ID, usable as `parent_container_id` for nested folders and projects) and `folder_id` (folder UUID)."
  value = { for k, f in stackit_resourcemanager_folder.folder : k => {
    container_id = f.container_id
    folder_id    = f.folder_id
  } }
}
