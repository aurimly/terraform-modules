mock_provider "google" {}

run "instances" {
  command = plan

  variables {
    instances = {
      "main" = {
        name          = "example-bt-main"
        edition       = "ENTERPRISE_PLUS"
        force_destroy = true
        clusters = {
          "eu" = {
            cluster_id   = "example-bt-eu"
            zone         = "europe-west4-a"
            num_nodes    = 3
            storage_type = "HDD"
          }
          "eu2" = {
            cluster_id = "example-bt-eu2"
            zone       = "europe-west4-b"
            autoscaling_config = {
              min_nodes  = 1
              max_nodes  = 3
              cpu_target = 50
            }
          }
        }
        tables = {
          "events" = {
            name                    = "event-stream"
            split_keys              = ["a", "b"]
            deletion_protection     = "PROTECTED"
            change_stream_retention = "24h0m0s"
            column_families = {
              "raw" = {}
              "agg" = { type = "intsum" }
            }
            automated_backup_policy = {
              retention_period = "72h0m0s"
              frequency        = "24h0m0s"
            }
            gc_policies = {
              "raw" = {
                max_age = { duration = "168h" }
              }
              "agg" = {
                gc_rules = "{\"rules\":[{\"max_version\":10}]}"
              }
            }
            role_bindings = {
              "readers" = {
                role    = "roles/bigtable.reader"
                members = ["serviceAccount:etl@example-prj.iam.gserviceaccount.com"]
              }
            }
          }
        }
        app_profiles = {
          "hot-throughput" = {
            app_profile_id                = "hot-throughput"
            multi_cluster_routing_use_any = true
            standard_isolation            = { priority = "PRIORITY_MEDIUM" }
          }
          "single-writer" = {
            app_profile_id = "single-writer"
            single_cluster_routing = {
              cluster_id                 = "example-bt-eu"
              allow_transactional_writes = true
            }
          }
        }
        role_bindings = {
          "users" = {
            role    = "roles/bigtable.user"
            members = ["group:example-data@example.com"]
          }
        }
      }
    }
  }
}

run "rejects_cluster_num_nodes_and_autoscaling" {
  command = plan

  variables {
    instances = {
      "main" = {
        name = "example-bt-main"
        clusters = {
          "eu" = {
            cluster_id = "example-bt-eu"
            num_nodes  = 3
            autoscaling_config = {
              min_nodes  = 1
              max_nodes  = 3
              cpu_target = 50
            }
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_duplicate_cluster_zone" {
  command = plan

  variables {
    instances = {
      "main" = {
        name = "example-bt-main"
        clusters = {
          "eu" = {
            cluster_id = "example-bt-eu"
            zone       = "europe-west4-a"
            num_nodes  = 3
          }
          "eu2" = {
            cluster_id = "example-bt-eu2"
            zone       = "europe-west4-a"
            num_nodes  = 3
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_app_profile_routing_xor" {
  command = plan

  variables {
    instances = {
      "main" = {
        name = "example-bt-main"
        clusters = {
          "eu" = {
            cluster_id = "example-bt-eu"
            num_nodes  = 3
          }
        }
        app_profiles = {
          "bad" = {
            app_profile_id                = "bad"
            multi_cluster_routing_use_any = true
            single_cluster_routing = {
              cluster_id = "example-bt-eu"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_gc_policy_conflicting_rules" {
  command = plan

  variables {
    instances = {
      "main" = {
        name = "example-bt-main"
        clusters = {
          "eu" = {
            cluster_id = "example-bt-eu"
            num_nodes  = 3
          }
        }
        tables = {
          "events" = {
            name            = "event-stream"
            column_families = { "raw" = {} }
            gc_policies = {
              "raw" = {
                max_age  = { duration = "168h" }
                gc_rules = "{\"rules\":[{\"max_version\":10}]}"
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}
