locals {
  secrets = {
    for key, secret in var.secrets : key => {
      secret_id   = secret.secret_id
      project_id  = secret.project_id
      labels      = secret.labels
      annotations = secret.annotations
      replication = secret.replication != null ? {
        auto = secret.replication.auto != null ? {
          customer_managed_encryption = try(secret.replication.auto.customer_managed_encryption, null)
        } : null
        user_managed = secret.replication.user_managed != null ? {
          replicas = [
            for replica in secret.replication.user_managed.replicas : {
              location                    = replica.location
              customer_managed_encryption = try(replica.customer_managed_encryption, null)
            }
          ]
        } : null
      } : { auto = { customer_managed_encryption = null }, user_managed = null }
      rotation            = secret.rotation
      topics              = secret.topics
      version_aliases     = secret.version_aliases
      version_destroy_ttl = secret.version_destroy_ttl
      ttl                 = secret.ttl
      deletion_policy     = secret.deletion_policy
    }
  }

  secret_versions = {
    for b in flatten([
      for key, secret in var.secrets : [
        for version_key, version in secret.versions : {
          secret_key  = key
          version_key = version_key
          version     = version
        }
      ]
    ]) : "${b.secret_key}/${b.version_key}" => b
  }

  iam_bindings = {
    for b in flatten([
      for key, secret in var.secrets : [
        for binding_key, binding in secret.role_bindings : {
          secret_key  = key
          binding_key = binding_key
          role        = binding.role
          members     = binding.members
          condition   = binding.condition
        }
      ]
    ]) : "${b.secret_key}/${b.binding_key}" => b
  }
}

resource "google_secret_manager_secret" "secret" {
  for_each = local.secrets

  secret_id   = each.value.secret_id
  project     = each.value.project_id
  labels      = each.value.labels
  annotations = each.value.annotations

  dynamic "replication" {
    for_each = [each.value.replication]

    content {
      dynamic "auto" {
        for_each = replication.value.auto != null ? [replication.value.auto] : []

        content {
          dynamic "customer_managed_encryption" {
            for_each = replication.value.auto.customer_managed_encryption != null ? [replication.value.auto.customer_managed_encryption] : []

            content {
              kms_key_name = customer_managed_encryption.value.kms_key_name
            }
          }
        }
      }

      dynamic "user_managed" {
        for_each = replication.value.user_managed != null ? [replication.value.user_managed] : []

        content {
          dynamic "replicas" {
            for_each = replication.value.user_managed.replicas

            content {
              location = replicas.value.location

              dynamic "customer_managed_encryption" {
                for_each = replicas.value.customer_managed_encryption != null ? [replicas.value.customer_managed_encryption] : []

                content {
                  kms_key_name = customer_managed_encryption.value.kms_key_name
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "rotation" {
    for_each = each.value.rotation != null ? [each.value.rotation] : []

    content {
      next_rotation_time = rotation.value.next_rotation_time
      rotation_period    = rotation.value.rotation_period
    }
  }

  dynamic "topics" {
    for_each = each.value.topics != null ? each.value.topics : []

    content {
      name = topics.value.name
    }
  }

  version_aliases     = each.value.version_aliases
  version_destroy_ttl = each.value.version_destroy_ttl
  ttl                 = each.value.ttl
  deletion_policy     = each.value.deletion_policy
}

resource "google_secret_manager_secret_version" "version" {
  for_each = local.secret_versions

  secret = google_secret_manager_secret.secret[each.value.secret_key].id

  secret_data           = sensitive(each.value.version.secret_data)
  is_secret_data_base64 = each.value.version.is_secret_data_base64
  enabled               = each.value.version.enabled
  deletion_policy       = each.value.version.deletion_policy
}

resource "google_secret_manager_secret_iam_binding" "binding" {
  for_each = local.iam_bindings

  secret_id = google_secret_manager_secret.secret[each.value.secret_key].id
  role      = each.value.role
  members   = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_secret_manager_secret.secret]
}
