mock_provider "google" {}

run "functions" {
  command = plan

  variables {
    functions = {
      "http" = {
        name        = "example-http-fn"
        location    = "europe-west4"
        description = "HTTP example"
        build_config = {
          runtime    = "nodejs20"
          entrypoint = "helloHttp"
          source = {
            storage_source = {
              bucket = "example-gcf-source"
              object = "function-source.zip"
            }
          }
        }
        service_config = {
          available_memory = "256M"
          timeout_seconds  = 60
          ingress_settings = "ALLOW_INTERNAL_AND_GCLB"
        }
        role_bindings = {
          "invoker" = {
            role    = "roles/cloudfunctions.invoker"
            members = ["serviceAccount:svc@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
      "pubsub" = {
        name     = "example-pubsub-fn"
        location = "europe-west4"
        build_config = {
          runtime = "python312"
          source = {
            repo_source = {
              repo_name   = "example-repo"
              branch_name = "^main$"
            }
          }
        }
        event_trigger = {
          event_type   = "google.cloud.pubsub.topic.v1.messagePublished"
          pubsub_topic = "projects/example-prj/topics/example-topic"
          retry_policy = "RETRY_POLICY_RETRY"
        }
        role_bindings = {
          "invoker" = {
            role    = "roles/cloudfunctions.invoker"
            members = ["serviceAccount:svc@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
    }
  }
}

run "rejects_both_sources" {
  command = plan

  variables {
    functions = {
      "http" = {
        name     = "example-http-fn"
        location = "europe-west4"
        build_config = {
          runtime = "nodejs20"
          source = {
            storage_source = {
              bucket = "example-gcf-source"
              object = "function-source.zip"
            }
            repo_source = {
              repo_name = "example-repo"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.functions]
}

run "rejects_both_update_policies" {
  command = plan

  variables {
    functions = {
      "http" = {
        name     = "example-http-fn"
        location = "europe-west4"
        build_config = {
          runtime                 = "nodejs20"
          automatic_update_policy = true
          on_deploy_update_policy = true
          source = {
            storage_source = {
              bucket = "example-gcf-source"
              object = "function-source.zip"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.functions]
}

run "rejects_bad_ingress" {
  command = plan

  variables {
    functions = {
      "http" = {
        name     = "example-http-fn"
        location = "europe-west4"
        build_config = {
          runtime = "nodejs20"
          source = {
            storage_source = {
              bucket = "example-gcf-source"
              object = "function-source.zip"
            }
          }
        }
        service_config = {
          ingress_settings = "INGRESS_TRAFFIC_ALL"
        }
      }
    }
  }

  expect_failures = [var.functions]
}

run "rejects_connector_with_direct_vpc" {
  command = plan

  variables {
    functions = {
      "http" = {
        name     = "example-http-fn"
        location = "europe-west4"
        build_config = {
          runtime = "nodejs20"
          source = {
            storage_source = {
              bucket = "example-gcf-source"
              object = "function-source.zip"
            }
          }
        }
        service_config = {
          vpc_connector     = "projects/example-prj/locations/europe-west4/connectors/example-conn"
          direct_vpc_egress = "VPC_EGRESS_ALL_TRAFFIC"
        }
      }
    }
  }

  expect_failures = [var.functions]
}

run "rejects_duplicate_binding_roles" {
  command = plan

  variables {
    functions = {
      "http" = {
        name     = "example-http-fn"
        location = "europe-west4"
        build_config = {
          runtime = "nodejs20"
          source = {
            storage_source = {
              bucket = "example-gcf-source"
              object = "function-source.zip"
            }
          }
        }
        role_bindings = {
          "a" = {
            role    = "roles/cloudfunctions.invoker"
            members = ["serviceAccount:svc@example-prj.iam.gserviceaccount.com"]
          }
          "b" = {
            role    = "roles/cloudfunctions.invoker"
            members = ["serviceAccount:other@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
    }
  }

  expect_failures = [var.functions]
}
