# aws/efs

Map-keyed module for Amazon EFS: file systems with lifecycle policies,
throughput/performance modes, encryption (on by default), backup and file
system policies, mount targets, and access points.

## Destroy semantics (read before using)

- Removing a file system key destroys its access points, mount targets,
  backup policy and file system policy first (graph edge), then the file
  system. The API refuses file system deletion while mount targets still
  exist; the reference ordering handles it. Deleting a mount target
  whose subnet is being deleted concurrently can leave it stuck in
  `deleting` — delete the EFS stack before the network stack.
- Encryption is immutable and this module defaults it **on**
  (`encrypted = true`; the provider default is `false`). Flipping
  `encrypted` after first apply forces replacement of the file system
  and every mount target and access point with it (unavailability
  window, new file system ID, new mount addresses). Turning encryption
  off requires delete + recreate.
- CMK lifecycle trap: a CMK that is destroyed or revoked (for example a
  bulk destroy tearing down `aws/kms` before this module) leaves the
  file system intact but permanently unreadable — no module-level guard
  is possible with a pass-through key. Destroy the EFS module before
  the KMS module.
- Access point `root_directory.creation_info` runs only at access point
  creation (first client connect). Changing `creation_info` afterwards
  does not re-chown the directory.
- `performance_mode` is immutable (replacement); throughput mode changes
  in place, except that after switching to Provisioned throughput (or
  changing the provisioned amount) the API blocks another mode switch or
  a decrease for 24 hours.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `file_systems` | `map(object)` | `{}` | Map of file systems keyed by an arbitrary unique ID. |
| `mount_targets` | `map(object)` | `{}` | Map of mount targets keyed by an arbitrary unique ID; each references its file system by `fs_key`. |
| `access_points` | `map(object)` | `{}` | Map of access points keyed by an arbitrary unique ID; each references its file system by `fs_key`. |

### `file_systems` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 1-64 characters (validated); becomes the `creation_token` (deterministic, replace-free idempotency) and the `Name` tag. |
| `performance_mode` | `string` | `generalPurpose` | `generalPurpose` or `maxIO` (validated). Immutable after creation. `maxIO` does not support Elastic throughput. |
| `throughput_mode` | `string` | `bursting` | `bursting`, `provisioned` or `elastic` (validated). Changes in place, with the 24-hour Provisioned window noted above. |
| `provisioned_throughput_in_mibps` | `number` | — | Provisioned throughput, only with `throughput_mode = provisioned` (validated). |
| `encrypted` | `bool` | `true` | Encryption at rest — **this module defaults to `true`, deviating from the provider default `false`**; immutable after creation (see Destroy semantics). With `kms_key_id` unset the file system encrypts under the AWS-managed `aws/efs` key: encryption is on, but the key is not consumer-controllable (no rotation or policy control) — pairing with `aws/kms` is optional, not required for encryption. |
| `kms_key_id` | `string` | — | KMS CMK ARN for encryption (pass-through, pair with `aws/kms`); requires `encrypted = true` (validated). Destroy the EFS module before the KMS module (CMK trap above). |
| `lifecycle_policy` | `object` | — | `{transition_to_ia, transition_to_archive, transition_to_primary_storage_class}`. IA and Archive values: `AFTER_1_DAY`, `AFTER_7_DAYS`, `AFTER_14_DAYS`, `AFTER_30_DAYS`, `AFTER_60_DAYS`, `AFTER_90_DAYS`, `AFTER_180_DAYS`, `AFTER_270_DAYS`, `AFTER_365_DAYS` (validated); primary storage class only `AFTER_1_ACCESS` (validated). Archive and primary-storage transitions require `transition_to_ia` (validated); Archive additionally requires Elastic throughput and General Purpose performance mode at the API. |
| `protection` | `object` | — | `{replication_overwrite}` — `ENABLED` or `DISABLED` (validated); protects the file system from being overwritten by a replication configuration. |
| `backup_policy` | `object` | — | `{status}` — `ENABLED` or `DISABLED` (validated); presence manages `aws_efs_backup_policy` (AWS Backup automatic backups). |
| `policy` | `string` | — | JSON file system policy (pass `jsonencode({...})`); presence manages `aws_efs_file_system_policy`. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `mount_targets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `fs_key` | `string` | — | Key of the file system entry this mount target belongs to (checked at plan/apply; a wrong key errors before any resource is created). |
| `subnet_id` | `string` | — | Subnet for the mount target (validated `subnet-...`); pair with the `aws/subnet` module. |
| `security_group_ids` | `set(string)` | — | Up to 5 security group IDs for the mount target (mapped to the provider's `security_groups` attribute); pair with the `aws/security-group` module (NFS port 2049). |
| `ip_address` | `string` | — | Address within the subnet to mount at. |
| `ip_address_type` | `string` | `IPV4_ONLY` | `IPV4_ONLY`, `IPV6_ONLY` or `DUAL_STACK` (validated); IPv6 requires a VPC with IPv6 support. |
| `ipv6_address` | `string` | — | IPv6 address to use; only with `IPV6_ONLY`/`DUAL_STACK` (validated). |

Mount targets have **no tags attribute in the API** — there is nothing
to name.

### `access_points` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `fs_key` | `string` | — | Key of the file system entry this access point belongs to (checked at plan/apply). |
| `posix_user` | `object` | — | `{uid, gid, secondary_gids}` — the operating system identity all file system requests use through this access point. Module-required: the API defaults to root `0:0` when omitted, which this module refuses implicitly by requiring the block. |
| `root_directory` | `object` | — | `{path, creation_info}`. `path` is the absolute directory exposed as root (up to four subdirectories); `creation_info` is `{owner_uid, owner_gid, permissions}` (octal string like `"0755"`, validated) and applies only when the path does not exist yet, at first client connect. |
| `tags` | `map(string)` | `{}` | Tags passed through as set — the API has no access point name attribute. |

## Outputs

`file_system_ids`, `file_system_arns`, `file_system_dns_names` — maps of
file system key => ID / ARN / DNS mount address.

`mount_target_ids`, `mount_target_ip_addresses`,
`mount_target_network_interface_ids` — maps of `"fsKey.mtKey"` key =>
mount target ID / IP / ENI ID.

`access_point_ids`, `access_point_arns` — maps of `"fsKey.apKey"` key =>
access point ID / ARN.

## Example

```hcl
file_systems = {
  "data" = {
    name = "example-data"

    lifecycle_policy = {
      transition_to_ia = "AFTER_30_DAYS"
    }

    backup_policy = {
      status = "ENABLED"
    }

    kms_key_id = dependency.kms.outputs.key_arns["efs"]

    tags = {
      Environment = "example"
    }
  },
}

mount_targets = {
  "az-a" = {
    fs_key             = "data"
    subnet_id          = dependency.network.outputs.private_subnet_ids["a"]
    security_group_ids = dependency.security_groups.outputs.security_group_ids["efs"]
  },
  "az-b" = {
    fs_key             = "data"
    subnet_id          = dependency.network.outputs.private_subnet_ids["b"]
    security_group_ids = dependency.security_groups.outputs.security_group_ids["efs"]
  },
}

access_points = {
  "app-data" = {
    fs_key = "data"

    posix_user = {
      uid = 1000
      gid = 1000
    }

    root_directory = {
      path = "/app"

      creation_info = {
        owner_uid   = 1000
        owner_gid   = 1000
        permissions = "0755"
      }
    }
  },
}
```

Mount from a client (Amazon Linux 2023, EFS mount helper):

```bash
mount -t efs -o tls,accesspoint=fsap-0123456789abcdef0 fs-0123456789abcdef0:/ /mnt/example-data
```

## Notes

- Pair with `aws/kms` (CMK for `kms_key_id`), `aws/security-group`
  (port 2049 from the clients' sources) and `aws/subnet` (one mount
  target per AZ for redundancy).
- Keys are arbitrary unique identifiers; mount target and access point
  resources use composite `"fsKey.mtKey"`/`"fsKey.apKey"` keys (the dot
  is reserved — map keys containing it are rejected at plan time).
- The access point's `posix_user` identity pairs with the
  `access_point_arns` output in IAM client policies
  (`elasticfilesystem:ClientRootAccess`, `ClientMount`,
  `ClientWrite` conditions).
- `throughput_mode = elastic` scales with workload and bills per
  request; `provisioned` bills for the provisioned rate — both carry
  cost implications the bursting baseline does not.
- Backup policies require AWS Backup to be usable in the account/region
  (the IAM side is consumer-owned).

## Import

`aws_efs_file_system` ← file system ID (`fs-...`).
`aws_efs_mount_target` ← mount target ID (`fsmt-...`).
`aws_efs_access_point` ← access point ID (`fsap-...`).
`aws_efs_backup_policy` ← file system ID (import into
`backup_policy[fs-key]` after inserting the file system).
`aws_efs_file_system_policy` ← file system ID (import into
`policy[fs-key]`).
