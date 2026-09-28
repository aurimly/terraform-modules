locals {
  mount_targets = { for k, v in var.mount_targets : "${v.fs_key}.${k}" => v }

  access_points = { for k, v in var.access_points : "${v.fs_key}.${k}" => v }
}

resource "aws_efs_file_system" "fs" {
  for_each = var.file_systems

  creation_token                  = each.value.name
  performance_mode                = each.value.performance_mode
  throughput_mode                 = each.value.throughput_mode
  provisioned_throughput_in_mibps = each.value.provisioned_throughput_in_mibps
  encrypted                       = each.value.encrypted
  kms_key_id                      = each.value.kms_key_id

  dynamic "lifecycle_policy" {
    for_each = each.value.lifecycle_policy != null ? [each.value.lifecycle_policy] : []

    content {
      transition_to_ia                    = lifecycle_policy.value.transition_to_ia
      transition_to_archive               = lifecycle_policy.value.transition_to_archive
      transition_to_primary_storage_class = lifecycle_policy.value.transition_to_primary_storage_class
    }
  }

  dynamic "protection" {
    for_each = each.value.protection != null ? [each.value.protection] : []

    content {
      replication_overwrite = protection.value.replication_overwrite
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_efs_backup_policy" "backup_policy" {
  for_each = { for k, t in var.file_systems : k => t if t.backup_policy != null }

  file_system_id = aws_efs_file_system.fs[each.key].id

  backup_policy {
    status = each.value.backup_policy.status
  }
}

resource "aws_efs_file_system_policy" "policy" {
  for_each = { for k, t in var.file_systems : k => t if t.policy != null }

  file_system_id = aws_efs_file_system.fs[each.key].id
  policy         = each.value.policy
}

resource "aws_efs_mount_target" "mount_target" {
  for_each = local.mount_targets

  file_system_id  = aws_efs_file_system.fs[each.value.fs_key].id
  subnet_id       = each.value.subnet_id
  ip_address      = each.value.ip_address
  ip_address_type = each.value.ip_address_type
  ipv6_address    = each.value.ipv6_address
  security_groups = each.value.security_group_ids

  lifecycle {
    precondition {
      condition     = contains(keys(var.file_systems), each.value.fs_key)
      error_message = "mount target \"${each.key}\": fs_key \"${each.value.fs_key}\" is not a key of the file_systems map."
    }
  }
}

resource "aws_efs_access_point" "access_point" {
  for_each = local.access_points

  file_system_id = aws_efs_file_system.fs[each.value.fs_key].id

  posix_user {
    uid            = each.value.posix_user.uid
    gid            = each.value.posix_user.gid
    secondary_gids = each.value.posix_user.secondary_gids
  }

  dynamic "root_directory" {
    for_each = each.value.root_directory != null ? [each.value.root_directory] : []

    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []

        content {
          owner_uid   = creation_info.value.owner_uid
          owner_gid   = creation_info.value.owner_gid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = each.value.tags

  lifecycle {
    precondition {
      condition     = contains(keys(var.file_systems), each.value.fs_key)
      error_message = "access point \"${each.key}\": fs_key \"${each.value.fs_key}\" is not a key of the file_systems map."
    }
  }
}
