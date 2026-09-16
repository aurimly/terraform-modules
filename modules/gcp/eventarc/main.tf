resource "google_eventarc_trigger" "trigger" {
  for_each = var.triggers

  name                    = each.value.name
  location                = each.value.location
  project                 = each.value.project_id
  labels                  = each.value.labels
  service_account         = each.value.service_account
  channel                 = each.value.channel
  event_data_content_type = each.value.event_data_content_type
  deletion_policy         = each.value.deletion_policy

  destination {
    dynamic "cloud_run_service" {
      for_each = each.value.cloud_run_service != null ? [each.value.cloud_run_service] : []

      content {
        service = cloud_run_service.value.service
        region  = cloud_run_service.value.region
        path    = cloud_run_service.value.path
      }
    }

    dynamic "gke" {
      for_each = each.value.gke != null ? [each.value.gke] : []

      content {
        cluster   = gke.value.cluster
        location  = gke.value.location
        namespace = gke.value.namespace
        service   = gke.value.service
        path      = gke.value.path
      }
    }

    workflow = each.value.workflow

    dynamic "http_endpoint" {
      for_each = each.value.http_endpoint != null ? [each.value.http_endpoint] : []

      content {
        uri = http_endpoint.value.uri
      }
    }

    dynamic "network_config" {
      for_each = each.value.network_attachment != null ? [each.value.network_attachment] : []

      content {
        network_attachment = network_config.value
      }
    }
  }

  dynamic "matching_criteria" {
    for_each = each.value.matching_criteria

    content {
      attribute = matching_criteria.value.attribute
      value     = matching_criteria.value.value
      operator  = matching_criteria.value.operator
    }
  }

  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []

    content {
      max_attempts = retry_policy.value.max_attempts
    }
  }

  dynamic "transport" {
    for_each = each.value.pubsub_topic != null ? [each.value.pubsub_topic] : []

    content {
      pubsub {
        topic = transport.value
      }
    }
  }
}
