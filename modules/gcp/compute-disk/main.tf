locals {
  attachments = {
    for k, a in var.snapshot_schedule_attachments : k => {
      disk_key   = a.disk_key
      policy_key = a.policy_key
      disk_name  = var.disks[a.disk_key].name
      disk_zone  = var.disks[a.disk_key].zone
      project_id = var.disks[a.disk_key].project_id
    }
  }
}

resource "google_compute_disk" "disk" {
  for_each = var.disks

  name                                  = each.value.name
  zone                                  = each.value.zone
  project                               = each.value.project_id
  type                                  = each.value.type
  size                                  = each.value.size
  description                           = each.value.description
  labels                                = each.value.labels
  architecture                          = each.value.architecture
  access_mode                           = each.value.access_mode
  physical_block_size_bytes             = each.value.physical_block_size_bytes
  provisioned_iops                      = each.value.provisioned_iops
  provisioned_throughput                = each.value.provisioned_throughput
  storage_pool                          = each.value.storage_pool
  enable_confidential_compute           = each.value.enable_confidential_compute
  deletion_policy                       = each.value.deletion_policy
  create_snapshot_before_destroy        = each.value.create_snapshot_before_destroy
  create_snapshot_before_destroy_prefix = each.value.create_snapshot_before_destroy_prefix
  image                                 = each.value.image
  snapshot                              = each.value.snapshot
  source_instant_snapshot               = each.value.source_instant_snapshot
  source_disk                           = each.value.source_disk
  source_storage_object                 = each.value.source_storage_object

  dynamic "guest_os_features" {
    for_each = each.value.guest_os_features

    content {
      type = guest_os_features.value.type
    }
  }

  dynamic "disk_encryption_key" {
    for_each = each.value.disk_encryption_key != null ? [each.value.disk_encryption_key] : []

    content {
      kms_key_self_link       = disk_encryption_key.value.kms_key_self_link
      kms_key_service_account = disk_encryption_key.value.kms_key_service_account
    }
  }
}

resource "google_compute_snapshot" "snapshot" {
  for_each = var.snapshots

  name                    = each.value.name
  project                 = each.value.project_id
  zone                    = each.value.zone
  source_disk             = each.value.source_disk
  source_instant_snapshot = each.value.source_instant_snapshot
  description             = each.value.description
  labels                  = each.value.labels
  storage_locations       = each.value.storage_locations
  snapshot_type           = each.value.snapshot_type
  chain_name              = each.value.chain_name
  deletion_policy         = each.value.deletion_policy
}

resource "google_compute_resource_policy" "snapshot_schedule" {
  for_each = var.snapshot_schedule_policies

  name            = each.value.name
  project         = each.value.project_id
  region          = each.value.region
  description     = each.value.description
  deletion_policy = each.value.deletion_policy

  dynamic "snapshot_schedule_policy" {
    for_each = [each.value.snapshot_schedule_policy]

    content {
      dynamic "schedule" {
        for_each = [1]

        content {
          dynamic "hourly_schedule" {
            for_each = snapshot_schedule_policy.value.hourly_schedule != null ? [snapshot_schedule_policy.value.hourly_schedule] : []

            content {
              hours_in_cycle = hourly_schedule.value.hours_in_cycle
              start_time     = hourly_schedule.value.start_time
            }
          }

          dynamic "daily_schedule" {
            for_each = snapshot_schedule_policy.value.daily_schedule != null ? [snapshot_schedule_policy.value.daily_schedule] : []

            content {
              days_in_cycle = daily_schedule.value.days_in_cycle
              start_time    = daily_schedule.value.start_time
            }
          }

          dynamic "weekly_schedule" {
            for_each = snapshot_schedule_policy.value.weekly_schedule != null ? [snapshot_schedule_policy.value.weekly_schedule] : []

            content {
              dynamic "day_of_weeks" {
                for_each = weekly_schedule.value.day_of_weeks

                content {
                  day        = day_of_weeks.value.day
                  start_time = day_of_weeks.value.start_time
                }
              }
            }
          }
        }
      }

      dynamic "retention_policy" {
        for_each = snapshot_schedule_policy.value.retention_policy != null ? [snapshot_schedule_policy.value.retention_policy] : []

        content {
          max_retention_days    = retention_policy.value.max_retention_days
          on_source_disk_delete = retention_policy.value.on_source_disk_delete
        }
      }

      dynamic "snapshot_properties" {
        for_each = snapshot_schedule_policy.value.snapshot_properties != null ? [snapshot_schedule_policy.value.snapshot_properties] : []

        content {
          labels            = snapshot_properties.value.labels
          storage_locations = snapshot_properties.value.storage_locations
          guest_flush       = snapshot_properties.value.guest_flush
          chain_name        = snapshot_properties.value.chain_name
        }
      }
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "attachment" {
  for_each = local.attachments

  name    = google_compute_resource_policy.snapshot_schedule[each.value.policy_key].name
  disk    = google_compute_disk.disk[each.value.disk_key].self_link
  zone    = each.value.disk_zone
  project = each.value.project_id
}
