locals {
  iam_bindings = {
    for b in flatten([
      for key, job in var.jobs : [
        for binding_key, binding in job.role_bindings : {
          job_key     = key
          binding_key = binding_key
          name        = job.name
          role        = binding.role
          members     = binding.members
          condition   = binding.condition
          project_id  = job.project_id
        }
      ]
    ]) : "${b.job_key}/${b.binding_key}" => b
  }
}

resource "google_cloud_run_v2_job" "job" {
  for_each = var.jobs

  name                = each.value.name
  location            = each.value.location
  project             = each.value.project_id
  launch_stage        = each.value.launch_stage
  labels              = each.value.labels
  annotations         = each.value.annotations
  tags                = each.value.tags
  deletion_protection = each.value.deletion_protection
  deletion_policy     = each.value.deletion_policy

  dynamic "binary_authorization" {
    for_each = each.value.binary_authorization != null ? [each.value.binary_authorization] : []

    content {
      breakglass_justification = binary_authorization.value.breakglass_justification
      use_default              = binary_authorization.value.use_default
      policy                   = binary_authorization.value.policy
    }
  }

  template {
    parallelism = each.value.template.parallelism
    task_count  = each.value.template.task_count

    template {
      max_retries           = each.value.template.max_retries
      timeout               = each.value.template.timeout
      service_account       = each.value.template.service_account
      encryption_key        = each.value.template.encryption_key
      execution_environment = each.value.template.execution_environment

      dynamic "node_selector" {
        for_each = each.value.template.node_selector != null ? [each.value.template.node_selector] : []

        content {
          accelerator = node_selector.value.accelerator
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
                  secret_key_ref {
                    secret  = env.value.value_source.secret_key_ref.secret
                    version = env.value.value_source.secret_key_ref.version
                  }
                }
              }
            }
          }

          dynamic "resources" {
            for_each = containers.value.resources != null ? [containers.value.resources] : []

            content {
              limits = resources.value.limits
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
              sub_path   = volume_mounts.value.sub_path
            }
          }

          dynamic "startup_probe" {
            for_each = containers.value.startup_probe != null ? [containers.value.startup_probe] : []

            content {
              initial_delay_seconds = startup_probe.value.initial_delay_seconds
              timeout_seconds       = startup_probe.value.timeout_seconds
              period_seconds        = startup_probe.value.period_seconds
              failure_threshold     = startup_probe.value.failure_threshold

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
        }
      }
    }
  }
}

resource "google_cloud_run_v2_job_iam_binding" "binding" {
  for_each = local.iam_bindings

  name     = each.value.name
  location = var.jobs[each.value.job_key].location
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

  depends_on = [google_cloud_run_v2_job.job]
}
