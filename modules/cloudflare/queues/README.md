# cloudflare/queues

Map-keyed module for Cloudflare Queues with their consumers. Each `queues`
entry creates one `cloudflare_queue`; each `consumers` entry creates one
`cloudflare_queue_consumer` attached to the queue named by its `queue_key`,
in the account resolved from the queue's entry.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | `""` | Fallback account ID for queues that omit `account_id`. |
| `queues` | `map(object)` | — | Map of queues keyed by an arbitrary unique ID. |
| `consumers` | `map(object)` | — | Map of consumers keyed by an arbitrary unique ID, attached to queues by `queue_key`. |

Plan-time validation: map keys and `queue_key` values are dot-free (consumer
addresses are composed as `<queue-key>.<consumer-key>`), `queue_key` names an
existing queue entry, (resolved account, queue_name) pairs are unique
case-insensitively, `queue_name` is non-empty, `jurisdiction` is
`eu`/`us`/`fedramp`, consumer `type` is `worker`/`http_pull`/`notification`,
worker consumers carry a `script_name`, and `dead_letter_queue` is non-empty.
A missing `account_id` on both levels fails the queue lifecycle precondition
with a keyed message.

### `queues` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `queue_name` | `string` | — | Queue name, unique per account case-insensitively; the API identifier. |
| `account_id` | `string` | `null` | Account for this queue; falls back to the module-level `account_id` when omitted. |
| `jurisdiction` | `string` | `null` | Queue jurisdiction: `eu`, `us` or `fedramp`. Creation-time at the API — a change attempts an in-place update and may be rejected at apply. |
| `settings` | `object` | `null` | Queue-level settings — `delivery_delay` (seconds), `delivery_paused` (bool), `message_retention_period` (seconds). |

### `consumers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `queue_key` | `string` | — | Key of the queue entry this consumer attaches to (validated to exist). Immutable — changing it replaces the consumer. |
| `type` | `string` | — | `worker`, `http_pull` or `notification`. Creation-time at the API — a change attempts an in-place update and may be rejected at apply. |
| `script_name` | `string` | `null` | Name of the consuming Worker — required (validated) for `type = "worker"`. |
| `dead_letter_queue` | `string` | `null` | Queue NAME (not an ID) receiving messages that exceed retries; must exist in the same account. |
| `settings` | `object` | `null` | Consumer settings — `batch_size`, `max_concurrency`, `max_retries`, `max_wait_time_ms`, `retry_delay`, `visibility_timeout_ms`, and the notification destination lists below. |
| `settings.email_destinations` | `list(string)` | `[]` | Destination email addresses — `notification` consumers. |
| `settings.pagerduty_destinations` | `list(string)` | `[]` | PagerDuty destination UUIDs — `notification` consumers. |
| `settings.webhook_destinations` | `list(string)` | `[]` | Webhook destination UUIDs (e.g. the `cloudflare/notifications` module's `webhook_ids`). |

## Outputs

| Name | Description |
|---|---|
| `queue_ids` | Map of queue key => queue ID. |
| `queue_names` | Map of queue key => queue name. |
| `consumer_ids` | Map of `<queue-key>.<consumer-key>` => consumer ID. |
| `consumer_queue_names` | Map of `<queue-key>.<consumer-key>` => the queue name the consumer is attached to. |

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

queues = {
  "orders" = {
    queue_name = "orders-queue"
    settings = {
      delivery_delay = 5
    }
  }
  "orders-dlq" = {
    queue_name = "orders-dlq"
  }
}

consumers = {
  "orders-worker" = {
    queue_key         = "orders"
    type              = "worker"
    script_name       = "order-processor"
    dead_letter_queue = "orders-dlq"
    settings = {
      batch_size       = 50
      max_retries      = 3
      max_wait_time_ms = 5000
    }
  }
}
```

## Notes

- The module floor is the repo-wide `>= 5.0.0`, but `settings.delivery_paused`
  only exists from provider v5.3.0, the queue `jurisdiction` and the consumer
  destination lists (`email`/`pagerduty`/`webhooks`) from v5.26.0, and the
  `queue_name` attribute the outputs read from v5.18.0 — consumers pinned below
  those get "unsupported attribute".
  The module was researched against v5.29.0.
- Consumers attach to queues managed by this module via `queue_key` — a
  dangling key fails at plan with a named message instead of an index error.
  Queues managed elsewhere are out of scope for consumers here.
- `dead_letter_queue` is a queue name, mirroring the API; create the DLQ as a
  `queues` entry in the same module (or reference an existing name in the same
  account) — the API verifies it exists.
- `max_concurrency = null` opts into the platform maximum (the provider's
  recommended default). Numeric bounds are not validated here — the provider
  doesn't validate them either; Cloudflare's Queues limits apply at apply time.
- The destination lists matter for `type = "notification"` consumers: emails
  are plain addresses, while PagerDuty and webhook entries are UUIDs of
  destinations configured under Cloudflare notifications (the
  `cloudflare/notifications` module's `webhook_ids` output feeds the webhook
  case).
- Consumer imports are not supported by the provider (stated on the resource);
  only queues import.
- Producing/consuming logic (producer bindings in Workers, HTTP pull clients)
  stays with the application tooling — same split as script content for
  `cloudflare/workers_script`.
- The caller needs `Queues Read`/`Write` and `Workers Scripts Read`/`Write` on
  the account.

## Import

`cloudflare_queue` ← `<account_id>/<queue_id>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/023e105f-4eef-8ad9-ca31-a8372d0c3530`.
`cloudflare_queue_consumer` does not currently support import (the provider
states so).
