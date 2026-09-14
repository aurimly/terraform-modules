resource "google_cloud_scheduler_job" "job" {
  for_each = var.jobs

  name             = each.value.name
  description      = each.value.description
  schedule         = each.value.schedule
  time_zone        = each.value.time_zone
  paused           = each.value.paused
  attempt_deadline = each.value.attempt_deadline
  region           = each.value.region
  project          = each.value.project_id
  deletion_policy  = each.value.deletion_policy

  dynamic "retry_config" {
    for_each = each.value.retry_config != null ? [each.value.retry_config] : []

    content {
      retry_count          = retry_config.value.retry_count
      max_retry_duration   = retry_config.value.max_retry_duration
      min_backoff_duration = retry_config.value.min_backoff_duration
      max_backoff_duration = retry_config.value.max_backoff_duration
      max_doublings        = retry_config.value.max_doublings
    }
  }

  dynamic "pubsub_target" {
    for_each = each.value.pubsub_target != null ? [each.value.pubsub_target] : []

    content {
      topic_name = pubsub_target.value.topic_name
      data       = pubsub_target.value.data
      attributes = pubsub_target.value.attributes
    }
  }

  dynamic "http_target" {
    for_each = each.value.http_target != null ? [each.value.http_target] : []

    content {
      uri         = http_target.value.uri
      http_method = http_target.value.http_method
      body        = http_target.value.body
      headers     = http_target.value.headers

      dynamic "oauth_token" {
        for_each = http_target.value.oauth_token != null ? [http_target.value.oauth_token] : []

        content {
          service_account_email = oauth_token.value.service_account_email
          scope                 = oauth_token.value.scope
        }
      }

      dynamic "oidc_token" {
        for_each = http_target.value.oidc_token != null ? [http_target.value.oidc_token] : []

        content {
          service_account_email = oidc_token.value.service_account_email
          audience              = oidc_token.value.audience
        }
      }
    }
  }

  dynamic "app_engine_http_target" {
    for_each = each.value.app_engine_http_target != null ? [each.value.app_engine_http_target] : []

    content {
      http_method  = app_engine_http_target.value.http_method
      relative_uri = app_engine_http_target.value.relative_uri
      body         = app_engine_http_target.value.body
      headers      = app_engine_http_target.value.headers

      dynamic "app_engine_routing" {
        for_each = app_engine_http_target.value.app_engine_routing != null ? [app_engine_http_target.value.app_engine_routing] : []

        content {
          service  = app_engine_routing.value.service
          version  = app_engine_routing.value.version
          instance = app_engine_routing.value.instance
        }
      }
    }
  }
}
