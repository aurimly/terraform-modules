mock_provider "google" {}

run "cluster_with_node_pool_and_backup_plan" {
  command = plan

  variables {
    clusters = {
      "main" = {
        name       = "example-cluster"
        location   = "us-central1"
        project_id = "example-project-1234"
        release_channel = {
          channel = "REGULAR"
        }
        workload_identity = true
        ip_allocation_policy = {
          cluster_secondary_range_name  = "example-pods"
          services_secondary_range_name = "example-services"
        }
        node_pools = [
          {
            name = "example-pool"
            autoscaling = {
              min_node_count = 1
              max_node_count = 3
            }
            upgrade_settings = {
              max_surge       = 1
              max_unavailable = 0
            }
            node_config = {
              machine_type = "e2-standard-4"
              oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
            }
          },
        ]
        backup_plans = [
          {
            name = "example-backup"
            retention_policy = {
              backup_retain_days = 30
            }
            backup_schedule = {
              rpo_config = {
                target_rpo_minutes = 240
              }
            }
            backup_config = {
              all_namespaces = true
            }
          },
        ]
      },
    }
  }
}
