# aws/lambda

Map-keyed module for Lambda functions: S3-packaged zip code (uploaded
consumer-side), VPC configuration, layers, DLQ, tracing, advanced logging,
event source mappings (SQS/Kinesis/DynamoDB streams/MSK) and invocation
permissions for producer services.

## Destroy semantics (read before using)

- Removing a function key deletes the function immediately — there is no
  recovery beyond redeploying code.
- Event source mappings and permissions inside the function entry are
  destroyed with it, so producers (S3 notifications, SNS topics, ALB
  rules, API Gateway integrations) lose their target until re-created.
- Reserved concurrency disappears with the function.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `functions` | `map(object)` | `{}` | Map of functions keyed by an arbitrary unique ID. Map keys must not contain `.` (composite resource addresses; validated). |

### `functions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Function name, up to 64 characters of alphanumerics/hyphens/underscores (validated). |
| `role_arn` | `string` | — | Execution role ARN (from `aws/iam-role`; trust `Service: lambda.amazonaws.com`). |
| `runtime` | `string` | — | Lambda runtime (e.g. `nodejs22.x`, `python3.13`); name-shape validated, not a fixed list, so new runtimes never break the module. |
| `handler` | `string` | — | Function entry-point (`file.method` for zips). |
| `description` | `string` | — | Function description. |
| `memory_size` | `number` | `128` | MB (128–32768 validated; the account default quota may be lower and raises automatically with usage). |
| `timeout` | `number` | `3` | Seconds (1–900). |
| `architectures` | `list(string)` | — | Exactly one of `x86_64`, `arm64` (at most one value, validated). |
| `layers` | `list(string)` | `[]` | Layer-version ARNs; at most 5 (validated). |
| `s3_bucket` | `string` | — | S3 bucket with the deployment zip — uploaded consumer-side; this module never packages code. |
| `s3_key` | `string` | — | Object key of the zip. |
| `s3_object_version` | `string` | — | Pin an object version; versioned buckets recommended. |
| `source_code_hash` | `string` | — | Or use a base64 hash to trigger redeployments for fixed keys. |
| `reserved_concurrent_executions` | `number` | — | `-1` (unreserved) or a non-negative number (validated). |
| `kms_key_arn` | `string` | — | KMS key encrypting `environment_variables`. No-op when the function has no environment variables (the API does not save the configuration without env vars in use). |
| `publish` | `bool` | `false` | Create a version per code change (`function_qualified_arns` output populates). |
| `tracing_config` | `object` | — | `{mode}` — `Active` or `PassThrough` (required inside the block, validated). |
| `dead_letter_config` | `object` | — | `{target_arn}` — SQS queue or SNS topic ARN (validated). |
| `vpc_config` | `object` | — | `{subnet_ids, security_group_ids}` — at least one of each (validated). The execution role needs the VPC-access permissions consumer-side; the module never attaches policies. |
| `environment_variables` | `map(string)` | — | Emitted only when set (an emptied map clears variables; unset leaves them alone). Stored in plain text in state — encrypt with `kms_key_arn` and keep secrets in a secret manager. |
| `logging_config` | `object` | — | `{log_format, application_log_level, system_log_level, log_group}` — `log_format` (`JSON`/`Text`) is required inside the block; log levels apply to JSON only (validated). Newer provider attribute (floor ≈5.32). |
| `ephemeral_storage` | `object` | — | `{size}` in MB, 512–10240 (validated). |
| `event_source_mappings` | `map(object)` | `{}` | Map of event sources feeding the function; see the table below. |
| `permissions` | `map(object)` | `{}` | Map of resource-based invocation permissions; see the table below. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `event_source_mappings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `event_source_arn` | `string` | — | SQS queue, Kinesis stream, DynamoDB stream or MSK cluster ARN (validated; self-managed Kafka endpoints are out of scope). |
| `enabled` | `bool` | `true` | Whether the mapping is active. |
| `batch_size` | `number` | — | Max records per batch (service-specific API limits). |
| `starting_position` | `string` | — | `TRIM_HORIZON`, `LATEST` or `AT_TIMESTAMP` (validated). Required for Kinesis/DynamoDB/MSK, forbidden for SQS (validated). |
| `starting_position_timestamp` | `string` | — | Timestamp for `AT_TIMESTAMP` (Kinesis only, validated). |
| `maximum_batching_window_in_seconds` | `number` | — | Max record-gathering window. |
| `maximum_retry_attempts` | `number` | — | Retries before the record ages out. |
| `bisect_batch_on_function_error` | `bool` | — | Split failed batches (stream sources). |
| `parallelization_factor` | `number` | — | Concurrent batches per shard (Kinesis/DynamoDB). |
| `destination_arn` | `string` | — | Failed-record destination for stream sources only (DynamoDB streams, Kinesis and Kafka; SQS-rejected) — pair with `aws/sqs` queues. On-failure handling for SQS sources is the queue's own redrive policy. |
| `function_response_types` | `list(string)` | `[]` | Only `ReportBatchItemFailures` (validated). |
| `filter_criteria` | `object` | — | `{filters = [{pattern}]}` — `pattern` is a required JSON filter document and must be non-empty. |

### `permissions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `statement_id` | `string` | — | Statement identifier — make it descriptive per producer. |
| `action` | `string` | `lambda:InvokeFunction` | Action allowed by the producer principal. |
| `principal` | `string` | — | e.g. `s3.amazonaws.com`, `sns.amazonaws.com`, `elasticloadbalancing.amazonaws.com`, `apigateway.amazonaws.com`. |
| `source_arn` | `string` | — | Restrict to the producing resource (bucket ARN, topic ARN, ALB ARN). |
| `source_account` | `string` | — | Restrict to a producing account ID. |

## Outputs

`function_arns` — map of function key => function ARN (unqualified).
`function_names` — map of function key => function name.
`function_invoke_arns` — map of function key => `:invoke` ARN (for API
Gateway and service integrations).
`function_qualified_arns` — map of function key => version-qualified ARN;
populated when `publish = true`, empty otherwise.

## Example

```hcl
functions = {
  "orders" = {
    name      = "example-orders"
    role_arn  = dependency.role.outputs.role_arns["lambda-exec"]
    runtime   = "python3.13"
    handler   = "app.handler"
    s3_bucket = dependency.artifacts.outputs.bucket_ids["artifacts"]
    s3_key    = "orders.zip"
    environment_variables = {
      QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/123456789012/example-orders"
    }
    event_source_mappings = {
      "jobs" = {
        event_source_arn      = dependency.jobs.outputs.queue_arns["orders"]
        batch_size            = 10
        function_response_types = ["ReportBatchItemFailures"]
      }
    }
    permissions = {
      "s3-notify" = {
        statement_id = "AllowS3BucketNotification"
        principal    = "s3.amazonaws.com"
        source_arn   = "arn:aws:s3:::example-artifacts"
      }
    }
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not function names; multiple
  functions can share a name suffix across the map (the key
  disambiguates mappings and permissions).
- Packaging: upload the zip to S3 first (`aws/s3-bucket` can own the
  bucket; enable versioning and pass `s3_object_version`, or pass
  `source_code_hash` for fixed keys). The module never packages or
  uploads code; container-image packaging is out of scope.
- `logging_config` is a newer provider attribute (floor ≈5.32) — keep
  provider pins at the consumer root; no in-module constraint.
- Log groups: Lambda auto-creates `/aws/lambda/<name>` with
  never-expire retention. Pre-create the log group consumer-side to
  control retention (CloudWatch log groups are out of this module's
  scope; `logging_config.log_group` only redirects).
- Event source mappings cover the SQS / Kinesis / DynamoDB-stream / MSK
  core attributes; exotic attributes (self-managed Kafka access config,
  DocumentDB) are omitted — add consumer-side or on request.
- `permissions` are required for cross-resource invocation: pair with
  `aws/s3-bucket` notifications (`principal = "s3.amazonaws.com"`,
  `source_arn` = bucket ARN), `aws/sns` lambda subscriptions
  (`sns.amazonaws.com`), `aws/alb` lambda target groups
  (`elasticloadbalancing.amazonaws.com`) and API Gateway
  (`apigateway.amazonaws.com`).
- Function URLs, aliases and version resources are out of scope.

## Import

`aws_lambda_function` ← function name.
`aws_lambda_event_source_mapping` ← mapping UUID.
`aws_lambda_permission` ← `<function-name>/<statement-id>` (the resource
is keyed by `"function-key.permission-key"`; import into that address
after inserting the function).
