locals {
  iam_bindings = {
    for b in flatten([
      for key, service in var.services : [
        for binding_key, binding in service.role_bindings : {
          service_key = key
          binding_key = binding_key
          name        = service.name
          role        = binding.role
          members     = binding.members
          condition   = binding.condition
          project_id  = service.project_id
        }
      ]
    ]) : "${b.service_key}/${b.binding_key}" => b
  }
}

resource "google_cloud_run_v2_service" "service" {
  for_each = var.services

  name                = each.value.name
  location            = each.value.location
  project             = each.value.project_id
  description         = each.value.description
  ingress             = each.value.ingress
  launch_stage        = each.value.launch_stage
  labels              = each.value.labels
  annotations         = each.value.annotations
  deletion_protection = each.value.deletion_protection

  dynamic "binary_authorization" {
    for_each = each.value.binary_authorization != null ? [each.value.binary_authorization] : []

    content {
      breakglass_justification = binary_authorization.value.breakglass_justification
      use_default              = binary_authorization.value.use_default
      policy                   = binary_authorization.value.policy
    }
  }

  template {
    encryption_key                   = each.value.template.encryption_key
    service_account                  = each.value.template.service_account
    timeout                          = each.value.template.timeout
    max_instance_request_concurrency = each.value.template.max_instance_request_concurrency

    dynamic "containers" {
      for_each = each.value.template.containers

      content {
        name    = containers.value.name
        image   = containers.value.image
        command = containers.value.command
        args    = containers.value.args

        dynamic "env" {
          for_each = containers.value.env

          content {
            name  = env.value.name
            value = env.value.value

            dynamic "value_source" {
              for_each = env.value.value_source != null ? [env.value.value_source] : []

              content {
                dynamic "secret_key_ref" {
                  for_each = env.value.value_source.secret_key_ref != null ? [env.value.value_source.secret_key_ref] : []

                  content {
                    secret  = secret_key_ref.value.secret
                    version = secret_key_ref.value.version
                  }
                }
              }
            }
          }
        }

        dynamic "resources" {
          for_each = containers.value.resources != null ? [containers.value.resources] : []

          content {
            limits            = resources.value.limits
            startup_cpu_boost = resources.value.startup_cpu_boost
            cpu_idle          = resources.value.cpu_idle
          }
        }

        dynamic "ports" {
          for_each = containers.value.ports

          content {
            name           = ports.value.name
            container_port = ports.value.container_port
          }
        }

        dynamic "volume_mounts" {
          for_each = containers.value.volume_mounts

          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }

        dynamic "startup_probe" {
          for_each = containers.value.startup_probe != null ? [containers.value.startup_probe] : []

          content {
            timeout_seconds   = startup_probe.value.timeout_seconds
            period_seconds    = startup_probe.value.period_seconds
            failure_threshold = startup_probe.value.failure_threshold

            dynamic "http_get" {
              for_each = startup_probe.value.http_get != null ? [startup_probe.value.http_get] : []

              content {
                path = http_get.value.path

                dynamic "http_headers" {
                  for_each = http_get.value.http_headers

                  content {
                    name  = http_headers.value.name
                    value = http_headers.value.value
                  }
                }
              }
            }

            dynamic "grpc" {
              for_each = startup_probe.value.grpc != null ? [startup_probe.value.grpc] : []

              content {
                port    = grpc.value.port
                service = grpc.value.service
              }
            }

            dynamic "tcp_socket" {
              for_each = startup_probe.value.tcp_socket != null ? [startup_probe.value.tcp_socket] : []

              content {
                port = tcp_socket.value.port
              }
            }
          }
        }

        dynamic "liveness_probe" {
          for_each = containers.value.liveness_probe != null ? [containers.value.liveness_probe] : []

          content {
            initial_delay_seconds = liveness_probe.value.initial_delay_seconds
            timeout_seconds       = liveness_probe.value.timeout_seconds
            period_seconds        = liveness_probe.value.period_seconds
            failure_threshold     = liveness_probe.value.failure_threshold

            dynamic "http_get" {
              for_each = liveness_probe.value.http_get != null ? [liveness_probe.value.http_get] : []

              content {
                path = http_get.value.path

                dynamic "http_headers" {
                  for_each = http_get.value.http_headers

                  content {
                    name  = http_headers.value.name
                    value = http_headers.value.value
                  }
                }
              }
            }

            dynamic "grpc" {
              for_each = liveness_probe.value.grpc != null ? [liveness_probe.value.grpc] : []

              content {
                port    = grpc.value.port
                service = grpc.value.service
              }
            }

            dynamic "tcp_socket" {
              for_each = liveness_probe.value.tcp_socket != null ? [liveness_probe.value.tcp_socket] : []

              content {
                port = tcp_socket.value.port
              }
            }
          }
        }
      }
    }

    dynamic "scaling" {
      for_each = each.value.template.scaling != null ? [each.value.template.scaling] : []

      content {
        min_instance_count = scaling.value.min_instance_count
        max_instance_count = scaling.value.max_instance_count
      }
    }

    dynamic "vpc_access" {
      for_each = each.value.template.vpc_access != null ? [each.value.template.vpc_access] : []

      content {
        connector = vpc_access.value.connector
        egress    = vpc_access.value.egress

        dynamic "network_interfaces" {
          for_each = vpc_access.value.network_interfaces

          content {
            network    = network_interfaces.value.network
            subnetwork = network_interfaces.value.subnetwork
            tags       = network_interfaces.value.tags
          }
        }
      }
    }

    dynamic "volumes" {
      for_each = each.value.template.volumes

      content {
        name = volumes.value.name

        dynamic "secret" {
          for_each = volumes.value.secret != null ? [volumes.value.secret] : []

          content {
            secret       = secret.value.secret
            default_mode = secret.value.default_mode

            dynamic "items" {
              for_each = secret.value.items

              content {
                path    = items.value.path
                version = items.value.version
                mode    = items.value.mode
              }
            }
          }
        }

        dynamic "cloud_sql_instance" {
          for_each = volumes.value.cloud_sql_instance != null ? [volumes.value.cloud_sql_instance] : []

          content {
            instances = cloud_sql_instance.value.instances
          }
        }

        dynamic "nfs" {
          for_each = volumes.value.nfs != null ? [volumes.value.nfs] : []

          content {
            server    = nfs.value.server
            path      = nfs.value.path
            read_only = nfs.value.read_only
          }
        }

        dynamic "gcs" {
          for_each = volumes.value.gcs != null ? [volumes.value.gcs] : []

          content {
            bucket        = gcs.value.bucket
            mount_options = gcs.value.mount_options
            read_only     = gcs.value.read_only
          }
        }

        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir != null ? [volumes.value.empty_dir] : []

          content {
            medium     = empty_dir.value.medium
            size_limit = empty_dir.value.size_limit
          }
        }
      }
    }
  }

  dynamic "traffic" {
    for_each = each.value.traffic

    content {
      percent  = traffic.value.percent
      type     = traffic.value.type
      revision = traffic.value.revision
      tag      = traffic.value.tag
    }
  }
}

resource "google_cloud_run_v2_service_iam_binding" "binding" {
  for_each = local.iam_bindings

  name     = each.value.name
  location = var.services[each.value.service_key].location
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

  depends_on = [google_cloud_run_v2_service.service]
}
