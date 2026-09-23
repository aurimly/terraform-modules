# aws/sns

Map-keyed module for SNS topics: standard and FIFO, optional topic policy,
per-protocol delivery feedback, and subscriptions (with filter and redrive
policies) attached to managed topics.

## Destroy semantics (read before using)

- Removing a topic key destroys the topic; subscriptions attached through
  this module are destroyed first (the subscription resource). Existing
  subscribers outside the module lose their endpoint.
- Removing a subscription key unsubscribes the endpoint immediately.
- The `policy` sub-resource is authoritative per topic: set it once per
  topic in this module. Clearing it leaves no topic policy (falls back to
  the default).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `topics` | `map(object)` | `{}` | Map of topics keyed by an arbitrary unique ID. |

### `topics` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Topic name, up to 256 chars of alphanumerics/hyphens/underscores (validated). FIFO names must end in `.fifo` (precondition). Set this **or** `name_prefix` (validated). |
| `name_prefix` | `string` | — | Prefix for a provider-generated unique name; keep `.fifo` budget for FIFO topics. |
| `fifo` | `bool` | `false` | FIFO topic. FIFO accepts only `sqs`, `application` and `lambda` subscription protocols (validated) and requires content-based deduplication at the API level for ordering guarantees. |
| `display_name` | `string` | — | Display name shown in email/SMS senders (max 100 chars). |
| `signature_version` | `string` | — | `1` or `2` (validated). `2` adds SigV4 message signing. |
| `tracing_mode` | `string` | — | `Active` or `PassThrough` (validated) for X-Ray tracing. |
| `content_based_deduplication` | `bool` | — | FIFO-only (precondition); deduplicates on the message content hash instead of a group-provided dedup ID. |
| `policy` | `string` | — | JSON topic policy; presence manages `aws_sns_topic_policy`. |
| `kms_master_key_id` | `string` | — | KMS key for server-side encryption at rest. |
| `delivery_policy` | `string` | — | JSON HTTP delivery policy (`http_delivery_policy` shape: retry delays, rate limits). |
| `application_feedback` | `object` | — | `{success_feedback_role_arn, failure_feedback_role_arn, success_feedback_sample_rate}` for platform-application deliveries. |
| `lambda_feedback` | `object` | — | Same shape, for lambda deliveries. |
| `http_feedback` | `object` | — | Same shape, for HTTP/S deliveries. |
| `sqs_feedback` | `object` | — | Same shape, for SQS deliveries. |
| `firehose_feedback` | `object` | — | Same shape, for Firehose deliveries. |
| `subscriptions` | `map(object)` | `{}` | Map of subscriptions attached to **this topic**; see the `subscriptions` object table. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `subscriptions` object

| Attribute | Type | Description |
|---|---|---|
| `protocol` | `string` | One of `http`, `https`, `email`, `email-json`, `sms`, `sqs`, `application`, `lambda`, `firehose` (validated). |
| `endpoint` | `string` | ARN (sqs/application/lambda/firehose), URL (http/https), or email address. ARN/URL required for non-email protocols (validated). |
| `endpoint_auto_confirms` | `bool` | Auto-confirm HTTP/S endpoints (http/https only, validated). Beware: spoofable — prefer explicit confirmation for public endpoints. |
| `confirmation_timeout` | `number` | Minutes before HTTP/S confirmation expires (1–503 on the API side; not validated here beyond planning). |
| `raw_message_delivery` | `bool` | Deliver the raw payload without SNS envelope (sqs/http/https/email-json/firehose only, validated). |
| `delivery_policy` | `string` | JSON per-subscription HTTP delivery policy. |
| `filter_policy` | `string` | JSON filter policy document (validated JSON). |
| `filter_policy_scope` | `string` | `MessageAttributes` or `MessageBody` (validated); requires `filter_policy` (validated). |
| `redrive_policy` | `string` | JSON redrive policy with a `deadLetterTargetArn` (validated JSON). |

## Outputs

`topic_arns` — map of topic key => topic ARN.
`topic_names` — map of topic key => topic name.
`subscription_arns` — map of `"topic-key.subscription-key"` => subscription ARN.
Unconfirmed HTTP/S subscriptions report `pending confirmation` in the ARN
position until confirmed.

## Example

```hcl
topics = {
  "events" = {
    name              = "example-events"
    display_name      = "example"
    signature_version = "2"
    sqs_feedback = {
      failure_feedback_role_arn    = "arn:aws:iam::111111111111:role/example-sns-failure"
      success_feedback_sample_rate = 100
    }
    subscriptions = {
      "jobs-queue" = {
        protocol = "sqs"
        endpoint = "arn:aws:sqs:eu-central-1:111111111111:example-jobs"
        filter_policy = jsonencode({
          type = ["order"]
        })
        redrive_policy = jsonencode({
          deadLetterTargetArn = "arn:aws:sqs:eu-central-1:111111111111:example-events-dlq"
        })
      }
    }
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not topic names.
- Subscriptions attach to topics **in this same map** (the sub-key's topic
  key resolves through the module). To subscribe an external topic, use the
  `aws_sns_topic_subscription` resource consumer-side with the topic ARN
  passed in.
- `email`/`email-json` endpoints require manual confirmation from the
  mailbox; they appear as `pending confirmation` until then, and the TF
  resource handles it.
- Feedback role ARNs need `sns:GetTopicAttributes`/logging permissions for
  SNS to write delivery logs to CloudWatch.

## Import

`aws_sns_topic` ← topic ARN.
`aws_sns_topic_policy` ← topic ARN (the resource is keyed by topic key;
import into the `policy[topic-key]` address after inserting the topic).
`aws_sns_topic_subscription` ← subscription ARN (or `pending` +
`<topic-arn>,<endpoint>,<protocol>` triple for pending-confirmation
HTTP/S subscriptions: `pending:<topic-arn>,<endpoint>,<protocol>` with
the SubscriptionAttributes still unconfirmed).
