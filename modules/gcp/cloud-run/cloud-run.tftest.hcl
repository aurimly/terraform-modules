mock_provider "google" {}

run "services" {
  command = plan

  variables {
    services = {
      "api" = {
        name     = "example-api"
        location = "europe-west4"
        ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"
        template = {
          service_account = "api-rt@example-prj.iam.gserviceaccount.com"
          scaling = {
            min_instance_count = 1
            max_instance_count = 10
          }
          vpc_access = {
            egress = "ALL_TRAFFIC"
            network_interfaces = [
              {
                network    = "vpc-example"
                subnetwork = "sn-example-west4"
              },
            ]
          }
          containers = [
            {
              image = "europe-docker.pkg.dev/example-prj/example/example-api:1.2.3"
              env = [
                {
                  name = "DB_PASSWORD"
                  value_source = {
                    secret_key_ref = {
                      secret  = "db-password"
                      version = "latest"
                    }
                  }
                },
              ]
              resources = {
                limits = {
                  "cpu"    = "1"
                  "memory" = "512Mi"
                }
              }
              startup_probe = {
                http_get = {
                  path = "/healthz"
                }
              }
            },
          ]
        }
      }
      "web" = {
        name     = "example-web"
        location = "europe-west4"
        ingress  = "INGRESS_TRAFFIC_ALL"
        template = {
          containers = [{ image = "europe-docker.pkg.dev/example-prj/example/example-web:0.9.0" }]
        }
        role_bindings = {
          "public" = {
            role    = "roles/run.invoker"
            members = ["allUsers"]
          }
        }
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    services = {
      "api" = {
        name     = "Example_API"
        location = "europe-west4"
        template = {
          containers = [{ image = "europe-docker.pkg.dev/example-prj/example/example-api:1.2.3" }]
        }
      }
    }
  }

  expect_failures = [var.services]
}

run "rejects_connector_with_direct_vpc_egress" {
  command = plan

  variables {
    services = {
      "api" = {
        name     = "example-api"
        location = "europe-west4"
        template = {
          vpc_access = {
            connector = "projects/example-prj/locations/europe-west4/connectors/vpc-connector"
            network_interfaces = [
              {
                network    = "vpc-example"
                subnetwork = "sn-example-west4"
              },
            ]
          }
          containers = [{ image = "europe-docker.pkg.dev/example-prj/example/example-api:1.2.3" }]
        }
      }
    }
  }

  expect_failures = [var.services]
}

run "rejects_two_env_fields" {
  command = plan

  variables {
    services = {
      "api" = {
        name     = "example-api"
        location = "europe-west4"
        template = {
          containers = [
            {
              image = "europe-docker.pkg.dev/example-prj/example/example-api:1.2.3"
              env = [
                {
                  name  = "FOO"
                  value = "bar"
                  value_source = {
                    secret_key_ref = {
                      secret  = "db-password"
                      version = "latest"
                    }
                  }
                },
              ]
            },
          ]
        }
      }
    }
  }

  expect_failures = [var.services]
}

run "rejects_two_volume_types" {
  command = plan

  variables {
    services = {
      "api" = {
        name     = "example-api"
        location = "europe-west4"
        template = {
          volumes = [
            {
              name = "gcp-sql"
              gcs  = { bucket = "example-assets" }
              nfs  = { server = "10.0.0.5" }
            },
          ]
          containers = [{ image = "europe-docker.pkg.dev/example-prj/example/example-api:1.2.3" }]
        }
      }
    }
  }

  expect_failures = [var.services]
}

run "rejects_traffic_sum" {
  command = plan

  variables {
    services = {
      "api" = {
        name     = "example-api"
        location = "europe-west4"
        template = {
          containers = [{ image = "europe-docker.pkg.dev/example-prj/example/example-api:1.2.3" }]
        }
        traffic = [
          { percent = 50, type = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION", revision = "example-api-00001" },
          { percent = 30, type = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION", revision = "example-api-00002" },
        ]
      }
    }
  }

  expect_failures = [var.services]
}
