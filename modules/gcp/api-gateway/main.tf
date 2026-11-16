terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 8.0.0"
    }
  }
}

resource "google_api_gateway_api" "api" {
  for_each = var.apis

  provider = google-beta

  api_id          = each.value.api_id
  project         = each.value.project
  display_name    = each.value.display_name
  managed_service = each.value.managed_service
  labels          = each.value.labels
  deletion_policy = each.value.deletion_policy
}

resource "google_api_gateway_api_config" "api_config" {
  for_each = var.api_configs

  provider = google-beta

  api     = google_api_gateway_api.api[each.value.api].api_id
  project = each.value.project

  api_config_id        = each.value.api_config_id
  api_config_id_prefix = each.value.api_config_id_prefix
  display_name         = each.value.display_name
  labels               = each.value.labels
  deletion_policy      = each.value.deletion_policy

  dynamic "openapi_documents" {
    for_each = each.value.openapi_documents != null ? each.value.openapi_documents : []

    content {
      document {
        path     = openapi_documents.value.document.path
        contents = openapi_documents.value.document.contents
      }
    }
  }

  dynamic "grpc_services" {
    for_each = each.value.grpc_services != null ? each.value.grpc_services : []

    content {
      file_descriptor_set {
        path     = grpc_services.value.file_descriptor_set.path
        contents = grpc_services.value.file_descriptor_set.contents
      }

      dynamic "source" {
        for_each = grpc_services.value.source != null ? [grpc_services.value.source] : []

        content {
          path     = source.value.path
          contents = source.value.contents
        }
      }
    }
  }

  dynamic "managed_service_configs" {
    for_each = each.value.managed_service_configs != null ? each.value.managed_service_configs : []

    content {
      path     = managed_service_configs.value.path
      contents = managed_service_configs.value.contents
    }
  }

  dynamic "gateway_config" {
    for_each = each.value.gateway_config != null ? [each.value.gateway_config] : []

    content {
      backend_config {
        google_service_account = gateway_config.value.backend_config.google_service_account
      }
    }
  }

  # Configs are immutable upstream; a spec change replaces the config. The
  # provider requires create_before_destroy so the gateway keeps serving
  # while the replacement is created and repoints in-module.
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "gateway" {
  for_each = var.gateways

  provider = google-beta

  api_config = google_api_gateway_api_config.api_config[each.value.api_config_key].id
  project    = each.value.project

  gateway_id      = each.value.gateway_id
  display_name    = each.value.display_name
  labels          = each.value.labels
  region          = each.value.region
  deletion_policy = each.value.deletion_policy
}
