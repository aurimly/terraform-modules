resource "google_vertex_ai_index_endpoint" "index_endpoint" {
  for_each = var.index_endpoints

  display_name            = each.value.display_name
  region                  = each.value.region
  project                 = each.value.project_id
  description             = each.value.description
  labels                  = each.value.labels
  network                 = each.value.network
  public_endpoint_enabled = each.value.public_endpoint_enabled
  deletion_policy         = each.value.deletion_policy

  dynamic "encryption_spec" {
    for_each = each.value.encryption_spec != null ? [each.value.encryption_spec] : []

    content {
      kms_key_name = encryption_spec.value.kms_key_name
    }
  }

  dynamic "private_service_connect_config" {
    for_each = each.value.private_service_connect_config != null ? [each.value.private_service_connect_config] : []

    content {
      enable_private_service_connect = private_service_connect_config.value.enable_private_service_connect
      project_allowlist              = private_service_connect_config.value.project_allowlist

      dynamic "psc_automation_configs" {
        for_each = private_service_connect_config.value.psc_automation_configs

        content {
          project_id = psc_automation_configs.value.project_id
          network    = psc_automation_configs.value.network
        }
      }
    }
  }
}

resource "google_vertex_ai_index_endpoint_deployed_index" "deployed_index" {
  for_each = var.deployed_indexes

  deployed_index_id     = each.value.deployed_index_id
  index                 = each.value.index
  index_endpoint        = each.value.index_endpoint
  region                = each.value.region
  display_name          = each.value.display_name
  enable_access_logging = each.value.enable_access_logging
  reserved_ip_ranges    = each.value.reserved_ip_ranges
  deployment_group      = each.value.deployment_group
  deletion_policy       = each.value.deletion_policy

  dynamic "automatic_resources" {
    for_each = each.value.automatic_resources != null ? [each.value.automatic_resources] : []

    content {
      min_replica_count = automatic_resources.value.min_replica_count
      max_replica_count = automatic_resources.value.max_replica_count
    }
  }

  dynamic "dedicated_resources" {
    for_each = each.value.dedicated_resources != null ? [each.value.dedicated_resources] : []

    content {
      min_replica_count = dedicated_resources.value.min_replica_count
      max_replica_count = dedicated_resources.value.max_replica_count

      machine_spec {
        machine_type = dedicated_resources.value.machine_spec.machine_type
      }
    }
  }

  dynamic "deployed_index_auth_config" {
    for_each = each.value.deployed_index_auth_config != null ? [each.value.deployed_index_auth_config] : []

    content {
      dynamic "auth_provider" {
        for_each = deployed_index_auth_config.value.auth_provider != null ? [deployed_index_auth_config.value.auth_provider] : []

        content {
          audiences       = auth_provider.value.audiences
          allowed_issuers = auth_provider.value.allowed_issuers
        }
      }
    }
  }
}
