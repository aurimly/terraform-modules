variable "endpoints" {
  description = "Map of Vertex AI endpoints keyed by an arbitrary identifier. Each entry creates one google_vertex_ai_endpoint. Model upload/deployment for custom models happens outside Terraform; traffic_split manages routing by deployed-model id."
  type = map(object({
    name                       = string
    display_name               = string
    location                   = string
    region                     = optional(string)
    project_id                 = optional(string)
    description                = optional(string)
    labels                     = optional(map(string), {})
    dedicated_endpoint_enabled = optional(bool)
    deletion_policy            = optional(string)
    traffic_split              = optional(map(number))
    network                    = optional(string)
    encryption_spec = optional(object({
      kms_key_name = string
    }))
    private_service_connect_config = optional(object({
      enable_private_service_connect = bool
      project_allowlist              = optional(list(string))
      psc_automation_configs = optional(list(object({
        project_id = string
        network    = string
      })), [])
    }))
    predict_request_response_logging_config = optional(object({
      enabled       = optional(bool)
      sampling_rate = optional(number)
      bigquery_destination = optional(object({
        output_uri = string
      }))
    }))
  }))

  validation {
    condition     = alltrue([for k, s in var.endpoints : can(regex("^[1-9][0-9]{0,9}$", s.name))])
    error_message = "name must be numeric with no leading zeros and at most 10 digits (e.g. \"1234567890\"); Vertex AI endpoint names are numeric ids."
  }

  validation {
    condition     = alltrue([for k, s in var.endpoints : s.traffic_split == null || (alltrue([for p in s.traffic_split : p >= 0 && p <= 100]) && (length(s.traffic_split) == 0 || sum(values(s.traffic_split)) == 100))])
    error_message = "traffic_split percentages must each be 0 to 100 and sum to 100, unless the map is empty (an endpoint accepting no traffic)."
  }

  validation {
    condition     = alltrue([for k, s in var.endpoints : s.network == null || s.private_service_connect_config == null])
    error_message = "network and private_service_connect_config are mutually exclusive; set only one."
  }

  validation {
    condition     = alltrue([for k, s in var.endpoints : s.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], s.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, s in var.endpoints : s.predict_request_response_logging_config == null || s.predict_request_response_logging_config.sampling_rate == null || (s.predict_request_response_logging_config.sampling_rate > 0 && s.predict_request_response_logging_config.sampling_rate <= 1)])
    error_message = "predict_request_response_logging_config.sampling_rate must be a fraction in range (0,1] when set."
  }

  validation {
    condition = alltrue([
      for k, s in var.endpoints : alltrue(flatten([
        for kk, v in s.labels : [
          length(kk) <= 64,
          length(v) <= 64,
          !can(regex("[A-Z ]", kk)),
          !can(regex("[A-Z ]", v)),
        ]
      ]))
    ])
    error_message = "labels keys and values must be at most 64 characters and contain no uppercase ASCII letters or spaces (international characters are allowed, matching the provider)."
  }
}

variable "model_garden_deployments" {
  description = "Map of Model Garden / Hugging Face model deployments keyed by an arbitrary identifier. Each entry creates one google_vertex_ai_endpoint_with_model_garden_deployment (an endpoint plus a single deployed model)."
  type = map(object({
    publisher_model_name  = optional(string)
    hugging_face_model_id = optional(string)
    location              = string
    project_id            = optional(string)
    deletion_policy       = optional(string)
    model_config = optional(object({
      accept_eula                = optional(bool)
      model_display_name         = optional(string)
      hugging_face_cache_enabled = optional(bool)
      hugging_face_access_token  = optional(string)
      container_spec = optional(object({
        image_uri             = string
        predict_route         = optional(string)
        health_route          = optional(string)
        command               = optional(list(string))
        args                  = optional(list(string))
        env                   = optional(list(object({ name = string, value = string })), [])
        ports                 = optional(list(object({ container_port = number })), [])
        grpc_ports            = optional(list(object({ container_port = number })), [])
        shared_memory_size_mb = optional(number)
        deployment_timeout    = optional(string)
        startup_probe = optional(object({
          exec = optional(object({ command = list(string) }))
          http_get = optional(object({
            path   = optional(string)
            port   = optional(number)
            host   = optional(string)
            scheme = optional(string)
            http_headers = optional(list(object({
              name  = string
              value = optional(string)
            })), [])
          }))
          grpc = optional(object({
            port    = optional(number)
            service = optional(string)
          }))
          tcp_socket = optional(object({
            port = optional(number)
            host = optional(string)
          }))
          timeout_seconds       = optional(number)
          success_threshold     = optional(number)
          initial_delay_seconds = optional(number)
          period_seconds        = optional(number)
          failure_threshold     = optional(number)
        }))
        health_probe = optional(object({
          exec = optional(object({ command = list(string) }))
          http_get = optional(object({
            path   = optional(string)
            port   = optional(number)
            host   = optional(string)
            scheme = optional(string)
            http_headers = optional(list(object({
              name  = string
              value = optional(string)
            })), [])
          }))
          grpc = optional(object({
            port    = optional(number)
            service = optional(string)
          }))
          tcp_socket = optional(object({
            port = optional(number)
            host = optional(string)
          }))
          timeout_seconds       = optional(number)
          success_threshold     = optional(number)
          initial_delay_seconds = optional(number)
          period_seconds        = optional(number)
          failure_threshold     = optional(number)
        }))
        liveness_probe = optional(object({
          exec = optional(object({ command = list(string) }))
          http_get = optional(object({
            path   = optional(string)
            port   = optional(number)
            host   = optional(string)
            scheme = optional(string)
            http_headers = optional(list(object({
              name  = string
              value = optional(string)
            })), [])
          }))
          grpc = optional(object({
            port    = optional(number)
            service = optional(string)
          }))
          tcp_socket = optional(object({
            port = optional(number)
            host = optional(string)
          }))
          timeout_seconds       = optional(number)
          success_threshold     = optional(number)
          initial_delay_seconds = optional(number)
          period_seconds        = optional(number)
          failure_threshold     = optional(number)
        }))
      }))
    }))
    endpoint_config = optional(object({
      endpoint_display_name      = optional(string)
      dedicated_endpoint_enabled = optional(bool)
      private_service_connect_config = optional(object({
        enable_private_service_connect = bool
        project_allowlist              = optional(list(string))
        psc_automation_configs = optional(list(object({
          project_id = string
          network    = string
        })), [])
      }))
    }))
    deploy_config = optional(object({
      fast_tryout_enabled = optional(bool)
      system_labels       = optional(map(string))
      dedicated_resources = optional(object({
        min_replica_count      = number
        max_replica_count      = optional(number)
        required_replica_count = optional(number)
        spot                   = optional(bool)
        machine_spec = object({
          machine_type             = optional(string)
          accelerator_type         = optional(string)
          accelerator_count        = optional(number)
          tpu_topology             = optional(string)
          multihost_gpu_node_count = optional(number)
          reservation_affinity = optional(object({
            reservation_affinity_type = string
            key                       = optional(string)
            values                    = optional(list(string))
          }))
        })
        autoscaling_metric_specs = optional(list(object({
          metric_name = string
          target      = optional(number)
        })), [])
      }))
    }))
  }))

  validation {
    condition     = alltrue([for k, s in var.model_garden_deployments : (s.publisher_model_name != null) != (s.hugging_face_model_id != null)])
    error_message = "set exactly one of publisher_model_name or hugging_face_model_id."
  }

  validation {
    condition     = alltrue([for k, s in var.model_garden_deployments : s.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], s.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, s in var.model_garden_deployments : s.model_config == null || s.model_config.container_spec == null || alltrue(flatten([
        for p in [s.model_config.container_spec.startup_probe, s.model_config.container_spec.health_probe, s.model_config.container_spec.liveness_probe] : p == null ? [] : [length([
          for t in ["exec", "http_get", "grpc", "tcp_socket"] : t if p[t] != null
        ]) == 1]
      ]))
    ])
    error_message = "each probe must set exactly one of exec, http_get, grpc or tcp_socket."
  }

  validation {
    condition = alltrue([
      for k, s in var.model_garden_deployments : s.deploy_config == null || s.deploy_config.dedicated_resources == null || (
        s.deploy_config.dedicated_resources.min_replica_count >= 1 &&
        (s.deploy_config.dedicated_resources.max_replica_count == null || s.deploy_config.dedicated_resources.max_replica_count >= s.deploy_config.dedicated_resources.min_replica_count)
      )
    ])
    error_message = "dedicated_resources.min_replica_count must be at least 1, and max_replica_count must be greater than or equal to min_replica_count when set."
  }

  validation {
    condition = alltrue([
      for k, s in var.model_garden_deployments : s.deploy_config == null || s.deploy_config.dedicated_resources == null || alltrue([
        for m in s.deploy_config.dedicated_resources.autoscaling_metric_specs : can(regex("^aiplatform\\.googleapis\\.com/prediction/online/", m.metric_name)) && (m.target == null || (m.target >= 1 && m.target <= 100))
      ])
    ])
    error_message = "autoscaling_metric_specs.metric_name must start with aiplatform.googleapis.com/prediction/online/ and target must be 1 to 100 when set."
  }

  validation {
    condition = alltrue([
      for k, s in var.model_garden_deployments : s.deploy_config == null || s.deploy_config.dedicated_resources == null || s.deploy_config.dedicated_resources.machine_spec.reservation_affinity == null || (
        contains(["TYPE_UNSPECIFIED", "NO_RESERVATION", "ANY_RESERVATION", "SPECIFIC_RESERVATION"], s.deploy_config.dedicated_resources.machine_spec.reservation_affinity.reservation_affinity_type) &&
        (s.deploy_config.dedicated_resources.machine_spec.reservation_affinity.reservation_affinity_type != "SPECIFIC_RESERVATION" || (s.deploy_config.dedicated_resources.machine_spec.reservation_affinity.key != null && length(s.deploy_config.dedicated_resources.machine_spec.reservation_affinity.values) > 0))
      )
    ])
    error_message = "reservation_affinity.reservation_affinity_type must be one of TYPE_UNSPECIFIED, NO_RESERVATION, ANY_RESERVATION or SPECIFIC_RESERVATION; SPECIFIC_RESERVATION requires key and values to be set."
  }

  validation {
    condition = alltrue([
      for k, s in var.model_garden_deployments : s.deploy_config == null || s.deploy_config.dedicated_resources == null || s.deploy_config.dedicated_resources.machine_spec.accelerator_count == null || (
        s.deploy_config.dedicated_resources.machine_spec.accelerator_count >= 0 &&
        (s.deploy_config.dedicated_resources.machine_spec.accelerator_count == 0 || s.deploy_config.dedicated_resources.machine_spec.accelerator_type != null)
      )
    ])
    error_message = "machine_spec.accelerator_count must be 0 or greater; when greater than 0, accelerator_type must be set."
  }
}
