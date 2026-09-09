locals {
  iam_bindings = {
    for b in flatten([
      for key, repo in var.repositories : [
        for binding_key, binding in repo.role_bindings : {
          repo_key      = key
          binding_key   = binding_key
          project_id    = repo.project_id
          location      = repo.location
          repository_id = repo.repository_id
          role          = binding.role
          members       = binding.members
        }
      ]
    ]) : "${b.repo_key}/${b.binding_key}" => b
  }
}

resource "google_artifact_registry_repository" "repository" {
  for_each = var.repositories

  project       = each.value.project_id
  location      = each.value.location
  repository_id = each.value.repository_id
  format        = each.value.format

  description            = each.value.description
  labels                 = each.value.labels
  kms_key_name           = each.value.kms_key_name
  cleanup_policy_dry_run = each.value.cleanup_policy_dry_run

  dynamic "cleanup_policies" {
    for_each = each.value.cleanup_policies

    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.condition != null ? [cleanup_policies.value.condition] : []

        content {
          tag_state             = condition.value.tag_state
          tag_prefixes          = condition.value.tag_prefixes
          version_name_prefixes = condition.value.version_name_prefixes
          package_name_prefixes = condition.value.package_name_prefixes
          older_than            = condition.value.older_than
          newer_than            = condition.value.newer_than
        }
      }

      dynamic "most_recent_versions" {
        for_each = cleanup_policies.value.most_recent_versions != null ? [cleanup_policies.value.most_recent_versions] : []

        content {
          keep_count            = most_recent_versions.value.keep_count
          package_name_prefixes = most_recent_versions.value.package_name_prefixes
        }
      }
    }
  }

  dynamic "docker_config" {
    for_each = each.value.docker_config != null ? [each.value.docker_config] : []

    content {
      immutable_tags = docker_config.value.immutable_tags
    }
  }

  dynamic "vulnerability_scanning_config" {
    for_each = each.value.vulnerability_scanning_config != null ? [each.value.vulnerability_scanning_config] : []

    content {
      enablement_config = vulnerability_scanning_config.value.enablement_config
    }
  }
}

resource "google_artifact_registry_repository_iam_binding" "binding" {
  for_each = local.iam_bindings

  project    = each.value.project_id
  location   = each.value.location
  repository = each.value.repository_id

  role    = each.value.role
  members = each.value.members

  depends_on = [google_artifact_registry_repository.repository]
}
