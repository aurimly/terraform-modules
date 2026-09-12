locals {
  iam_bindings = {
    for b in flatten([
      for key, fn in var.functions : [
        for binding_key, binding in fn.role_bindings : {
          function_key = key
          binding_key  = binding_key
          name         = fn.name
          role         = binding.role
          members      = binding.members
          condition    = binding.condition
          project_id   = fn.project_id
          location     = fn.location
        }
      ]
    ]) : "${b.function_key}/${b.binding_key}" => b
  }
}

resource "google_cloudfunctions2_function" "function" {
  for_each = var.functions

  name            = each.value.name
  location        = each.value.location
  project         = each.value.project_id
  description     = each.value.description
  labels          = each.value.labels
  kms_key_name    = each.value.kms_key_name
  deletion_policy = each.value.deletion_policy

  dynamic "build_config" {
    for_each = [each.value.build_config]

    content {
      runtime               = build_config.value.runtime
      entry_point           = build_config.value.entrypoint
      worker_pool           = build_config.value.worker_pool
      service_account       = build_config.value.service_account
      docker_repository     = build_config.value.docker_repository
      environment_variables = build_config.value.environment_variables

      dynamic "automatic_update_policy" {
        for_each = build_config.value.automatic_update_policy != null && build_config.value.automatic_update_policy ? [1] : []

        content {}
      }

      dynamic "on_deploy_update_policy" {
        for_each = build_config.value.on_deploy_update_policy != null && build_config.value.on_deploy_update_policy ? [1] : []

        content {}
      }

      dynamic "source" {
        for_each = [build_config.value.source]

        content {
          dynamic "storage_source" {
            for_each = source.value.storage_source != null ? [source.value.storage_source] : []

            content {
              bucket     = storage_source.value.bucket
              object     = storage_source.value.object
              generation = storage_source.value.generation
            }
          }

          dynamic "repo_source" {
            for_each = source.value.repo_source != null ? [source.value.repo_source] : []

            content {
              project_id   = repo_source.value.project_id
              repo_name    = repo_source.value.repo_name
              branch_name  = repo_source.value.branch_name
              tag_name     = repo_source.value.tag_name
              commit_sha   = repo_source.value.commit_sha
              dir          = repo_source.value.dir
              invert_regex = repo_source.value.invert_regex
            }
          }
        }
      }
    }
  }

  dynamic "service_config" {
    for_each = each.value.service_config != null ? [each.value.service_config] : []

    content {
      min_instance_count               = service_config.value.min_instance_count
      max_instance_count               = service_config.value.max_instance_count
      available_memory                 = service_config.value.available_memory
      available_cpu                    = service_config.value.available_cpu
      timeout_seconds                  = service_config.value.timeout_seconds
      environment_variables            = service_config.value.environment_variables
      ingress_settings                 = service_config.value.ingress_settings
      vpc_connector                    = service_config.value.vpc_connector
      vpc_connector_egress_settings    = service_config.value.vpc_connector_egress_settings
      service_account_email            = service_config.value.service_account_email
      max_instance_request_concurrency = service_config.value.max_instance_request_concurrency
      all_traffic_on_latest_revision   = service_config.value.all_traffic_on_latest_revision
      binary_authorization_policy      = service_config.value.binary_authorization_policy
      direct_vpc_egress                = service_config.value.direct_vpc_egress

      dynamic "direct_vpc_network_interface" {
        for_each = service_config.value.direct_vpc_network_interface != null ? [service_config.value.direct_vpc_network_interface] : []

        content {
          network    = direct_vpc_network_interface.value.network
          subnetwork = direct_vpc_network_interface.value.subnetwork
          tags       = direct_vpc_network_interface.value.tags
        }
      }

      dynamic "secret_environment_variables" {
        for_each = service_config.value.secret_environment_variables

        content {
          key        = secret_environment_variables.value.key
          project_id = secret_environment_variables.value.project_id
          secret     = secret_environment_variables.value.secret
          version    = secret_environment_variables.value.version
        }
      }

      dynamic "secret_volumes" {
        for_each = service_config.value.secret_volumes

        content {
          mount_path = secret_volumes.value.mount_path
          project_id = secret_volumes.value.project_id
          secret     = secret_volumes.value.secret

          dynamic "versions" {
            for_each = secret_volumes.value.versions

            content {
              version = versions.value.version
              path    = versions.value.path
            }
          }
        }
      }
    }
  }

  dynamic "event_trigger" {
    for_each = each.value.event_trigger != null ? [each.value.event_trigger] : []

    content {
      trigger_region        = event_trigger.value.trigger_region
      event_type            = event_trigger.value.event_type
      pubsub_topic          = event_trigger.value.pubsub_topic
      service_account_email = event_trigger.value.service_account_email
      retry_policy          = event_trigger.value.retry_policy

      dynamic "event_filters" {
        for_each = event_trigger.value.event_filters

        content {
          attribute = event_filters.value.attribute
          value     = event_filters.value.value
          operator  = event_filters.value.operator
        }
      }
    }
  }
}

resource "google_cloudfunctions2_function_iam_binding" "binding" {
  for_each = local.iam_bindings

  project        = each.value.project_id
  location       = each.value.location
  cloud_function = each.value.name
  role           = each.value.role
  members        = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_cloudfunctions2_function.function]
}
