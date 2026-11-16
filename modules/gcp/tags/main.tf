resource "google_tags_tag_key" "key" {
  for_each = var.tag_keys

  parent               = each.value.parent
  short_name           = each.value.short_name
  description          = each.value.description
  purpose              = each.value.purpose
  purpose_data         = each.value.purpose_data
  allowed_values_regex = each.value.allowed_values_regex
  deletion_policy      = each.value.deletion_policy
}

resource "google_tags_tag_value" "value" {
  for_each = var.tag_values

  parent          = google_tags_tag_key.key[each.value.key].id
  short_name      = each.value.short_name
  description     = each.value.description
  deletion_policy = each.value.deletion_policy
}
