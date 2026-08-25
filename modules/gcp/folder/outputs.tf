output "folders" {
  description = "Map of folder key => object with `name` (full resource name \"folders/<id>\", usable as parent) and `folder_id` (bare numeric ID)."
  value = { for k, f in google_folder.folder : k => {
    name      = f.name
    folder_id = f.folder_id
  } }
}
