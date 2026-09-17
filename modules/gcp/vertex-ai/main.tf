resource "google_vertex_ai_endpoint" "endpoint" {
  for_each = var.endpoints

  name                       = each.value.name
  display_name               = each.value.display_name
  location                   = each.value.location
  region                     = each.value.region
  project                    = each.value.project_id
  description                = each.value.description
  labels                     = each.value.labels
  dedicated_endpoint_enabled = each.value.dedicated_endpoint_enabled
  deletion_policy            = each.value.deletion_policy
  traffic_split              = each.value.traffic_split != null ? jsonencode(each.value.traffic_split) : null
  network                    = each.value.network

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

  dynamic "predict_request_response_logging_config" {
    for_each = each.value.predict_request_response_logging_config != null ? [each.value.predict_request_response_logging_config] : []

    content {
      enabled       = predict_request_response_logging_config.value.enabled
      sampling_rate = predict_request_response_logging_config.value.sampling_rate

      dynamic "bigquery_destination" {
        for_each = predict_request_response_logging_config.value.bigquery_destination != null ? [predict_request_response_logging_config.value.bigquery_destination] : []

        content {
          output_uri = bigquery_destination.value.output_uri
        }
      }
    }
  }
}

resource "google_vertex_ai_endpoint_with_model_garden_deployment" "model_garden" {
  for_each = var.model_garden_deployments

  publisher_model_name  = each.value.publisher_model_name
  hugging_face_model_id = each.value.hugging_face_model_id
  location              = each.value.location
  project               = each.value.project_id
  deletion_policy       = each.value.deletion_policy

  dynamic "model_config" {
    for_each = each.value.model_config != null ? [each.value.model_config] : []

    content {
      accept_eula                = model_config.value.accept_eula
      model_display_name         = model_config.value.model_display_name
      hugging_face_cache_enabled = model_config.value.hugging_face_cache_enabled
      hugging_face_access_token  = model_config.value.hugging_face_access_token

      dynamic "container_spec" {
        for_each = model_config.value.container_spec != null ? [model_config.value.container_spec] : []

        content {
          image_uri             = container_spec.value.image_uri
          predict_route         = container_spec.value.predict_route
          health_route          = container_spec.value.health_route
          command               = container_spec.value.command
          args                  = container_spec.value.args
          shared_memory_size_mb = container_spec.value.shared_memory_size_mb
          deployment_timeout    = container_spec.value.deployment_timeout

          dynamic "env" {
            for_each = container_spec.value.env

            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "ports" {
            for_each = container_spec.value.ports

            content {
              container_port = ports.value.container_port
            }
          }

          dynamic "grpc_ports" {
            for_each = container_spec.value.grpc_ports

            content {
              container_port = grpc_ports.value.container_port
            }
          }

          dynamic "startup_probe" {
            for_each = container_spec.value.startup_probe != null ? [container_spec.value.startup_probe] : []

            content {
              timeout_seconds       = startup_probe.value.timeout_seconds
              success_threshold     = startup_probe.value.success_threshold
              initial_delay_seconds = startup_probe.value.initial_delay_seconds
              period_seconds        = startup_probe.value.period_seconds
              failure_threshold     = startup_probe.value.failure_threshold

              dynamic "exec" {
                for_each = startup_probe.value.exec != null ? [startup_probe.value.exec] : []

                content {
                  command = exec.value.command
                }
              }

              dynamic "http_get" {
                for_each = startup_probe.value.http_get != null ? [startup_probe.value.http_get] : []

                content {
                  path   = http_get.value.path
                  port   = http_get.value.port
                  host   = http_get.value.host
                  scheme = http_get.value.scheme

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
                  host = tcp_socket.value.host
                }
              }
            }
          }

          dynamic "health_probe" {
            for_each = container_spec.value.health_probe != null ? [container_spec.value.health_probe] : []

            content {
              timeout_seconds       = health_probe.value.timeout_seconds
              success_threshold     = health_probe.value.success_threshold
              initial_delay_seconds = health_probe.value.initial_delay_seconds
              period_seconds        = health_probe.value.period_seconds
              failure_threshold     = health_probe.value.failure_threshold

              dynamic "exec" {
                for_each = health_probe.value.exec != null ? [health_probe.value.exec] : []

                content {
                  command = exec.value.command
                }
              }

              dynamic "http_get" {
                for_each = health_probe.value.http_get != null ? [health_probe.value.http_get] : []

                content {
                  path   = http_get.value.path
                  port   = http_get.value.port
                  host   = http_get.value.host
                  scheme = http_get.value.scheme

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
                for_each = health_probe.value.grpc != null ? [health_probe.value.grpc] : []

                content {
                  port    = grpc.value.port
                  service = grpc.value.service
                }
              }

              dynamic "tcp_socket" {
                for_each = health_probe.value.tcp_socket != null ? [health_probe.value.tcp_socket] : []

                content {
                  port = tcp_socket.value.port
                  host = tcp_socket.value.host
                }
              }
            }
          }

          dynamic "liveness_probe" {
            for_each = container_spec.value.liveness_probe != null ? [container_spec.value.liveness_probe] : []

            content {
              timeout_seconds       = liveness_probe.value.timeout_seconds
              success_threshold     = liveness_probe.value.success_threshold
              initial_delay_seconds = liveness_probe.value.initial_delay_seconds
              period_seconds        = liveness_probe.value.period_seconds
              failure_threshold     = liveness_probe.value.failure_threshold

              dynamic "exec" {
                for_each = liveness_probe.value.exec != null ? [liveness_probe.value.exec] : []

                content {
                  command = exec.value.command
                }
              }

              dynamic "http_get" {
                for_each = liveness_probe.value.http_get != null ? [liveness_probe.value.http_get] : []

                content {
                  path   = http_get.value.path
                  port   = http_get.value.port
                  host   = http_get.value.host
                  scheme = http_get.value.scheme

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
                  host = tcp_socket.value.host
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "endpoint_config" {
    for_each = each.value.endpoint_config != null ? [each.value.endpoint_config] : []

    content {
      endpoint_display_name      = endpoint_config.value.endpoint_display_name
      dedicated_endpoint_enabled = endpoint_config.value.dedicated_endpoint_enabled

      dynamic "private_service_connect_config" {
        for_each = endpoint_config.value.private_service_connect_config != null ? [endpoint_config.value.private_service_connect_config] : []

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
  }

  dynamic "deploy_config" {
    for_each = each.value.deploy_config != null ? [each.value.deploy_config] : []

    content {
      fast_tryout_enabled = deploy_config.value.fast_tryout_enabled
      system_labels       = deploy_config.value.system_labels

      dynamic "dedicated_resources" {
        for_each = deploy_config.value.dedicated_resources != null ? [deploy_config.value.dedicated_resources] : []

        content {
          min_replica_count      = dedicated_resources.value.min_replica_count
          max_replica_count      = dedicated_resources.value.max_replica_count
          required_replica_count = dedicated_resources.value.required_replica_count
          spot                   = dedicated_resources.value.spot

          machine_spec {
            machine_type             = dedicated_resources.value.machine_spec.machine_type
            accelerator_type         = dedicated_resources.value.machine_spec.accelerator_type
            accelerator_count        = dedicated_resources.value.machine_spec.accelerator_count
            tpu_topology             = dedicated_resources.value.machine_spec.tpu_topology
            multihost_gpu_node_count = dedicated_resources.value.machine_spec.multihost_gpu_node_count

            dynamic "reservation_affinity" {
              for_each = dedicated_resources.value.machine_spec.reservation_affinity != null ? [dedicated_resources.value.machine_spec.reservation_affinity] : []

              content {
                reservation_affinity_type = reservation_affinity.value.reservation_affinity_type
                key                       = reservation_affinity.value.key
                values                    = reservation_affinity.value.values
              }
            }
          }

          dynamic "autoscaling_metric_specs" {
            for_each = dedicated_resources.value.autoscaling_metric_specs

            content {
              metric_name = autoscaling_metric_specs.value.metric_name
              target      = autoscaling_metric_specs.value.target
            }
          }
        }
      }
    }
  }
}
