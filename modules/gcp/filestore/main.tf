locals {
  backups = {
    for b in flatten([
      for instance_key, instance in var.instances : [
        for backup_key, backup in instance.backups : {
          instance_key = instance_key
          backup_key   = backup_key
          instance     = instance
          backup       = backup
        }
      ]
    ]) : "${b.instance_key}/${b.backup_key}" => b
  }
}

resource "google_filestore_instance" "instance" {
  for_each = var.instances

  name     = each.value.name
  project  = each.value.project_id
  location = each.value.location
  tier     = each.value.tier

  description = each.value.description
  protocol    = each.value.protocol
  labels      = each.value.labels

  kms_key_name                = each.value.kms_key_name
  deletion_protection_enabled = each.value.deletion_protection_enabled
  deletion_protection_reason  = each.value.deletion_protection_reason

  file_shares {
    capacity_gb   = each.value.file_shares.capacity_gb
    name          = each.value.file_shares.name
    source_backup = each.value.file_shares.source_backup

    dynamic "nfs_export_options" {
      for_each = each.value.file_shares.nfs_export_options

      content {
        ip_ranges   = nfs_export_options.value.ip_ranges
        access_mode = nfs_export_options.value.access_mode
        squash_mode = nfs_export_options.value.squash_mode
        anon_uid    = nfs_export_options.value.anon_uid
        anon_gid    = nfs_export_options.value.anon_gid
      }
    }
  }

  networks {
    network           = each.value.networks.network
    modes             = each.value.networks.modes
    connect_mode      = each.value.networks.connect_mode
    reserved_ip_range = each.value.networks.reserved_ip_range
  }

  dynamic "performance_config" {
    for_each = each.value.performance_config != null ? [each.value.performance_config] : []

    content {
      dynamic "iops_per_tb" {
        for_each = performance_config.value.iops_per_tb != null ? [performance_config.value.iops_per_tb] : []

        content {
          max_iops_per_tb = iops_per_tb.value.max_iops_per_tb
        }
      }

      dynamic "fixed_iops" {
        for_each = performance_config.value.fixed_iops != null ? [performance_config.value.fixed_iops] : []

        content {
          max_iops = fixed_iops.value.max_iops
        }
      }
    }
  }
}

resource "google_filestore_backup" "backup" {
  for_each = local.backups

  name              = each.value.backup.name
  location          = each.value.backup.location != null ? each.value.backup.location : each.value.instance.location
  project           = each.value.instance.project_id
  description       = each.value.backup.description
  labels            = each.value.backup.labels
  source_instance   = google_filestore_instance.instance[each.value.instance_key].id
  source_file_share = each.value.instance.file_shares.name
}
