terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_objectstorage_bucket" "bucket" {
  for_each = var.buckets

  name        = each.value.name
  project_id  = each.value.project_id
  region      = each.value.region
  object_lock = each.value.object_lock
}

resource "stackit_objectstorage_credentials_group" "credentials_group" {
  for_each = var.credentials_groups

  name       = each.value.name
  project_id = each.value.project_id
  region     = each.value.region
}

resource "stackit_objectstorage_credential" "credential" {
  for_each = var.credentials

  project_id           = each.value.project_id
  region               = each.value.region
  credentials_group_id = each.value.credentials_group_id != null ? each.value.credentials_group_id : stackit_objectstorage_credentials_group.credentials_group[each.value.credentials_group_key].credentials_group_id
  expiration_timestamp = each.value.expiration_timestamp
  rotate_when_changed  = each.value.rotate_when_changed
}
