# gcp/firestore

Map-keyed module for Google Cloud Firestore databases
(`google_firestore_database`), covering native and Datastore mode,
standard and enterprise editions, CMEK and delete protection.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `databases` | `map(object)` | — | Map of databases keyed by an arbitrary unique ID. |

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Database id: `(default)` or 4–63 lowercase letters/digits/hyphens starting with a letter and not UUID-shaped (validated). Immutable; changing forces replacement. |
| `location_id` | `string` | — | Multi-region (e.g. `nam5`, `eur3`) or region (e.g. `europe-west1`). |
| `project_id` | `string` | — | Project the database lives in; defaults to the provider-level project. |
| `type` | `string` | — | `FIRESTORE_NATIVE` or `DATASTORE_MODE` (validated). |
| `database_edition` | `string` | — | `STANDARD` or `ENTERPRISE` (validated); `ENTERPRISE` requires `type = FIRESTORE_NATIVE` (validated). |
| `concurrency_mode` | `string` | — | `OPTIMISTIC`, `PESSIMISTIC` or `OPTIMISTIC_WITH_ENTITY_GROUPS` (validated). |
| `app_engine_integration_mode` | `string` | — | `ENABLED` or `DISABLED` (validated). |
| `point_in_time_recovery_enablement` | `string` | — | `POINT_IN_TIME_RECOVERY_ENABLED` or `POINT_IN_TIME_RECOVERY_DISABLED`. |
| `delete_protection_state` | `string` | — | `DELETE_PROTECTION_STATE_UNSPECIFIED`, `DELETE_PROTECTION_ENABLED` or `DELETE_PROTECTION_DISABLED` (validated). |
| `deletion_policy` | `string` | `ABANDON` (provider default) | One of `DELETE`, `PREVENT`, `ABANDON` (validated). **The provider default is `ABANDON`** — see Notes. |
| `cmek_config` | `object` | — | `{kms_key_name}`; the key must live in the same location as the database. |
| `tags` | `map(string)` | — | Resource-manager tags, `tagKeys/{id}` → `tagValues/{id}`. Immutable; changing forces replacement. |
| `firestore_data_access_mode` | `string` | — | ENTERPRISE only: `DATA_ACCESS_MODE_ENABLED` or `DATA_ACCESS_MODE_DISABLED`. |
| `mongodb_compatible_data_access_mode` | `string` | — | ENTERPRISE only: `DATA_ACCESS_MODE_ENABLED` or `DATA_ACCESS_MODE_DISABLED`. |
| `realtime_updates_mode` | `string` | — | ENTERPRISE only: `REALTIME_UPDATES_MODE_ENABLED` or `REALTIME_UPDATES_MODE_DISABLED`. |

## Outputs

`database_names` — map of database key => database id (e.g. `(default)`).
`database_ids` — map of database key => fully qualified database id.
`database_uids` — map of database key => system-generated uid.

## Example

```hcl
databases = {
  "default" = {
    name        = "(default)"
    location_id = "nam5"
    type        = "FIRESTORE_NATIVE"
    deletion_policy = "DELETE"
    point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
    delete_protection_state = "DELETE_PROTECTION_ENABLED"
  }
  "mongodb-compat" = {
    name        = "example-mongo"
    location_id = "eur3"
    type        = "FIRESTORE_NATIVE"
    database_edition = "ENTERPRISE"
    mongodb_compatible_data_access_mode = "DATA_ACCESS_MODE_ENABLED"
    deletion_policy = "DELETE"
  }
}
```

## Notes

- **`deletion_policy` defaults to `ABANDON` upstream.** Without an
  explicit `DELETE`, `terraform destroy` removes the database from state
  but leaves the real database behind in the project. Set `DELETE`
  (optionally combined with `deletion_protection_state` disabled) to
  allow actual deletion; `PREVENT` makes destroy fail outright.
- `deletion_policy` does not exist in the API — it only changes how
  Terraform treats the resource. It is distinct from
  `delete_protection_state`, which is API-level protection.
- PITR reads cover the past 7 days when enabled; without it only the
  past hour is readable.
- For CMEK, the KMS key must live in the same location as the database
  (multi-region `nam5` → US keys, `eur3` → europe keys) and the Firestore
  service agent needs `roles/cloudkms.cryptoKeyEncrypterDecrypter` on
  it; wire that grant with `gcp/kms` or `gcp/project-iam` — this module
  does not manage it.
- The three data-access modes are ENTERPRISE-only; setting them on a
  STANDARD or DATASTORE_MODE database is rejected at plan time (validated).
- For App Engine integration, the project must have an App Engine app
  (`google_app_engine_application`) before `app_engine_integration_mode`
  can be set to `ENABLED`; this module does not create it.
- No IAM resources exist for Firestore databases; database-scoped access
  is governed by project-level IAM.
- Keys are arbitrary unique identifiers, not database ids — the
  `(default)` database id is just the `name` value of an entry.

## Import

`google_firestore_database` ← `projects/{project}/databases/{name}`,
`{project}/{name}` or `{name}`.
