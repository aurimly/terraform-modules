resource "azurerm_container_app" "container_app" {
  for_each = var.container_apps

  name                         = each.value.name
  resource_group_name          = each.value.resource_group_name
  container_app_environment_id = each.value.container_app_environment_id
  revision_mode                = each.value.revision_mode

  workload_profile_name  = each.value.workload_profile_name
  max_inactive_revisions = each.value.max_inactive_revisions

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "secret" {
    for_each = each.value.secret
    content {
      name                = secret.value.name
      value               = secret.value.value
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  dynamic "registry" {
    for_each = each.value.registry
    content {
      server               = registry.value.server
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
      identity             = registry.value.identity
    }
  }

  dynamic "dapr" {
    for_each = each.value.dapr != null ? [each.value.dapr] : []
    content {
      app_id       = dapr.value.app_id
      app_port     = dapr.value.app_port
      app_protocol = dapr.value.app_protocol
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress != null ? [each.value.ingress] : []
    content {
      target_port                = ingress.value.target_port
      exposed_port               = ingress.value.exposed_port
      transport                  = ingress.value.transport
      external_enabled           = ingress.value.external_enabled
      allow_insecure_connections = ingress.value.allow_insecure_connections
      client_certificate_mode    = ingress.value.client_certificate_mode

      dynamic "cors" {
        for_each = ingress.value.cors != null ? [ingress.value.cors] : []
        content {
          allowed_origins           = cors.value.allowed_origins
          allow_credentials_enabled = cors.value.allow_credentials_enabled
          allowed_headers           = cors.value.allowed_headers
          allowed_methods           = cors.value.allowed_methods
          exposed_headers           = cors.value.exposed_headers
          max_age_in_seconds        = cors.value.max_age_in_seconds
        }
      }

      dynamic "ip_security_restriction" {
        for_each = ingress.value.ip_security_restriction
        content {
          name             = ip_security_restriction.value.name
          action           = ip_security_restriction.value.action
          ip_address_range = ip_security_restriction.value.ip_address_range
          description      = ip_security_restriction.value.description
        }
      }

      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weight
        content {
          label           = traffic_weight.value.label
          latest_revision = traffic_weight.value.latest_revision
          revision_suffix = traffic_weight.value.revision_suffix
          percentage      = traffic_weight.value.percentage
        }
      }
    }
  }

  tags = each.value.tags

  dynamic "template" {
    for_each = [each.value.template]
    content {
      min_replicas                     = template.value.min_replicas
      max_replicas                     = template.value.max_replicas
      cooldown_period_in_seconds       = template.value.cooldown_period_in_seconds
      polling_interval_in_seconds      = template.value.polling_interval_in_seconds
      termination_grace_period_seconds = template.value.termination_grace_period_seconds
      revision_suffix                  = template.value.revision_suffix

      dynamic "container" {
        for_each = template.value.container
        content {
          name    = container.value.name
          image   = container.value.image
          cpu     = container.value.cpu
          memory  = container.value.memory
          args    = container.value.args
          command = container.value.command

          dynamic "env" {
            for_each = container.value.env
            content {
              name        = env.key
              value       = env.value.value
              secret_name = env.value.secret_name
            }
          }

          dynamic "liveness_probe" {
            for_each = container.value.liveness_probe
            content {
              transport               = upper(liveness_probe.value.transport)
              port                    = liveness_probe.value.port
              host                    = liveness_probe.value.host
              path                    = liveness_probe.value.path
              initial_delay           = liveness_probe.value.initial_delay
              interval_seconds        = liveness_probe.value.interval_seconds
              timeout                 = liveness_probe.value.timeout
              failure_count_threshold = liveness_probe.value.failure_count_threshold

              dynamic "header" {
                for_each = liveness_probe.value.header
                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "readiness_probe" {
            for_each = container.value.readiness_probe
            content {
              transport               = upper(readiness_probe.value.transport)
              port                    = readiness_probe.value.port
              host                    = readiness_probe.value.host
              path                    = readiness_probe.value.path
              initial_delay           = readiness_probe.value.initial_delay
              interval_seconds        = readiness_probe.value.interval_seconds
              timeout                 = readiness_probe.value.timeout
              failure_count_threshold = readiness_probe.value.failure_count_threshold
              success_count_threshold = readiness_probe.value.success_count_threshold

              dynamic "header" {
                for_each = readiness_probe.value.header
                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "startup_probe" {
            for_each = container.value.startup_probe
            content {
              transport               = upper(startup_probe.value.transport)
              port                    = startup_probe.value.port
              host                    = startup_probe.value.host
              path                    = startup_probe.value.path
              initial_delay           = startup_probe.value.initial_delay
              interval_seconds        = startup_probe.value.interval_seconds
              timeout                 = startup_probe.value.timeout
              failure_count_threshold = startup_probe.value.failure_count_threshold

              dynamic "header" {
                for_each = startup_probe.value.header
                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "volume_mounts" {
            for_each = container.value.volume_mounts
            content {
              name     = volume_mounts.key
              path     = volume_mounts.value.path
              sub_path = volume_mounts.value.sub_path
            }
          }
        }
      }

      dynamic "init_container" {
        for_each = template.value.init_container
        content {
          name    = init_container.value.name
          image   = init_container.value.image
          cpu     = init_container.value.cpu
          memory  = init_container.value.memory
          args    = init_container.value.args
          command = init_container.value.command

          dynamic "env" {
            for_each = init_container.value.env
            content {
              name        = env.key
              value       = env.value.value
              secret_name = env.value.secret_name
            }
          }

          dynamic "volume_mounts" {
            for_each = init_container.value.volume_mounts
            content {
              name     = volume_mounts.key
              path     = volume_mounts.value.path
              sub_path = volume_mounts.value.sub_path
            }
          }
        }
      }

      dynamic "http_scale_rule" {
        for_each = template.value.http_scale_rule
        content {
          name                = http_scale_rule.key
          concurrent_requests = http_scale_rule.value.concurrent_requests

          dynamic "authentication" {
            for_each = http_scale_rule.value.authentication
            content {
              secret_name       = authentication.value.secret_name
              trigger_parameter = authentication.value.trigger_parameter
            }
          }
        }
      }

      dynamic "tcp_scale_rule" {
        for_each = template.value.tcp_scale_rule
        content {
          name                = tcp_scale_rule.key
          concurrent_requests = tcp_scale_rule.value.concurrent_requests

          dynamic "authentication" {
            for_each = tcp_scale_rule.value.authentication
            content {
              secret_name       = authentication.value.secret_name
              trigger_parameter = authentication.value.trigger_parameter
            }
          }
        }
      }

      dynamic "azure_queue_scale_rule" {
        for_each = template.value.azure_queue_scale_rule
        content {
          name         = azure_queue_scale_rule.key
          queue_name   = azure_queue_scale_rule.value.queue_name
          queue_length = azure_queue_scale_rule.value.queue_length

          dynamic "authentication" {
            for_each = azure_queue_scale_rule.value.authentication
            content {
              secret_name       = authentication.value.secret_name
              trigger_parameter = authentication.value.trigger_parameter
            }
          }
        }
      }

      dynamic "custom_scale_rule" {
        for_each = template.value.custom_scale_rule
        content {
          name             = custom_scale_rule.key
          custom_rule_type = custom_scale_rule.value.custom_rule_type
          metadata         = custom_scale_rule.value.metadata
          identity_id      = custom_scale_rule.value.identity_id

          dynamic "authentication" {
            for_each = custom_scale_rule.value.authentication
            content {
              secret_name       = authentication.value.secret_name
              trigger_parameter = authentication.value.trigger_parameter
            }
          }
        }
      }

      dynamic "volume" {
        for_each = template.value.volume
        content {
          name          = volume.key
          storage_name  = volume.value.storage_name
          storage_type  = volume.value.storage_type
          mount_options = volume.value.mount_options
        }
      }
    }
  }
}
