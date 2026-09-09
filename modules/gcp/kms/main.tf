locals {
  keys = {
    for b in flatten([
      for keyring_key, keyring in var.keyrings : [
        for key_key, key in keyring.keys : {
          keyring_key = keyring_key
          key_key     = key_key
          keyring     = keyring
          key         = key
        }
      ]
    ]) : "${b.keyring_key}/${b.key_key}" => b
  }

  keyring_role_bindings = {
    for b in flatten([
      for keyring_key, keyring in var.keyrings : [
        for binding_key, binding in keyring.role_bindings : {
          keyring_key = keyring_key
          binding_key = binding_key
          keyring     = keyring
          role        = binding.role
          members     = binding.members
        }
      ]
    ]) : "${b.keyring_key}/${b.binding_key}" => b
  }

  key_role_bindings = {
    for b in flatten([
      for keyring_key, keyring in var.keyrings : [
        for key_key, key in keyring.keys : [
          for binding_key, binding in key.role_bindings : {
            keyring_key = keyring_key
            key_key     = key_key
            binding_key = binding_key
            keyring     = keyring
            role        = binding.role
            members     = binding.members
          }
        ]
      ]
    ]) : "${b.keyring_key}/${b.key_key}/${b.binding_key}" => b
  }
}

resource "google_kms_key_ring" "keyring" {
  for_each = var.keyrings

  name     = each.value.name
  location = each.value.location
  project  = each.value.project_id
}

resource "google_kms_crypto_key" "key" {
  for_each = local.keys

  name     = each.value.key.name
  key_ring = google_kms_key_ring.keyring[each.value.keyring_key].id
  labels   = each.value.key.labels

  purpose                       = each.value.key.purpose
  rotation_period               = each.value.key.rotation_period
  destroy_scheduled_duration    = each.value.key.destroy_scheduled_duration
  import_only                   = each.value.key.import_only
  skip_initial_version_creation = each.value.key.skip_initial_version_creation
  deletion_policy               = each.value.key.deletion_policy

  dynamic "version_template" {
    for_each = each.value.key.version_template != null ? [each.value.key.version_template] : []

    content {
      algorithm        = version_template.value.algorithm
      protection_level = version_template.value.protection_level
    }
  }

  depends_on = [google_kms_key_ring.keyring]
}

resource "google_kms_key_ring_iam_binding" "binding" {
  for_each = local.keyring_role_bindings

  key_ring_id = google_kms_key_ring.keyring[each.value.keyring_key].id

  role    = each.value.role
  members = each.value.members

  depends_on = [google_kms_key_ring.keyring]
}

resource "google_kms_crypto_key_iam_binding" "binding" {
  for_each = local.key_role_bindings

  crypto_key_id = google_kms_crypto_key.key["${each.value.keyring_key}/${each.value.key_key}"].id

  role    = each.value.role
  members = each.value.members

  depends_on = [google_kms_crypto_key.key]
}
