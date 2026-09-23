# aws/sqs

Map-keyed module for SQS queues: standard and FIFO, managed or
customer-managed KMS encryption, dead-letter redrive and redrive-allow
policies.

## Destroy semantics (read before using)

- Removing a key destroys the queue with **all undelivered messages**;
  SQS keeps no recoverable state after `DeleteQueue`. There is no
  AWS-side removal protection — plan carefully for queues holding
  in-flight work.
- Removing the `redrive` entry detaches the dead-letter configuration;
  messages already moved to the DLQ stay there.
- `redrive_allow` only gates which other queues may use this queue as
  their DLQ; removing it does not affect the queue's own redrive.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `queues` | `map(object)` | `{}` | Map of queues keyed by an arbitrary unique ID. |

### `queues` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Queue name, up to 80 chars, alphanumerics/hyphens/underscores (validated). FIFO names must end in `.fifo` (precondition). Set this **or** `name_prefix` (validated). Immutable; changing replaces the queue. |
| `name_prefix` | `string` | — | Prefix for a provider-generated unique name (up to 48 chars, validated); the suffix plus FIFO's `.fifo` must fit the 80-char limit. |
| `fifo` | `bool` | `false` | Create a FIFO queue. Content-based deduplication is the API default for FIFO queues created via the console; the raw API used here requires enabling it client-side per message or via `deduplication_scope` — set explicitly what you need. |
| `delay_seconds` | `number` | — | Delivery delay in seconds, 0–900 (validated). Non-zero changes `DelaySeconds` and forces no replacement. |
| `max_message_size` | `number` | — | Message size limit in bytes, 1024–262144 (validated). |
| `message_retention_seconds` | `number` | — | Retention in seconds, 60–1209600 (validated; 1 minute to 14 days). |
| `receive_wait_time_seconds` | `number` | — | Long-poll wait in seconds, 0–20 (validated). |
| `visibility_timeout_seconds` | `number` | — | Visibility timeout in seconds, 0–43200 (validated). |
| `deduplication_scope` | `string` | — | `queue` or `messageGroup` (validated); FIFO-only (validated). |
| `fifo_throughput_limit` | `string` | — | `perQueue` or `perMessageGroupId` (validated); FIFO-only (validated). |
| `sse` | `object` | `{enabled = true}` | `{enabled, kms_master_key_id, kms_data_key_reuse_period_seconds}`. Default is SQS-managed SSE (`enabled = true`, no key). `kms_master_key_id` switches to customer-managed KMS and requires `enabled = true` (precondition). `kms_data_key_reuse_period_seconds` 60–86400 (validated), customer-managed KMS only. |
| `redrive` | `object` | — | `{dead_letter_target_arn, max_receive_count}` — presence attaches a dead-letter redrive policy; count 1–1000 (validated). |
| `redrive_allow` | `object` | — | `{permission, source_queue_arns}` — allow-list for queues that may use **this** queue as their DLQ. `permission` one of `byQueue`, `never`, `all` (validated); `source_queue_arns` required with `byQueue`, forbidden otherwise (validated). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

## Outputs

`queue_ids` — map of queue key => queue URL.
`queue_arns` — map of queue key => queue ARN.
`queue_names` — map of queue key => queue name.

## Example

```hcl
queues = {
  "jobs" = {
    name                       = "example-jobs"
    visibility_timeout_seconds = 300
    redrive = {
      dead_letter_target_arn = "arn:aws:sqs:eu-central-1:111111111111:example-jobs-dlq"
      max_receive_count      = 5
    }
    tags = {
      Environment = "example"
    }
  }
  "orders" = {
    name                 = "example-orders.fifo"
    fifo                 = true
    fifo_throughput_limit = "perMessageGroupId"
    sse = {
      enabled = true
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not queue names; the key only
  decouples your config from the name.
- The default `sse` posture is SQS-managed SSE. When you switch a queue
  from customer-managed KMS back to managed SSE, the API propagates the
  change asynchronously (up to ~15 minutes); sending during that window
  fails with a KMS error.
- DLQs referenced by `redrive` belong under this same map key set or
  another module instance — the module only needs the ARN.
- FIFO `name_prefix` ends up in the final `.fifo` name (the generated
  suffix is inserted before it), so keep 32-plus chars of budget
  (suffix within 80-char names).

## Import

`aws_sqs_queue` ← queue URL (`https://sqs.<region>.amazonaws.com/<account>/<name>`)
or `arn:aws:sqs:<region>:<account>:<name>` for the same-dwelling
provider; FIFO URLs keep the `.fifo` suffix.
