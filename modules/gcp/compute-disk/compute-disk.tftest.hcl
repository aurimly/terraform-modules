mock_provider "google" {}

run "disks_and_snapshots_and_schedules" {
  command = plan

  variables {
    disks = {
      "data" = {
        name         = "example-data-disk"
        zone         = "us-central1-a"
        type         = "pd-ssd"
        size         = 100
        labels       = { env = "example" }
        access_mode  = "READ_WRITE_SINGLE"
        architecture = "X86_64"
        guest_os_features = [
          { type = "SECURE_BOOT" },
          { type = "UEFI_COMPATIBLE" }
        ]
        disk_encryption_key = {
          kms_key_self_link = "projects/example-prj/locations/us-central1/keyRings/example-kr/cryptoKeys/example-key"
        }
      }
      "restored" = {
        name            = "example-restored"
        zone            = "us-central1-a"
        snapshot        = "projects/example-prj/global/snapshots/example-snap"
        deletion_policy = "ABANDON"
      }
    }

    snapshots = {
      "nightly" = {
        name              = "example-nightly-snap"
        source_disk       = "example-data-disk"
        zone              = "us-central1-a"
        snapshot_type     = "STANDARD"
        storage_locations = ["us"]
        deletion_policy   = "PREVENT"
      }
    }

    snapshot_schedule_policies = {
      "daily" = {
        name   = "example-daily-snapshots"
        region = "us-central1"
        snapshot_schedule_policy = {
          daily_schedule = {
            days_in_cycle = 1
            start_time    = "10:00"
          }
          retention_policy = {
            max_retention_days    = 30
            on_source_disk_delete = "APPLY_RETENTION_POLICY"
          }
        }
      }
      "weekly" = {
        name   = "example-weekly-snapshots"
        region = "us-central1"
        snapshot_schedule_policy = {
          weekly_schedule = {
            day_of_weeks = [
              { day = "MONDAY", start_time = "10:00" },
              { day = "FRIDAY", start_time = "10:00" }
            ]
          }
          snapshot_properties = {
            labels            = { env = "example" }
            storage_locations = ["us"]
          }
        }
      }
    }

    snapshot_schedule_attachments = {
      "data" = {
        disk_key   = "data"
        policy_key = "daily"
      }
    }
  }
}

run "rejects_two_sources" {
  command = plan

  variables {
    disks = {
      "bad" = {
        name     = "example-bad"
        zone     = "us-central1-a"
        snapshot = "projects/example-prj/global/snapshots/example-snap"
        image    = "projects/example-prj/global/images/example-img"
      }
    }
  }

  expect_failures = [var.disks]
}

run "rejects_empty_disk_without_size" {
  command = plan

  variables {
    disks = {
      "bad" = {
        name = "example-bad"
        zone = "us-central1-a"
      }
    }
  }

  expect_failures = [var.disks]
}

run "rejects_bad_access_mode" {
  command = plan

  variables {
    disks = {
      "bad" = {
        name        = "example-bad"
        zone        = "us-central1-a"
        size        = 50
        access_mode = "READ_MULTI"
      }
    }
  }

  expect_failures = [var.disks]
}

run "rejects_snapshot_without_source" {
  command = plan

  variables {
    snapshots = {
      "bad" = {
        name = "example-bad-snap"
        zone = "us-central1-a"
      }
    }
  }

  expect_failures = [var.snapshots]
}

run "rejects_multi_day_daily_schedule" {
  command = plan

  variables {
    snapshot_schedule_policies = {
      "bad" = {
        name   = "example-bad-schedule"
        region = "us-central1"
        snapshot_schedule_policy = {
          daily_schedule = {
            days_in_cycle = 3
            start_time    = "10:00"
          }
        }
      }
    }
  }

  expect_failures = [var.snapshot_schedule_policies]
}

run "rejects_two_schedules" {
  command = plan

  variables {
    snapshot_schedule_policies = {
      "bad" = {
        name   = "example-bad-schedule"
        region = "us-central1"
        snapshot_schedule_policy = {
          daily_schedule = {
            days_in_cycle = 1
            start_time    = "10:00"
          }
          hourly_schedule = {
            hours_in_cycle = 3
            start_time     = "10:00"
          }
        }
      }
    }
  }

  expect_failures = [var.snapshot_schedule_policies]
}
