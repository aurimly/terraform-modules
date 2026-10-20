mock_provider "google" {}

run "native_and_enterprise" {
  command = plan

  variables {
    databases = {
      "default" = {
        name                              = "(default)"
        location_id                       = "nam5"
        type                              = "FIRESTORE_NATIVE"
        deletion_policy                   = "DELETE"
        point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
        delete_protection_state           = "DELETE_PROTECTION_ENABLED"
        concurrency_mode                  = "OPTIMISTIC"
        app_engine_integration_mode       = "DISABLED"
        cmek_config = {
          kms_key_name = "projects/example-prj/locations/us/keyRings/example/cryptoKeys/example"
        }
        tags = { "tagKeys/1" = "tagValues/2" }
      }
      "mongo" = {
        name                                = "example-mongo"
        location_id                         = "eur3"
        type                                = "FIRESTORE_NATIVE"
        database_edition                    = "ENTERPRISE"
        mongodb_compatible_data_access_mode = "DATA_ACCESS_MODE_ENABLED"
        realtime_updates_mode               = "REALTIME_UPDATES_MODE_ENABLED"
        deletion_policy                     = "DELETE"
      }
    }
  }
}

run "rejects_enterprise_mode_on_standard" {
  command = plan

  variables {
    databases = {
      "bad" = {
        name                  = "example-bad"
        location_id           = "nam5"
        type                  = "FIRESTORE_NATIVE"
        database_edition      = "STANDARD"
        realtime_updates_mode = "REALTIME_UPDATES_MODE_ENABLED"
      }
    }
  }

  expect_failures = [var.databases]
}

run "rejects_enterprise_with_datastore_type" {
  command = plan

  variables {
    databases = {
      "bad" = {
        name             = "example-bad"
        location_id      = "nam5"
        type             = "DATASTORE_MODE"
        database_edition = "ENTERPRISE"
      }
    }
  }

  expect_failures = [var.databases]
}

run "rejects_bad_type" {
  command = plan

  variables {
    databases = {
      "bad" = {
        name        = "example-bad"
        location_id = "nam5"
        type        = "MONGODB"
      }
    }
  }

  expect_failures = [var.databases]
}

run "rejects_uuid_shaped_name" {
  command = plan

  variables {
    databases = {
      "bad" = {
        name        = "1c2f8a52-8f8e-4f8f-8e8f-8f8e8f8e8f8e"
        location_id = "nam5"
        type        = "FIRESTORE_NATIVE"
      }
    }
  }

  expect_failures = [var.databases]
}

run "rejects_short_name" {
  command = plan

  variables {
    databases = {
      "bad" = {
        name        = "ab"
        location_id = "nam5"
        type        = "FIRESTORE_NATIVE"
      }
    }
  }

  expect_failures = [var.databases]
}

run "rejects_bad_concurrency_mode" {
  command = plan

  variables {
    databases = {
      "bad" = {
        name             = "example-bad"
        location_id      = "nam5"
        type             = "FIRESTORE_NATIVE"
        concurrency_mode = "SERIALIZABLE"
      }
    }
  }

  expect_failures = [var.databases]
}
