# aws/cloudtrail

Map-keyed module for CloudTrail trails: multi-region and organization trails
with S3 delivery (required), optional KMS encryption, CloudWatch log-group
wiring, SNS notifications, and event/advanced-event/Insights selectors.

The delivery bucket and its CloudTrail bucket policy stay consumer-side —
pair with `aws/s3-bucket` and its `aws_iam_policy_document` policy.

## Destroy semantics (read before using)

- Destroying the module deletes the trail immediately. Log files already in
  S3 remain.
- Setting `enable_logging = false` stops delivery without deleting the
  trail.
- Removing an organization trail stops delivery for all member accounts.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `trails` | `map(object)` | `{}` | Map of trails keyed by an arbitrary unique ID. |

Plan-time validation: `name` matches CloudTrail trail naming rules,
`s3_bucket_name` is a valid bucket name, the CloudWatch log-group ARN carries
no `:*` suffix (the module appends it) and is set together with the role ARN,
`event_selectors` and `advanced_event_selectors` are mutually exclusive with
at most 5 basic selectors, selector enums match the CloudTrail API
(case-sensitive), the readOnly/eventCategory/resources.type fields accept
`equals` only, each advanced field selector sets exactly one operator, the
exclude-management-event-sources selector requires `include_management_events`,
and `insight_types` entries are valid and distinct.

### `trails` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Trail name; 3–128 characters of alphanumerics, dots, underscores, hyphens (validated). |
| `s3_bucket_name` | `string` | — | Delivery bucket (consumer-side; needs the CloudTrail bucket policy — see Notes). |
| `s3_key_prefix` | `string` | `null` | Prefix for delivered log files. |
| `is_multi_region_trail` | `bool` | `false` | Log all regions; create it from the intended home region (see Notes). |
| `is_organization_trail` | `bool` | `false` | Log all member accounts; must be created from the organization management account (see Notes). |
| `enable_log_file_validation` | `bool` | `false` | Write digest files enabling integrity validation. |
| `enable_logging` | `bool` | `true` | Start logging on creation. |
| `include_global_service_events` | `bool` | `true` | Include events from global services (IAM, STS, ...). |
| `kms_key_id` | `string` | `null` | KMS key ARN for log-file encryption (pair with `aws/kms`; the key policy must allow `cloudtrail.amazonaws.com` — see Notes). |
| `cloud_watch_logs_group_arn` | `string` | `null` | Existing log-group ARN; the `:*` stream suffix is appended automatically. Set together with `cloud_watch_logs_role_arn` (validated). |
| `cloud_watch_logs_role_arn` | `string` | `null` | Role CloudTrail assumes to write to the log group (needs `logs:CreateLogStream`/`logs:PutLogEvents`). |
| `sns_topic_name` | `string` | `null` | Topic name (or ARN for cross-region topics) notified per log delivery. |
| `recursive_logging` | `bool` | `null` | Log the events CloudTrail itself generates when delivering log files to the trail's destinations (S3, CloudWatch Logs); set `false` to suppress them. Newer provider attribute (floor ~6.72); when unset CloudTrail defaults it to `true`, so `false` is the meaningful explicit value. |
| `event_selectors` | `map(object)` | `{}` | Basic event selectors (≤5 per trail, validated); conflicts with `advanced_event_selectors` (validated). See below. |
| `advanced_event_selectors` | `map(object)` | `{}` | Advanced event selectors (up to 500 conditions total across the trail). See below. |
| `insight_types` | `list(string)` | `[]` | `ApiCallRateInsight` and/or `ApiErrorRateInsight` (distinct, validated); requires the trail's selectors to log the matching management events — see Notes. |
| `tags` | `map(string)` | `{}` | Tags; passed through unchanged. |

### `event_selectors` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `read_write_type` | `string` | `All` | `ReadOnly`, `WriteOnly` or `All` (validated). |
| `include_management_events` | `bool` | `true` | Include management events. |
| `exclude_management_event_sources` | `list(string)` | `[]` | Subset of `kms.amazonaws.com`, `rdsdata.amazonaws.com` (validated). |
| `data_resources` | `map(object)` | `{}` | Data-event selectors; each entry is `{type, values}`. `type` is one of `AWS::S3::Object`, `AWS::Lambda::Function`, `AWS::DynamoDB::Table` (validated); `values` is a list of ARNs or `arn:...:*` patterns. |

### `advanced_event_selectors` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | `null` | Selector name. |
| `field_selectors` | `map(object)` | — (required) | Field conditions; each entry is `{field, equals, starts_with, ends_with, not_equals, not_starts_with, not_ends_with}`. `field` is one of `readOnly`, `eventSource`, `eventName`, `eventCategory`, `resources.type`, `resources.ARN` (validated); `readOnly`, `eventCategory` and `resources.type` accept `equals` only (validated). |

## Outputs

| Name | Description |
|---|---|
| `trail_arns` | Map of key => trail ARN (also the `aws_cloudtrail` import ID — id and ARN are the same for this resource). |
| `trail_home_regions` | Map of key => home region. |

## Example

```hcl
trails = {
  "audit" = {
    name                       = "example-audit-trail"
    s3_bucket_name             = "example-audit-logs"
    s3_key_prefix              = "cloudtrail"
    is_multi_region_trail      = true
    enable_log_file_validation = true
    kms_key_id                 = "arn:aws:kms:eu-central-1:123456789012:key/example"
    cloud_watch_logs_group_arn = "arn:aws:logs:eu-central-1:123456789012:log-group:/example/audit"
    cloud_watch_logs_role_arn  = "arn:aws:iam::123456789012:role/example-cloudtrail-logs"
    advanced_event_selectors = {
      "s3-data" = {
        name = "example-s3-data-events"
        field_selectors = {
          "category" = { field = "eventCategory", equals = ["Data"] }
          "type"     = { field = "resources.type", equals = ["AWS::S3::Object"] }
        }
      }
    }
  }
  "org" = {
    name                  = "example-org-trail"
    s3_bucket_name        = "example-audit-logs"
    is_organization_trail = true
    is_multi_region_trail = true
  }
}
```

## Notes

- Event data stores (CloudTrail Lake) are out of scope — a separate resource
  family (`aws_cloudtrail_event_data_store`) with no S3 delivery and its own
  retention model; manage them consumer-side or in a future module.
- Organization trails can only be created from the organization management
  account; multi-region trails should be created in their intended home
  region (AWS enforces both at the API).
- The delivery bucket needs a policy allowing CloudTrail — at minimum
  `s3:GetBucketAcl` on the bucket and `s3:PutObject` on `prefix/AWSLogs/account/*`
  with an `aws:SourceArn` condition referencing the trail ARN.
- With `kms_key_id` set, the KMS key policy must allow
  `cloudtrail.amazonaws.com` at least `kms:GenerateDataKey*` and
  `kms:Decrypt` (pair with `aws/kms`, which takes a `policy`).
- Insights events require the trail's selectors to log the matching
  management events — `ApiCallRateInsight` needs write-only management
  events, `ApiErrorRateInsight` needs read-only and write-only (all).
- The first advanced event selector must carry an `eventCategory`
  field selector (semantic API rule; not plan-validatable).
- Pairing: the CloudWatch log-group wiring pairs with `aws/cloudwatch`
  log groups; the trail ARN feeds the S3 bucket-policy `aws:SourceArn`
  condition.

## Import

`aws_cloudtrail` ← trail ARN
(`arn:aws:cloudtrail:<region>:<account>:trail/<name>`).
