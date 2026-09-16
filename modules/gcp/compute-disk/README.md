# gcp/compute-disk

Map-keyed module for standalone persistent disks (`google_compute_disk`), disk
snapshots (`google_compute_snapshot`), snapshot schedule policies
(`google_compute_resource_policy`, snapshot-schedule only), and the
schedule-to-disk attachment (`google_compute_disk_resource_policy_attachment`).

This module is for disks managed independently of any instance: data disks
sourced from images, snapshots or other disks, hyperdisk tuning, and the
snapshot lifecycle. Instance-coupled disks (boot disk, attach-on-create) stay
in `gcp/compute-instance` / `gcp/instance-template`; attachment to instances is
out of scope — attach via `google_compute_attached_disk` in consumer code and
reference the `disk_self_links` output.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `disks` | `map(object)` | `{}` | Map of disks keyed by an arbitrary unique ID. |
| `snapshots` | `map(object)` | `{}` | Map of disk snapshots keyed by an arbitrary unique ID. |
| `snapshot_schedule_policies` | `map(object)` | `{}` | Map of snapshot schedule policies keyed by an arbitrary unique ID. |
| `snapshot_schedule_attachments` | `map(object)` | `{}` | Map of attachments keyed by an arbitrary unique ID. |

### `disks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Disk name, RFC1035 1–63 chars (validated). Immutable; changing forces recreation. |
| `zone` | `string` | — | Zone, e.g. `us-central1-a` (shape-validated). Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `type` | `string` | — | `pd-standard`, `pd-balanced`, `pd-ssd`, `pd-extreme`, `hyperdisk-balanced`, `hyperdisk-throughput`, `hyperdisk-extreme`. Changing forces recreation for non-hyperdisk types. |
| `size` | `number` | — | Size in GB; required for empty disks, increasing is in place, decreasing forces recreation. |
| `description` | `string` | — | Free-text description. |
| `labels` | `map(string)` | `{}` | Labels. |
| `architecture` | `string` | — | `X86_64` or `ARM64` (validated). |
| `access_mode` | `string` | — | `READ_WRITE_SINGLE`, `READ_WRITE_MANY` or `READ_ONLY_SINGLE` (validated); hyperdisk only. |
| `physical_block_size_bytes` | `number` | — | `4096` or `16384` (validated). Immutable. |
| `provisioned_iops` | `number` | — | Hyperdisk only. |
| `provisioned_throughput` | `number` | — | Hyperdisk only (MB/s). |
| `storage_pool` | `string` | — | Storage pool for hyperdisk. |
| `enable_confidential_compute` | `bool` | — | Confidential VM disks; requires `disk_encryption_key` (validated). |
| `deletion_policy` | `string` | `DELETE` | `DELETE`, `ABANDON` or `PREVENT` (validated). |
| `create_snapshot_before_destroy` | `bool` | — | Snapshot the disk before Terraform destroys it. |
| `create_snapshot_before_destroy_prefix` | `string` | — | Prefix for those snapshots. |
| `guest_os_features` | `list(object)` | `[]` | List of `{type}`, e.g. `SECURE_BOOT`, `UEFI_COMPATIBLE`, `MULTI_IP_SUBNET`, `WINDOWS`. |
| `image` | `string` | — | Source image; at most one source (validated). Immutable. |
| `snapshot` | `string` | — | Source snapshot; at most one source (validated). Immutable. |
| `source_instant_snapshot` | `string` | — | Source instant snapshot; at most one source (validated). Immutable. |
| `source_disk` | `string` | — | Source disk (cloning); at most one source (validated). Immutable. |
| `source_storage_object` | `string` | — | `gs://...` source archive; at most one source (validated). Immutable. |
| `disk_encryption_key` | `object` | — | CMEK only: `{kms_key_self_link, kms_key_service_account}`. Raw key material is intentionally not exposed (raw keys live in state); requires Compute Engine System service account `cryptoKeyEncrypter/Decrypter` on the key. Immutable. |

Sources and `size` are mutually exclusive trade-offs: a disk with no source must
set `size` (validated). Downsizing shrinks nothing — the disk is recreated and
data is lost.

### `snapshots` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Snapshot name, RFC1035 (validated). Immutable. |
| `source_disk` | `string` | — | Disk the snapshot is taken from; exactly one of `source_disk`/`source_instant_snapshot` (validated). Immutable. |
| `source_instant_snapshot` | `string` | — | Instant snapshot the snapshot is taken from (validated). Immutable. |
| `zone` | `string` | — | Zone of the source disk. Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Snapshots are global-scope resources. |
| `description` | `string` | — | Free-text description. |
| `labels` | `map(string)` | `{}` | Labels. |
| `storage_locations` | `list(string)` | — | Cloud Storage locations for the snapshot, e.g. `["us"]`. |
| `snapshot_type` | `string` | STANDARD | `STANDARD` or `ARCHIVE` (validated). |
| `chain_name` | `string` | — | Snapshot chain name for incremental snapshot chains. Immutable. |
| `deletion_policy` | `string` | DELETE | `DELETE`, `ABANDON` or `PREVENT` (validated). |

### `snapshot_schedule_policies` object

Scoped to `snapshot_schedule_policy` — instance placement/schedule policies
belong in consumer config. See
`google_compute_resource_policy`.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy name, RFC1035 (validated). Immutable. |
| `region` | `string` | — | Region, e.g. `us-central1` (shape-validated). Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `description` | `string` | — | Free-text description. |
| `deletion_policy` | `string` | DELETE | `DELETE`, `ABANDON` or `PREVENT` (validated). |
| `snapshot_schedule_policy` | `object` | — | Required; see the schedule/retention/properties tables below. |

#### `snapshot_schedule_policy` nested objects

Exactly one of `hourly_schedule`, `daily_schedule`, `weekly_schedule` (validated).

| Attribute | Type | Default | Description |
|---|---|---|---|
| `hourly_schedule` | `object` | — | `{hours_in_cycle, start_time}`; `hours_in_cycle` divides 24 evenly. |
| `daily_schedule` | `object` | — | `{days_in_cycle, start_time}`; `days_in_cycle` must be 1 for snapshot schedules (validated). |
| `weekly_schedule` | `object` | — | `{day_of_weeks}`; list of `{day, start_time}`, day in `MONDAY`..`SUNDAY`. |
| `retention_policy` | `object` | — | `{max_retention_days (>= 1, validated), on_source_disk_delete}`; `on_source_disk_delete` in `KEEP_AUTO_SNAPSHOTS`, `APPLY_RETENTION_POLICY`. |
| `snapshot_properties` | `object` | — | `{labels, storage_locations, guest_flush, chain_name}` applied to created snapshots. |

`start_time` is UTC, e.g. `"10:00"` or `"10:00:00"`.

### `snapshot_schedule_attachments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `disk_key` | `string` | — | Key into the `disks` map (plan-fail if missing). |
| `policy_key` | `string` | — | Key into the `snapshot_schedule_policies` map (plan-fail if missing). |

A plan-time check rejects configs that would already fail at apply only.

## Outputs

| Name | Description |
|---|---|
| `disk_names` | Map of disk key => disk name. |
| `disk_self_links` | Map of disk key => disk self link. |
| `disk_ids` | Map of disk key => `projects/{project}/zones/{zone}/disks/{name}`. |
| `snapshot_names` | Map of snapshot key => snapshot name. |
| `snapshot_self_links` | Map of snapshot key => `projects/{project}/global/snapshots/{name}`. |
| `snapshot_schedule_policy_names` | Map of schedule policy key => policy name. |
| `snapshot_schedule_policy_self_links` | Map of schedule policy key => `projects/{project}/regions/{region}/resourcePolicies/{name}`. |

## Example

```hcl
module "disks" {
  source = "git::ssh://git@github.com/<org>/terraform-modules.git//modules/gcp/compute-disk?ref=v1.25.0"

  disks = {
    "postgres-data" = {
      name     = "example-postgres-data"
      zone     = "us-central1-a"
      type     = "pd-ssd"
      size     = 500
      labels   = { env = "example" }
      disk_encryption_key = {
        kms_key_self_link = google_kms_crypto_key.example.id
      }
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
  }

  snapshot_schedule_attachments = {
    "postgres-data" = {
      disk_key   = "postgres-data"
      policy_key = "daily"
    }
  }
}
```

## Import

- `google_compute_disk` ← `projects/{project}/zones/{zone}/disks/{name}`
- `google_compute_snapshot` ← `projects/{project}/global/snapshots/{name}`
- `google_compute_resource_policy` ← `projects/{project}/regions/{region}/resourcePolicies/{name}`
- `google_compute_disk_resource_policy_attachment` ← `projects/{project}/zones/{zone}/disks/{name}`

## Notes

- Downsizing `size` forces disk recreation; keep `deletion_policy = "PREVENT"`
  on data-carrying disks if you want a guard rail at destroy time.
- The Compute Engine System service account needs
  `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the CMEK used by
  `disk_encryption_key`.
- Attach the produced disks with `google_compute_attached_disk` (consumer side)
  referencing `disk_self_links`;
  `google_compute_disk_resource_policy_attachment` exists as its own resource
  because the inline `resource_policies` attribute on `google_compute_disk`
  cannot be updated after creation.
