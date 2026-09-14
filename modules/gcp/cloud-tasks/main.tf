locals {
  iam_bindings = {
    for b in flatten([
      for key, queue in var.queues : [
        for binding_key, binding in queue.role_bindings : {
          queue_key   = key
          binding_key = binding_key
          name        = queue.name
          location    = queue.location
          role        = binding.role
          members     = binding.members
          condition   = binding.condition
          project_id  = queue.project_id
        }
      ]
    ]) : "${b.queue_key}/${b.binding_key}" => b
  }
}

resource "google_cloud_tasks_queue" "queue" {
  for_each = var.queues

  name            = each.value.name
  location        = each.value.location
  project         = each.value.project_id
  desired_state   = each.value.desired_state
  deletion_policy = each.value.deletion_policy

  dynamic "rate_limits" {
    for_each = each.value.rate_limits != null ? [each.value.rate_limits] : []

    content {
      max_dispatches_per_second = rate_limits.value.max_dispatches_per_second
      max_concurrent_dispatches = rate_limits.value.max_concurrent_dispatches
    }
  }

  dynamic "retry_config" {
    for_each = each.value.retry_config != null ? [each.value.retry_config] : []

    content {
      max_attempts       = retry_config.value.max_attempts
      max_retry_duration = retry_config.value.max_retry_duration
      min_backoff        = retry_config.value.min_backoff
      max_backoff        = retry_config.value.max_backoff
      max_doublings      = retry_config.value.max_doublings
    }
  }

  dynamic "stackdriver_logging_config" {
    for_each = each.value.stackdriver_logging_config != null ? [each.value.stackdriver_logging_config] : []

    content {
      sampling_ratio = stackdriver_logging_config.value.sampling_ratio
    }
  }

  dynamic "http_target" {
    for_each = each.value.http_target != null ? [each.value.http_target] : []

    content {
      http_method = http_target.value.http_method

      dynamic "uri_override" {
        for_each = http_target.value.uri_override != null ? [http_target.value.uri_override] : []

        content {
          scheme                    = uri_override.value.scheme
          host                      = uri_override.value.host
          port                      = uri_override.value.port
          uri_override_enforce_mode = uri_override.value.uri_override_enforce_mode

          dynamic "path_override" {
            for_each = uri_override.value.path_override != null ? [uri_override.value.path_override] : []

            content {
              path = path_override.value.path
            }
          }

          dynamic "query_override" {
            for_each = uri_override.value.query_override != null ? [uri_override.value.query_override] : []

            content {
              query_params = query_override.value.query_params
            }
          }
        }
      }

      dynamic "header_overrides" {
        for_each = http_target.value.header_overrides

        content {
          header {
            key   = header_overrides.key
            value = header_overrides.value
          }
        }
      }

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
}

resource "google_cloud_tasks_queue_iam_binding" "binding" {
  for_each = local.iam_bindings

  name     = each.value.name
  location = each.value.location
  role     = each.value.role
  members  = each.value.members
  project  = each.value.project_id

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_cloud_tasks_queue.queue]
}
