# gcp/filestore

Map-keyed module for Google Cloud Filestore instances with optional backups.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of Filestore instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Instance name; RFC1035, 1–63 chars (validated). Immutable; changing forces replacement. |
| `location` | `string` | — | Region (`us-central1`) or zone (`us-central1-a`). `BASIC_*` tiers are zonal; `ZONAL` takes a zone, `REGIONAL`/`ENTERPRISE` a region. Immutable. |
| `tier` | `string` | — | One of `STANDARD`, `PREMIUM`, `BASIC_HDD`, `BASIC_SSD`, `HIGH_SCALE_SSD`, `ZONAL`, `REGIONAL`, `ENTERPRISE` (validated; no `TIER_` prefix). `STANDARD`/`PREMIUM` are deprecated aliases of `BASIC_HDD`/`BASIC_SSD`. Immutable. |
| `project_id` | `string` | — | Project the instance lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `protocol` | `string` | — | One of `NFS_V3` (default when omitted), `NFS_V4_1` (validated). `NFS_V4_1` requires `HIGH_SCALE_SSD`, `ZONAL`, `REGIONAL` or `ENTERPRISE` tiers. |
| `kms_key_name` | `string` | — | CMEK crypto key (fully-qualified) for data encryption — pair with the `gcp/kms` module. |
| `deletion_protection_enabled` | `bool` | — | Block accidental deletion. Changing toggles protection in place. |
| `deletion_protection_reason` | `string` | — | Reason recorded when enabling protection. |
| `file_shares` | `object` | — | `{capacity_gb, name, source_backup, nfs_export_options}`; see the `file_shares` object table. Single file share per instance. |
| `networks` | `object` | — | `{network, modes, connect_mode, reserved_ip_range}`; see the `networks` object table. Single network block. |
| `performance_config` | `object` | — | `{iops_per_tb: {max_iops_per_tb}, fixed_iops: {max_iops}}` — supply exactly one of the two sub-objects with its value set; a populated value is required (validated). |
| `backups` | `map(object)` | `{}` | Backups of this instance's file share; see the `backups` object table. |

### `instances.file_shares` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `capacity_gb` | `number` | — | Share capacity in GiB, > 0 (validated). Per-tier minimums and increments apply and the API rejects undersized values: `BASIC_SSD` 2560 GiB min (10 GiB increments), `BASIC_HDD` 1024 GiB min (10 GiB increments), `HIGH_SCALE_SSD` 10240 GiB min (2560 GiB increments), `ZONAL`/`REGIONAL` 1024 GiB min (256 GiB increments; 100 GiB for small-capacity allow-listed projects), `ENTERPRISE` 1024 GiB min (256 GiB increments). |
| `name` | `string` | — | File share name, at most 16 characters (validated). Immutable; changing forces replacement. |
| `source_backup` | `string` | — | Fully-qualified backup to create the share from (restore). |
| `nfs_export_options` | `map(object)` | `{}` | Per-client NFS export rules keyed by an arbitrary ID: `{ip_ranges (list, required), access_mode (`READ_WRITE`/`READ_ONLY`, validated), squash_mode (`ROOT_SQUASH`/`NO_ROOT_SQUASH`, validated), anon_uid, anon_gid}`. `anon_uid`/`anon_gid` require `squash_mode = ROOT_SQUASH` (validated). |

### `instances.networks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `network` | `string` | — | VPC network name or self link (required). |
| `modes` | `list(string)` | — | Non-empty list of `MODE_IPV4` and/or `MODE_IPV6` (validated). |
| `connect_mode` | `string` | — | One of `DIRECT_PEERING` (provider default when omitted), `PRIVATE_SERVICE_ACCESS` (validated). The `PRIVATE_SERVICE_CONNECT` mode (with `psc_config`) is not supported by this module. |
| `reserved_ip_range` | `string` | — | For `PRIVATE_SERVICE_ACCESS`: the name of an allocated range (pair with `gcp/private-service-connect`). For `DIRECT_PEERING`: a `/29` CIDR block. Omit for auto-selection. Set `connect_mode` explicitly when using `PRIVATE_SERVICE_ACCESS` — the semantics of `reserved_ip_range` differ per mode. |

### `instances.backups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Backup name; RFC1035, 1–63 chars (validated). Immutable. |
| `location` | `string` | — | Backup location; defaults to the instance location. A zone yields a zonal backup, a region a regional (cross-zone) backup; cross-region backups are allowed. |
| `description` | `string` | — | Human-readable description. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |

## Outputs

`instance_ids` — map of instance key => fully-qualified instance id.
`instance_ips` — map of instance key => IP addresses of the instance networks
(the endpoints NFS clients mount `/{file_shares.name}` from).
`backup_ids` — map of composite backup key (`instance key/backup key`) =>
fully-qualified backup id.

## Example

```hcl
instances = {
  "shared-storage" = {
    name     = "filestore-example-prd-euw4-01"
    location = "europe-west4-a"
    tier     = "BASIC_SSD"

    file_shares = {
      capacity_gb = 10240 # 10 TB
      name        = "share1"

      nfs_export_options = {
        "vpc-clients" = {
          ip_ranges   = ["10.10.0.0/16"]
          access_mode = "READ_WRITE"
          squash_mode = "ROOT_SQUASH"
          anon_uid    = 65534
          anon_gid    = 65534
        }
      }
    }

    networks = {
      network           = "projects/example-network-project/global/networks/example-vpc"
      modes             = ["MODE_IPV4"]
      connect_mode      = "PRIVATE_SERVICE_ACCESS"
      reserved_ip_range = "example-vpc-psc"
    }

    backups = {
      "daily" = {
        name     = "filestore-example-prd-euw4-01-backup"
        location = "europe-west4"
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — the key only decouples
  your config from the names.
- Pair with `gcp/project-services` (`file.googleapis.com`) when the target project
  does not have the Filestore API enabled yet; this module does not enable APIs
  itself.
- For `connect_mode = PRIVATE_SERVICE_ACCESS` a service networking connection with
  allocated ranges must exist first — pair with `gcp/private-service-connect` and
  reference its range name in `reserved_ip_range`.
- `name`, `location`, `tier`, `file_shares` and `networks` are immutable or
  restricted: changing them replaces the instance (a 10 TB share takes a while to
  re-provision). `capacity_gb` is growable in place within the tier's rules.
- Backups are `google_filestore_backup` resources bound to this instance and its
  (single) file share; scheduled backups pair with `gcp/cloud-scheduler` + a backup
  function. Restoring means a new instance with `file_shares.source_backup` set.
- NFS export options are keyed per client-range: each map entry adds one
  `nfs_export_options` block. Omit the map entirely to keep default export
  behavior (`READ_WRITE` for all clients, `NO_ROOT_SQUASH`).
- CMEK (`kms_key_name`) requires the KMS key to grant the Filestore service agent
  `roles/cloudkms.cryptoKeyEncrypterDecrypter` — grant it consumer-side (same
  pattern as the `gcp/kms` README GCS example).

## Import

`google_filestore_instance` ←
`projects/{project}/locations/{location}/instances/{name}` (also
`{location}/{instance}` — note the two-part form).
`google_filestore_backup` ←
`projects/{project}/locations/{location}/backups/{name}` (also `{location}/{backup}`).
