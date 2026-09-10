# gcp/logging

Map-keyed module for project-level Cloud Logging sinks exporting matching log
entries to Cloud Storage buckets, Pub/Sub topics, BigQuery datasets, Cloud
Logging buckets, or a shared sink destination.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `sinks` | `map(object)` | — | Map of sinks keyed by an arbitrary unique ID. |

### `sinks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Sink name; up to 100 characters, letters/digits/underscores/hyphens/periods, starting with a letter or digit. Validated here; provider requires it too. |
| `destination` | `string` | — | Full destination URI: `storage.googleapis.com/<bucket>`, `pubsub.googleapis.com/<topic>`, `bigquery.googleapis.com/datasets/<dataset>`, `logging.googleapis.com/projects/<project>/locations/<location>/buckets/<bucket>`, or a shared destination name (`bucket.<name>`, `pubsub.<name>`, `bigquery.<name>`, `logging.<name>`). Prefix-validated here; the API rejects destinations the caller cannot write to at apply. |
| `filter` | `string` | — | Cloud Logging query filter selecting which entries are exported (e.g. `severity>=WARNING`). Required by this module (the provider makes it optional); set to the broadest filter you need — a sink with no filter exports only what GCP writes. |
| `description` | `string` | — | Human-readable description. |
| `disabled` | `bool` | — | Create the sink in a disabled state. |
| `unique_writer_identity` | `bool` | `true` | Use a dedicated per-sink service account as the export writer. Required `true` when `bigquery_options` is set (validated). Defaults to `true` to match the provider. |
| `project_id` | `string` | — | Project the sink lives in; defaults to the provider-level project. Format validated. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). `ABANDON` destroys the resource from state without deleting the sink itself. |
| `bigquery_options` | `object` | — | Presence enables BigQuery sink options; see `bigquery_options` table. Only allowed with BigQuery dataset destinations (validated). |
| `exclusions` | `list(object)` | `[]` | Sink-level exclusion filters as `{name, filter, description, disabled}` objects; `name` must be unique within each sink (validated) and follows the provider's name rule (letters/digits/underscores/hyphens/periods, up to 100 chars, first char alphanumeric). |

### `bigquery_options` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `use_partitioned_tables` | `bool` | — | Whether to use partitioned tables for the sink. Required inside the object. |

## Outputs

`sink_names` — map of sink key => sink name.
`sink_writer_identities` — map of sink key => writer identity. The sink does
**not** grant the destination access itself; grant the identity the destination
role consumer-side (see Notes). May be an empty string until GCP provisions
the identity — don't assume a value in the same apply that depends on it.
`sink_filters` — map of sink key => effective filter.

## Example

```hcl
sinks = {
  "audit" = {
    name        = "example-audit-sink"
    destination = "storage.googleapis.com/example-audit-logs"
    filter      = "logName:\"cloudaudit.googleapis.com\""
    exclusions = [
      {
        name   = "ns.exclusion1"
        filter = "severity<ERROR"
      },
    ]
  }
  "metrics" = {
    name                   = "example-metrics-sink"
    destination            = "pubsub.googleapis.com/projects/example-prj/topics/example-logs"
    filter                 = "resource.type=\"gce_instance\" severity>=WARNING"
    unique_writer_identity = true
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not sink names.
- Pair with `gcp/project-services` (`logging.googleapis.com`) when the source
  project does not already have the Cloud Logging API enabled; this module
  does not enable APIs itself.
- The sink does **not** grant the writer identity access to the destination.
  Read `sink_writer_identities` and grant the identity the destination role
  consumer-side (or with `gcp/project-iam`):
  `roles/storage.objectCreator` for Cloud Storage,
  `roles/pubsub.publisher` for Pub/Sub, `roles/bigquery.dataEditor` for
  BigQuery, `roles/logging.bucketWriter` for Cloud Logging buckets.
- Keep `unique_writer_identity = true` when the destination is in another
  project — otherwise the export uses the source project's service account,
  which typically has no access to the destination project.
- BigQuery destinations: GCP creates the linked dataset; do not pre-create it.
- `custom_writer_identity` is not exposed — it applies to org-level sinks
  only, which are out of scope for this module.
- A sink named `_Default` or `_Required` acquires the matching auto-created
  sink, and destroying the resource leaves the sink in place (state-only
  removal). Reach for `deletion_policy` (or care) before naming a sink that.

## Import

`google_logging_project_sink` ←
`projects/{project}/sinks/{name}`.
