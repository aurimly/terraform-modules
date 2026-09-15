mock_provider "google" {}

run "clusters" {
  command = plan

  variables {
    clusters = {
      "spark" = {
        name                          = "example-spark"
        region                        = "europe-west1"
        graceful_decommission_timeout = "600s"
        cluster_config = {
          staging_bucket = "example-prj-dataproc-staging"
          software_config = {
            image_version       = "2.2.50-rocky9"
            override_properties = { "dataproc:dataproc.allow.zero.workers" = "true" }
            optional_components = ["ZEPPELIN"]
          }
          gce_cluster_config = {
            subnetwork             = "projects/example-prj/regions/europe-west1/subnetworks/example-sn"
            zone                   = "europe-west1-b"
            internal_ip_only       = true
            service_account        = "dataproc-wkr@example-prj.iam.gserviceaccount.com"
            service_account_scopes = ["cloud-platform"]
            tags                   = ["dataproc"]
            metadata               = { "owner" = "team" }
            shielded_instance_config = {
              enable_secure_boot = true
            }
          }
          master_config = {
            num_instances = 1
            machine_type  = "n2-standard-4"
            disk_config   = { boot_disk_type = "pd-ssd", boot_disk_size_gb = 100 }
          }
          worker_config = {
            num_instances     = 2
            machine_type      = "n2-standard-4"
            min_num_instances = 2
            disk_config       = { boot_disk_size_gb = 100, num_local_ssds = 1 }
            accelerators = [
              { accelerator_type = "nvidia-tesla-t4", accelerator_count = 1 },
            ]
          }
          preemptible_worker_config = {
            num_instances  = 2
            preemptibility = "SPOT"
            disk_config    = { boot_disk_size_gb = 100 }
          }
          initialization_actions = [
            { script = "gs://example-bucket/bootstrap.sh", timeout_sec = 500 },
          ]
          encryption_config = {
            kms_key_name = "projects/example-prj/locations/europe-west1/keyRings/example-kr/cryptoKeys/example-key"
          }
          lifecycle_config = {
            idle_delete_ttl  = "1800s"
            auto_delete_time = "2026-12-31T00:00:00Z"
          }
          autoscaling_config = {
            policy_uri = "projects/example-prj/locations/europe-west1/autoscalingPolicies/example-policy"
          }
        }
        role_bindings = {
          "users" = {
            role    = "roles/dataproc.viewer"
            members = ["group:example-analysts@example.com"]
          }
        }
      }
      "simple" = {
        name   = "example-simple"
        region = "europe-west1"
      }
    }
  }
}

run "rejects_bad_preemptibility" {
  command = plan

  variables {
    clusters = {
      "spark" = {
        name   = "example-spark"
        region = "europe-west1"
        cluster_config = {
          preemptible_worker_config = {
            num_instances  = 2
            preemptibility = "PREEMPTIBLE_LEGACY"
          }
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

run "rejects_network_and_subnetwork" {
  command = plan

  variables {
    clusters = {
      "spark" = {
        name   = "example-spark"
        region = "europe-west1"
        cluster_config = {
          gce_cluster_config = {
            network    = "vpc-example-prd"
            subnetwork = "example-sn"
          }
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

run "rejects_negative_local_ssds" {
  command = plan

  variables {
    clusters = {
      "spark" = {
        name   = "example-spark"
        region = "europe-west1"
        cluster_config = {
          worker_config = {
            num_instances = 2
            disk_config   = { num_local_ssds = -1 }
          }
        }
      }
    }
  }

  expect_failures = [var.clusters]
}
