mock_provider "google" {}

run "secrets" {
  command = plan

  variables {
    secrets = {
      "db-password" = {
        secret_id = "example-db-password"
        replication = {
          user_managed = {
            replicas = [
              { location = "europe-west4" },
              { location = "europe-west1", customer_managed_encryption = { kms_key_name = "projects/example-prj/locations/europe-west1/keyRings/example-kr/cryptoKeys/example-key" } },
            ]
          }
        }
        versions = {
          "1" = { secret_data = "example-value", enabled = true, deletion_policy = "DISABLE" }
        }
        role_bindings = {
          "accessors" = {
            role    = "roles/secretmanager.secretAccessor"
            members = ["serviceAccount:api-rt@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
      "app-config" = {
        secret_id = "example-app-config"
        replication = {
          auto = {
            customer_managed_encryption = { kms_key_name = "projects/example-prj/locations/us-central1/keyRings/example-kr/cryptoKeys/example-key" }
          }
        }
        rotation = {
          next_rotation_time = "2026-01-15T08:00:00Z"
          rotation_period    = "2592000s"
        }
        topics = [
          { name = "projects/example-prj/topics/example-secret-notifications" },
        ]
        version_destroy_ttl = "86400s"
      }
    }
  }
}

run "rejects_two_replication_modes" {
  command = plan

  variables {
    secrets = {
      "db-password" = {
        secret_id = "example-db-password"
        replication = {
          auto         = {}
          user_managed = { replicas = [{ location = "europe-west4" }] }
        }
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_version_without_payload" {
  command = plan

  variables {
    secrets = {
      "db-password" = {
        secret_id = "example-db-password"
        versions = {
          "1" = { enabled = true }
        }
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_rotation_without_topics" {
  command = plan

  variables {
    secrets = {
      "app-config" = {
        secret_id = "example-app-config"
        rotation = {
          next_rotation_time = "2026-01-15T08:00:00Z"
          rotation_period    = "2592000s"
        }
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_version_deletion_policy" {
  command = plan

  variables {
    secrets = {
      "db-password" = {
        secret_id = "example-db-password"
        versions = {
          "1" = { secret_data = "example-value", deletion_policy = "SKIP" }
        }
      }
    }
  }

  expect_failures = [var.secrets]
}
