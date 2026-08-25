resource "google_folder" "folder" {
  for_each = var.folders

  display_name        = each.value.display_name
  parent              = each.value.parent
  tags                = each.value.tags
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy
}
