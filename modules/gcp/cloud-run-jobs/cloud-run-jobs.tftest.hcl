mock_provider "google" {}

run "job_with_bindings" {
  command = plan

  variables {
    jobs = {
      "nightly" = {
        name     = "example-nightly"
        location = "europe-west4"
        template = {
          task_count            = 10
          parallelism           = 5
          max_retries           = 2
          timeout               = "600s"
          service_account       = "rt@example-prj.iam.gserviceaccount.com"
          execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
          node_selector = {
            accelerator = "nvidia-l4"
          }
          vpc_access = {
            connector = "projects/example-prj/locations/europe-west4/connectors/example-vpc"
            egress    = "ALL_TRAFFIC"
          }
          containers = [
            {
              name    = "worker"
              image   = "europe-docker.pkg.dev/example-prj/example/example:1.2.3"
              command = ["./run"]
              args    = ["--nightly"]
              env = [
                { name = "PLAIN", value = "x" },
                {
                  name = "DB_PASSWORD"
                  value_source = {
                    secret_key_ref = { secret = "db-password", version = "latest" }
                  }
                },
              ]
              resources     = { limits = { "cpu" = "1", "memory" = "512Mi" } }
              ports         = [{ name = "h2c", container_port = 8080 }]
              volume_mounts = [{ name = "secrets", mount_path = "/etc/secrets", sub_path = "db" }]
              startup_probe = {
                initial_delay_seconds = 5
                http_get = {
                  path         = "/healthz"
                  http_headers = [{ name = "X-Probe", value = "1" }]
                }
              }
            },
          ]
          volumes = [
            { name = "secrets", secret = { secret = "db-password", default_mode = 384, items = [{ path = "db", version = "latest", mode = 384 }] } },
            { name = "db", cloud_sql_instance = { instances = ["example-prj:europe-west4:instance"] } },
            { name = "scratch", empty_dir = { medium = "MEMORY", size_limit = "1G" } },
            { name = "share", nfs = { server = "10.0.0.5", path = "/share", read_only = true } },
            { name = "gcs", gcs = { bucket = "example-bucket", mount_options = ["ro"], read_only = true } },
          ]
        }
        role_bindings = {
          "public" = { role = "roles/run.invoker", members = ["allUsers"] }
          "audit" = {
            role      = "roles/cloudtasks.enqueuer"
            members   = ["serviceAccount:other@example-prj.iam.gserviceaccount.com"]
            condition = { title = "t", expression = "true", description = "d" }
          }
        }
      }
    }
  }
}

run "rejects_parallelism_over_task_count" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name     = "example-bad"
        location = "europe-west4"
        template = {
          task_count  = 2
          parallelism = 5
          containers  = [{ image = "example:1" }]
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_two_env_sources" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name     = "example-bad"
        location = "europe-west4"
        template = {
          containers = [
            {
              image = "example:1"
              env = [
                {
                  name         = "BROKEN"
                  value        = "x"
                  value_source = { secret_key_ref = { secret = "s", version = "latest" } }
                },
              ]
            },
          ]
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_probe_with_two_types" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name     = "example-bad"
        location = "europe-west4"
        template = {
          containers = [
            {
              image = "example:1"
              startup_probe = {
                http_get   = { path = "/healthz" }
                tcp_socket = { port = 8080 }
              }
            },
          ]
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_volume_with_no_type" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name     = "example-bad"
        location = "europe-west4"
        template = {
          containers = [{ image = "example:1" }]
          volumes    = [{ name = "empty" }]
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_bad_execution_environment" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name     = "example-bad"
        location = "europe-west4"
        template = {
          containers            = [{ image = "example:1" }]
          execution_environment = "GEN2"
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_bad_deletion_policy" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name            = "example-bad"
        location        = "europe-west4"
        deletion_policy = "KEEP"
        template = {
          containers = [{ image = "example:1" }]
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_vpc_access_conflict" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name     = "example-bad"
        location = "europe-west4"
        template = {
          containers = [{ image = "example:1" }]
          vpc_access = {
            connector          = "projects/example-prj/locations/europe-west4/connectors/example-vpc"
            network_interfaces = [{ network = "vpc-example", subnetwork = "sn-example" }]
          }
        }
      }
    }
  }

  expect_failures = [var.jobs]
}

run "rejects_duplicate_role" {
  command = plan

  variables {
    jobs = {
      "bad" = {
        name     = "example-bad"
        location = "europe-west4"
        template = {
          containers = [{ image = "example:1" }]
        }
        role_bindings = {
          "a" = { role = "roles/run.invoker", members = ["allUsers"] }
          "b" = { role = "roles/run.invoker", members = ["group:team@example.com"] }
        }
      }
    }
  }

  expect_failures = [var.jobs]
}
