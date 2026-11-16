mock_provider "google-beta" {}

run "api_config_gateway" {
  command = plan

  variables {
    apis = {
      "catalog" = {
        api_id       = "catalog-api"
        display_name = "Catalog API"
      }
    }

    api_configs = {
      "v1" = {
        api           = "catalog"
        api_config_id = "catalog-v1"
        openapi_documents = [
          {
            document = {
              path     = "spec.yaml"
              contents = "c3BlYw=="
            }
          }
        ]
        gateway_config = {
          backend_config = {
            google_service_account = "api-backend@example-prj.iam.gserviceaccount.com"
          }
        }
      }
    }

    gateways = {
      "prod" = {
        api_config_key = "v1"
        gateway_id     = "catalog-gateway"
        region         = "europe-west4"
      }
    }
  }
}

run "grpc_config" {
  command = plan

  variables {
    apis = {
      "bookstore" = {
        api_id = "bookstore-api"
      }
    }

    api_configs = {
      "v1" = {
        api = "bookstore"
        grpc_services = [
          {
            file_descriptor_set = {
              path     = "api_descriptor.pb"
              contents = "ZGVzY3JpcHRvcg=="
            }
          }
        ]
        managed_service_configs = [
          {
            path     = "api_config.yaml"
            contents = base64encode("type: google.api.Service\nconfig_version: 3\nname: bookstore.endpoints.example-prj.cloud.goog")
          }
        ]
      }
    }

    gateways = {}
  }
}

run "openapi_with_grpc_fails" {
  command = plan

  variables {
    apis = {
      "catalog" = {
        api_id = "catalog-api"
      }
    }

    api_configs = {
      "broken" = {
        api = "catalog"
        openapi_documents = [
          {
            document = {
              path     = "spec.yaml"
              contents = "c3BlYw=="
            }
          }
        ]
        managed_service_configs = [
          {
            path     = "api_config.yaml"
            contents = "Y29uZmln"
          }
        ]
      }
    }

    gateways = {}
  }

  expect_failures = [var.api_configs]
}

run "grpc_without_service_configs_fails" {
  command = plan

  variables {
    apis = {
      "bookstore" = {
        api_id = "bookstore-api"
      }
    }

    api_configs = {
      "broken" = {
        api = "bookstore"
        grpc_services = [
          {
            file_descriptor_set = {
              path     = "api_descriptor.pb"
              contents = "ZGVzY3JpcHRvcg=="
            }
          }
        ]
      }
    }

    gateways = {}
  }

  expect_failures = [var.api_configs]
}

run "dangling_config_api_fails" {
  command = plan

  variables {
    apis = {
      "catalog" = {
        api_id = "catalog-api"
      }
    }

    api_configs = {
      "orphan" = {
        api           = "missing"
        api_config_id = "catalog-v1"
        openapi_documents = [
          {
            document = {
              path     = "spec.yaml"
              contents = "c3BlYw=="
            }
          }
        ]
      }
    }

    gateways = {}
  }

  expect_failures = [var.api_configs]
}

run "dangling_gateway_config_fails" {
  command = plan

  variables {
    apis = {
      "catalog" = {
        api_id = "catalog-api"
      }
    }

    api_configs = {
      "v1" = {
        api           = "catalog"
        api_config_id = "catalog-v1"
        openapi_documents = [
          {
            document = {
              path     = "spec.yaml"
              contents = "c3BlYw=="
            }
          }
        ]
      }
    }

    gateways = {
      "orphan" = {
        api_config_key = "missing"
        gateway_id     = "catalog-gateway"
      }
    }
  }

  expect_failures = [var.gateways]
}

run "contents_not_base64_fails" {
  command = plan

  variables {
    apis = {
      "catalog" = {
        api_id = "catalog-api"
      }
    }

    api_configs = {
      "broken" = {
        api           = "catalog"
        api_config_id = "catalog-v1"
        openapi_documents = [
          {
            document = {
              path     = "spec.yaml"
              contents = "not: base64!"
            }
          }
        ]
      }
    }

    gateways = {}
  }

  expect_failures = [var.api_configs]
}
