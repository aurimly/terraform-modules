# gcp/bucket

Map-keyed module for Google Cloud Storage buckets with optional IAM bindings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `buckets` | `map(object)` | — | Map of buckets keyed by an arbitrary unique ID. |

### `buckets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Globally unique bucket name, 3–222 chars; lowercase letters, digits, `-`, `_`, `.`; start/end alnum; no consecutive dots; each dot-component ≤ 63 (validated per GCS rules). Immutable; changing forces replacement. |
| `location` | `string` | — | GCS location: region (`us-central1`), multi-region (`US`), zonal (`US-CENTRAL1`), or dual-region (`US-CENTRAL1+US-EAST1`). Shape-validated, not a location list. Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the bucket lives in; defaults to the provider-level project (which then requires the Compute API for dynamic project resolution — see Notes). Format validated. |
| `force_destroy` | `bool` | `false` | Delete the bucket and all objects on destroy. Import resets this to `false` in state — apply after import to restore. |
| `storage_class` | `string` | `STANDARD` | e.g. `STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`, `MULTI_REGIONAL`, `REGIONAL`. Not enum-validated — newer classes surface over time; the API rejects unknown values. |
| `uniform_bucket_level_access` | `bool` | `true` | Uniform (IAM-only) bucket access. Disabling requires care: ACLs apply again. |
| `public_access_prevention` | `string` | — | One of `enforced`, `inherited` (lowercase, validated). |
| `requester_pays` | `bool` | — | Requesters pay access costs. |
| `rpo` | `string` | — | One of `DEFAULT`, `ASYNC_TURBO` (validated). `ASYNC_TURBO` errors on single-region buckets. |
| `default_event_based_hold` | `bool` | — | Event-based hold on new objects. |
| `enable_object_retention` | `bool` | — | Allow per-object retention settings. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). `PREVENT` guards locked-retention buckets. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `versioning` | `bool` | — | Tri-state: set `true`/`false` to send the versioning block, omit to leave it unset. |
| `lifecycle_rules` | `list(object)` | `[]` | Lifecycle rules; see the `lifecycle_rules` object table. |
| `logging` | `object` | — | `{log_bucket, log_object_prefix}` — presence enables access-log delivery. |
| `encryption` | `object` | — | `{default_kms_key_name}` — CMEK for new objects. |
| `retention_policy` | `object` | — | `{retention_period, is_locked}`. `retention_period` is a numeric **string** (seconds; the provider expects a string since v7), 86400–3155759999, validated. `is_locked = true` is irreversible. |
| `soft_delete_policy` | `object` | — | `{retention_duration_seconds}` — `0` disables soft delete; otherwise 604800–7776000 (7–90 days), validated. |
| `custom_placement_config` | `object` | — | `{data_locations}` (set of locations); dual-regions use exactly 2 entries. |
| `website` | `object` | — | `{main_page_suffix, not_found_page}` static-website routing; at least one field required (validated). |
| `autoclass` | `object` | — | `{enabled, terminal_storage_class}`; terminal class one of `NEARLINE`, `ARCHIVE` (validated). |
| `cors` | `list(object)` | `[]` | CORS rules as `{origin, method, response_header, max_age_seconds}`. |
| `hierarchical_namespace` | `bool` | — | Presence enables HNS folders; requires `uniform_bucket_level_access` ≠ `false` (validated). |
| `role_bindings` | `map(object)` | `{}` | IAM bindings; see the `role_bindings` object table. |

### `lifecycle_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `action.type` | `string` | — | One of `Delete`, `SetStorageClass`, `AbortIncompleteMultipartUpload` (validated). |
| `action.storage_class` | `string` | — | Target class; required when `type = SetStorageClass` (validated). |
| `condition.age` | `number` | — | Days since creation. |
| `condition.created_before` | `string` | — | `YYYY-MM-DD` cutoff. |
| `condition.with_state` | `string` | — | One of `LIVE`, `ARCHIVED`, `ANY` (validated). |
| `condition.matches_storage_class` | `list(string)` | — | Apply only to objects of these classes. |
| `condition.matches_prefix` / `matches_suffix` | `list(string)` | — | Object-name prefix/suffix matches. |
| `condition.num_newer_versions` | `number` | — | Keep N newer versions. |
| `condition.size_above_bytes` / `size_below_bytes` | `number` | — | Object size bounds. |
| `condition.days_since_custom_time` | `number` | — | Days since object custom time. |
| `condition.days_since_noncurrent_time` | `number` | — | Days since becoming noncurrent. |
| `condition.custom_time_before` / `noncurrent_time_before` | `string` | — | `YYYY-MM-DD` cutoffs. |
| `condition.send_age_if_zero` and siblings (`send_num_newer_versions_if_zero`, `send_days_since_custom_time_if_zero`, `send_days_since_noncurrent_time_if_zero`) | `bool` | — | Send the companion field even when `0`; each flag needs its companion field set to matter. |
| `condition` (at least one field) | — | — | At least one substantive field is required (validated); the API rejects empty conditions. |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/storage.objectViewer`. Must be unique within the bucket (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role on this bucket. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`; per binding (not per bucket). |

## Outputs

`bucket_names` — map of bucket key => bucket name.
`bucket_self_links` — map of bucket key => bucket self link.
`bucket_urls` — map of bucket key => `gs://` URL.
`iam_binding_roles` — map of composite IAM binding key
(`bucket key/binding key`) => role.

## Example

```hcl
buckets = {
  "logs" = {
    name       = "example-project-1234-logs"
    location   = "us-central1"
    versioning = true
    lifecycle_rules = [
      {
        action = { type = "Delete" }
        condition = { age = 90 }
      },
      {
        action = { type = "SetStorageClass", storage_class = "NEARLINE" }
        condition = { age = 30, matches_storage_class = ["STANDARD"] }
      },
    ]
    role_bindings = {
      "viewers" = {
        role    = "roles/storage.objectViewer"
        members = ["group:example-viewers@example.com"]
      }
      "ci" = {
        role    = "roles/storage.objectCreator"
        members = ["serviceAccount:ci@example-project-1234.iam.gserviceaccount.com"]
        condition = {
          title      = "ci-prefix-only"
          expression = "resource.name.startsWith(\"projects/_/buckets/example-project-1234-logs/objects/ci/\")"
        }
      }
    }
  }
  "assets" = {
    name              = "example-assets"
    location          = "US"
    autoclass         = { enabled = true }
    soft_delete_policy = { retention_duration_seconds = 0 }
    cors = [
      { origin = ["https://example.org"], method = ["GET"], max_age_seconds = 3600 },
    ]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not bucket names — bucket names are
  globally unique anyway, the key only decouples your config from the name.
- Pair with `gcp/project-services` (`storage.googleapis.com`) when the target
  project does not have the storage API enabled yet; this module does not
  enable APIs itself.
- Omitting `project_id` makes the provider resolve the default project
  dynamically, which requires the Compute API in that project.
- `uniform_bucket_level_access` defaults to `true` (the modern posture). Once a
  bucket has UBLA enabled it cannot be fully reverted to ACL-managed access
  through this module.
- IAM bindings are authoritative per role (`google_storage_bucket_iam_binding`):
  members you omit are removed from that role on the bucket. Keys are
  `bucket key/binding key`; roles must be unique per bucket (validated) because
  two bindings for one role would fight over the same policy entry.
- `retention_policy.is_locked = true` is irreversible — the retention period can
  never be shortened afterwards, and `deletion_policy = PREVENT` pairs well with
  it.
- `versioning`, `logging`, `encryption`, `retention_policy`,
  `soft_delete_policy`, `custom_placement_config`, `website`, `autoclass` and
  `hierarchical_namespace` are presence-toggled: set the object to send the
  block, omit it to leave the attribute unset.
- `location` and `name` are immutable — changing either replaces the bucket
  (and, without `force_destroy`, the apply fails on the non-empty source).

## Import

`google_storage_bucket` ← `{bucket}` or `{project_id}/{bucket}`; note that
import resets `force_destroy` to `false` in state — apply after import to
restore the module value.
`google_storage_bucket_iam_binding` ← space-delimited `{bucket} roles/{role}`
(also `b/{bucket} roles/{role}`).
