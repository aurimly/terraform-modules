# gcp/pubsub

Map-keyed module for Pub/Sub topics with nested subscriptions and IAM
bindings on both levels.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `topics` | `map(object)` | — | Map of topics keyed by an arbitrary unique ID; subscriptions nest under each topic and flatten to composite keys (`topic key/subscription key`). |

### `topics` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Topic name, 3–255 chars starting with a letter (validated). Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the topic lives in; defaults to the provider-level project. Format validated. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `message_retention_duration` | `string` | — | Message retained in the topic after publish; seconds-suffixed 600s–2678400s (validated). |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `kms_key_name` | `string` | — | CMEK key (`projects/{p}/locations/{loc}/keyRings/{kr}/cryptoKeys/{key}`). Immutable. |
| `schema_settings` | `object` | — | `{schema, encoding, first_revision_id, last_revision_id}`; encoding one of `JSON`, `BINARY` (validated). Presence enables schema validation on the topic. |
| `message_storage_policy` | `object` | — | `{allowed_persistence_regions, enforce_in_transit}`; regions list is required when the block is set (e.g. `["us-central1"]`, or `["asia-northeast1"]`-style shapes). |
| `subscriptions` | `map(object)` | `{}` | Nested subscriptions; see the `subscriptions` object table. |
| `role_bindings` | `map(object)` | `{}` | IAM bindings on the topic; see the `role_bindings` object table. |

### `subscriptions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Subscription name, 3–255 chars starting with a letter (validated). Immutable. |
| `project_id` | `string` | — | Project the subscription lives in; use for cross-project subscriptions (the subscription lives here, the topic reference stays fully-qualified). |
| `labels` | `map(string)` | `{}` | User labels. |
| `ack_deadline_seconds` | `number` | `10` | 10–600 seconds; `0` is accepted by the API but resolves to the 10s default. |
| `message_retention_duration` | `string` | — | Retain messages after ack/push timeout; 600s–2678400s (validated). |
| `retain_acked_messages` | `bool` | — | Keep acked messages until the retention window ends. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `expiration_policy` | `object` | — | `{ttl}` — see Notes for the tri-state semantics. |
| `enable_message_ordering` | `bool` | `false` | Deliver ordered on message ordering key. |
| `enable_exactly_once_delivery` | `bool` | — | Exactly-once delivery. |
| `filter` | `string` | — | Filtering expression (e.g. `attributes.x = \"y\"`); cannot be cleared without replacement. |
| `dead_letter_policy` | `object` | — | `{dead_letter_topic, max_delivery_attempts}`; topic must be fully-qualified `projects/{project}/topics/{topic}` (validated); attempts within 5–100 (validated). |
| `retry_policy` | `object` | — | `{minimum_backoff, maximum_backoff}` seconds-suffixed durations, min ≤ max (validated). |
| `push_config` | `object` | — | Push delivery; see the `push_config` object table. |
| `bigquery_config` | `object` | — | BigQuery sink; see the `bigquery_config` object table. |
| `cloud_storage_config` | `object` | — | Cloud Storage sink; see the `cloud_storage_config` object table. |
| `role_bindings` | `map(object)` | `{}` | IAM bindings on the subscription; see the `role_bindings` object table. |

### Delivery shape

At most one of `push_config`, `bigquery_config` and `cloud_storage_config`
may be set per subscription (validated) — none set means a pull subscription,
the default.

### `push_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `push_endpoint` | `string` | — | HTTPS URL receiving messages. |
| `attributes` | `map(string)` | — | Extra headers. |
| `no_wrapper` | `object` | — | `{write_metadata}` (required inside the block) — toggle protobuf unwrapping and add the raw Pub/Sub metadata header. |
| `oidc_token` | `object` | — | `{service_account_email, audience}` — authentication for the push target; the service account is required. |

### `bigquery_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `table` | `string` | — | `{projectId}.{datasetId}.{tableId}` dot format (validated). |
| `use_topic_schema` | `bool` | — | Write messages using the topic schema. |
| `use_table_schema` | `bool` | — | Write using the table's schema validation mode. |
| `write_metadata` | `bool` | — | Include metadata columns. |
| `drop_unknown_fields` | `bool` | — | Drop fields absent from the schema. |
| `service_account_email` | `string` | — | SA Pub/Sub impersonates to write. |

### `cloud_storage_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `bucket` | `string` | — | Output bucket name (required, non-empty validated). |
| `filename_prefix` / `filename_suffix` | `string` | — | Output filename composition. |
| `filename_datetime_format` | `string` | — | Datetime token formatting when a timestamp component is present. |
| `max_duration` | `string` | — | Seconds-suffixed, ≥ 60s (validated). |
| `max_bytes` | `number` | — | Max file size. |
| `max_messages` | `number` | — | Max messages per file. |
| `service_account_email` | `string` | — | SA Pub/Sub impersonates to write. |
| `text_config` | `bool` | — | Presence switches output to text encoding (default is Avro). |
| `avro_config` | `object` | — | `{write_metadata, use_topic_schema}` — Avro-specific options. |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/pubsub.publisher`. Must be unique within the topic or subscription (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role on this resource. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`. |

## Outputs

`topic_names` — map of topic key => topic name.
`topic_ids` — map of topic key => fully-qualified topic ID.
`subscription_names` — map of subscription composite key (topic
key/subscription key) => subscription name.
`subscription_ids` — map of subscription composite key => fully-qualified
subscription ID.
`topic_iam_binding_roles` — map of topic IAM binding composite key
(topic key/binding key) => role.
`subscription_iam_binding_roles` — map of subscription IAM binding composite
key (topic key/subscription key/binding key) => role.

## Example

```hcl
topics = {
  "events" = {
    name       = "example-events"
    project_id = "example-prj"
    message_storage_policy = {
      allowed_persistence_regions = ["europe-west4"]
      enforce_in_transit          = true
    }
    schema_settings = {
      schema   = "projects/example-prj/schemas/example-schema"
      encoding = "JSON"
    }
    role_bindings = {
      "publishers" = {
        role    = "roles/pubsub.publisher"
        members = ["serviceAccount:prod-ingest@example-prj.iam.gserviceaccount.com"]
      }
    }
  }
  "notifications" = {
    name = "example-notifications"
    subscriptions = {
      "webhooks" = {
        name        = "example-webhooks"
        ack_deadline_seconds = 30
        push_config = {
          push_endpoint = "https://example.net/hooks"
          oidc_token = {
            service_account_email = "sa-webhook-rt@example-prj.iam.gserviceaccount.com"
          }
        }
        retry_policy = {
          minimum_backoff = "10s"
          maximum_backoff = "300s"
        }
        dead_letter_policy = {
          dead_letter_topic     = "projects/example-prj/topics/example-dlq"
          max_delivery_attempts = 10
        }
      }
      "export" = {
        name        = "example-storage-export"
        expiration_policy = { ttl = "" }
        cloud_storage_config = {
          bucket          = "example-archive"
          filename_prefix = "export/"
          max_duration    = "60s"
          avro_config     = { use_topic_schema = true }
        }
        role_bindings = {
          "consumers" = {
            role    = "roles/pubsub.subscriber"
            members = ["serviceAccount:etl@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
      "load" = {
        name = "example-bq-load"
        bigquery_config = {
          table        = "example-prj.example_dataset.example_events"
          write_metadata = true
        }
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — nested
  subscriptions flatten to `topic key/subscription key` in outputs and IAM
  composite keys, so multiple topics can carry identically named
  subscriptions.
- Switching a subscription's delivery shape can be destructive: moving
  between push/pull is in-place, while adopting or removing
  `bigquery_config`/`cloud_storage_config` replaces the subscription (and
  the active subscription would stop for the moment in between). Plan
  before touching the resolution for subscriptions with live traffic.
- `expiration_policy` tri-state: the API defaults a subscription to a 31-day
  expiration window; a block present with `ttl = ""` disables expiration
  (the subscription never expires); a numeric `ttl` (≥ 600s) sets an explicit
  expiry. If you omit the block entirely, the provider default (31-day TTL)
  applies — set `expiration_policy = { ttl = "" }` explicitly for
  never-expire.
- No Bigtable sink exists in Pub/Sub — the two sink types are BigQuery and
  Cloud Storage, alongside push and pull.
- `filter` cannot be removed on an existing subscription (the API has no
  clear for it); plan so accordingly.
- IAM bindings on the topic and on each subscription are authoritative per
  role (`google_pubsub_topic_iam_binding` /
  `google_pubsub_subscription_iam_binding`): members you omit are removed
  from that role. Roles must be unique within each topic/subscription
  (validated).
- Pair with `gcp/project-services` (`pubsub.googleapis.com`) when the project
  does not have the API enabled yet; cross-project subscriptions additionally
  need IAM on both projects.
- The identity running Terraform needs Pub/Sub admin on the target project
  to create topics, subscriptions, sink configs and IAM bindings.

## Import

`google_pubsub_topic` ← `projects/{project}/topics/{name}`.
`google_pubsub_subscription` ← `projects/{project}/subscriptions/{name}`.
`google_pubsub_topic_iam_binding` ← space-delimited
`{topic} roles/{role}`, e.g. `projects/example-prj/topics/example-events
roles/pubsub.publisher`.
`google_pubsub_subscription_iam_binding` ←
`projects/example-prj/subscriptions/example-webhooks roles/pubsub.viewer`.
