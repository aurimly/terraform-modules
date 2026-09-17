mock_provider "google" {}

run "endpoints" {
  command = plan

  variables {
    model_garden_deployments = {}
    endpoints = {
      "serving" = {
        name         = "1234567890"
        display_name = "example-endpoint"
        location     = "europe-west4"
        network      = "projects/123456789012/global/networks/vpc-example"
        traffic_split = {
          "12345" = 100
        }
        encryption_spec = {
          kms_key_name = "projects/example-prj/locations/europe-west4/keyRings/example-kr/cryptoKeys/example-key"
        }
        predict_request_response_logging_config = {
          enabled       = true
          sampling_rate = 0.5
          bigquery_destination = {
            output_uri = "bq://example-prj.example-ds.example-table"
          }
        }
      }
      "psc" = {
        name         = "987654321"
        display_name = "example-psc-endpoint"
        location     = "europe-west4"
        private_service_connect_config = {
          enable_private_service_connect = true
          project_allowlist              = ["example-prj"]
          psc_automation_configs = [
            {
              project_id = "example-prj"
              network    = "projects/123456789012/global/networks/vpc-example"
            },
          ]
        }
      }
    }
  }
}

run "model_garden_deployments" {
  command = plan

  variables {
    endpoints = {}
    model_garden_deployments = {
      "gemma" = {
        publisher_model_name = "publishers/google/models/gemma@gemma-1.1-2b-it"
        location             = "europe-west4"
        model_config = {
          accept_eula = true
          container_spec = {
            image_uri     = "europe-docker.pkg.dev/example-prj/example/example-image:1.0.0"
            predict_route = "/predict"
            health_route  = "/health"
            env = [
              { name = "MODEL_ID", value = "example" },
            ]
            ports = [{ container_port = 8080 }]
            startup_probe = {
              http_get = {
                path = "/health"
                port = 8080
              }
            }
          }
        }
        endpoint_config = {
          endpoint_display_name      = "example-gemma-endpoint"
          dedicated_endpoint_enabled = true
        }
        deploy_config = {
          dedicated_resources = {
            machine_spec = {
              machine_type      = "g2-standard-12"
              accelerator_type  = "NVIDIA_L4"
              accelerator_count = 1
            }
            min_replica_count = 1
            max_replica_count = 3
            autoscaling_metric_specs = [
              {
                metric_name = "aiplatform.googleapis.com/prediction/online/cpu/utilization"
                target      = 80
              },
            ]
          }
        }
      }
      "qwen" = {
        hugging_face_model_id = "Qwen/Qwen3-0.6B"
        location              = "europe-west4"
        model_config = {
          accept_eula = true
        }
      }
    }
  }
}

run "rejects_non_numeric_endpoint_name" {
  command = plan

  variables {
    model_garden_deployments = {}
    endpoints = {
      "serving" = {
        name         = "endpoint-1"
        display_name = "example-endpoint"
        location     = "europe-west4"
      }
    }
  }

  expect_failures = [var.endpoints]
}

run "rejects_traffic_split_sum" {
  command = plan

  variables {
    model_garden_deployments = {}
    endpoints = {
      "serving" = {
        name         = "1234567890"
        display_name = "example-endpoint"
        location     = "europe-west4"
        traffic_split = {
          "11111" = 60
          "22222" = 30
        }
      }
    }
  }

  expect_failures = [var.endpoints]
}

run "rejects_network_with_psc" {
  command = plan

  variables {
    model_garden_deployments = {}
    endpoints = {
      "serving" = {
        name         = "1234567890"
        display_name = "example-endpoint"
        location     = "europe-west4"
        network      = "projects/123456789012/global/networks/vpc-example"
        private_service_connect_config = {
          enable_private_service_connect = true
        }
      }
    }
  }

  expect_failures = [var.endpoints]
}

run "rejects_bad_deletion_policy" {
  command = plan

  variables {
    model_garden_deployments = {}
    endpoints = {
      "serving" = {
        name            = "1234567890"
        display_name    = "example-endpoint"
        location        = "europe-west4"
        deletion_policy = "KEEP"
      }
    }
  }

  expect_failures = [var.endpoints]
}

run "rejects_two_model_sources" {
  command = plan

  variables {
    endpoints = {}
    model_garden_deployments = {
      "both" = {
        publisher_model_name  = "publishers/google/models/gemma@gemma-1.1-2b-it"
        hugging_face_model_id = "Qwen/Qwen3-0.6B"
        location              = "europe-west4"
      }
    }
  }

  expect_failures = [var.model_garden_deployments]
}

run "rejects_two_probe_types" {
  command = plan

  variables {
    endpoints = {}
    model_garden_deployments = {
      "gemma" = {
        publisher_model_name = "publishers/google/models/gemma@gemma-1.1-2b-it"
        location             = "europe-west4"
        model_config = {
          accept_eula = true
          container_spec = {
            image_uri = "europe-docker.pkg.dev/example-prj/example/example-image:1.0.0"
            startup_probe = {
              http_get = {
                path = "/health"
              }
              exec = {
                command = ["true"]
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.model_garden_deployments]
}

run "rejects_replica_bounds" {
  command = plan

  variables {
    endpoints = {}
    model_garden_deployments = {
      "gemma" = {
        publisher_model_name = "publishers/google/models/gemma@gemma-1.1-2b-it"
        location             = "europe-west4"
        deploy_config = {
          dedicated_resources = {
            machine_spec = {
              machine_type = "g2-standard-12"
            }
            min_replica_count = 3
            max_replica_count = 1
          }
        }
      }
    }
  }

  expect_failures = [var.model_garden_deployments]
}
