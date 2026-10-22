# aws/eventbridge

Map-keyed module for EventBridge: custom and partner event buses (with
optional access policy), rules (cron/rate or event-pattern) with their
targets, per-bus archives, and the separate EventBridge Scheduler side —
schedule groups and schedules.

## Destroy semantics (read before using)

- Removing a bus key destroys the bus. Rules referencing it fail plan
  with a lookup error — remove those rules first (their keys or switch
  them to `event_bus_name`). Archives are destroyed through the bus
  (remove the archive keys together with the bus key in the same plan).
  The default bus cannot be destroyed here (it is not managed by name).
- Removing a rule key destroys the rule and its targets.
- Archiving without a deletion date archives forever (archival quota); a
  removed archive entry stops archiving when destroyed.
- Schedules with `action_after_completion = "DELETE"` delete themselves
  (the schedule object) from AWS after their final invocation completes
  — one-time `at(...)` schedules drift out of state that way; treat
  setting the flag as a state-drift expectation, not as deleting
  targets.
- Bus names and rule names are immutable; renaming a rule is
  destroy + create.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `event_buses` | `map(object)` | `{}` | Event buses keyed by an arbitrary unique ID. |
| `rules` | `map(object)` | `{}` | Event rules keyed by an arbitrary unique ID, with targets. |
| `schedules` | `map(object)` | `{}` | Scheduler schedules keyed by an arbitrary unique ID. |
| `schedule_groups` | `map(object)` | `{}` | Scheduler schedule groups keyed by an arbitrary unique ID. |

### `event_buses` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Bus name, up to 256 chars of alphanumerics/`.` `-` `_` (validated). Required. |
| `event_source_name` | `string` | — | Partner event source (`aws.partner/...`, validated); creates the bus the partner events arrive on — `name` must equal it (precondition). |
| `description` | `string` | — | Bus description. |
| `policy` | `string` | — | JSON resource policy admitting publishers/subscribers (validated JSON). |
| `archives` | `map(object)` | `{}` | Archives fed by this bus; `kms_key_arn` pairs with `aws/kms`. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name` (consumer tags win on any other key). |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name, up to 64 chars of alphanumerics/`.` `-` `_` (validated); unique per bus across keys (validated). |
| `event_bus_key` | `string` | — | Key into `event_buses` this rule fires on. Exactly one of `event_bus_key`/`event_bus_name` (precondition). |
| `event_bus_name` | `string` | — | Literal bus name — use `"default"` to attach rules to the default bus (validated format). |
| `description` | `string` | — | Rule description. |
| `schedule_expression` | `string` | — | `cron(...)` or `rate(...)` (validated). Exactly one of `schedule_expression`/`event_pattern` (precondition). |
| `event_pattern` | `string` | — | JSON event pattern (validated JSON); use `jsonencode()`. |
| `role_arn` | `string` | — | IAM role assumed when the rule invokes another account's resources. |
| `state` | `string` | `ENABLED` | `ENABLED` or `DISABLED` (validated). |
| `force_destroy` | `bool` | `false` | Also delete AWS-managed rules (e.g. subscribed SaaS event sources) that block rule deletion. |
| `targets` | `map(object)` | `{}` | Targets attached to this rule; see the `targets` object table. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `targets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `arn` | `string` | — | Target resource ARN (`aws:arn:sqs`, lambda, etc.). Required. |
| `target_id` | `string` | — | Target identifier used in the rule; defaults to a provider-generated one. |
| `role_arn` | `string` | — | IAM role granting permission to put events onto the target. |
| `input` | `string` | — | JSON template overriding the event payload delivered (validated JSON). At most one of `input`/`input_path` (precondition). |
| `input_path` | `string` | — | JSONPath payload selection. |
| `dead_letter_arn` | `string` | — | SQS queue ARN receiving undeliverable events. |
| `message_group_id` | `string` | — | FIFO queue group (creates the `sqs_target` block). |
| `retry_policy` | `object` | `{}` | `{maximum_event_age_in_seconds, maximum_retry_attempts}` (24h/185 daily ages/retries on the API side). |
| `batch_parameters` | `object` | — | Batch job dispatch: `{job_definition, job_name, array_size, job_attempts}`. |
| `http_parameters` | `object` | — | API destination HTTP target: `{path_parameter_values, query_string_parameters, header_parameters}`. |

### `schedules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Schedule name, up to 64 chars of alphanumerics/`.` `-` `_` (validated). |
| `group_name` | `string` | — | Literal group name of a group in `schedule_groups` (format-validated); omit for the `default` group. |
| `description` | `string` | — | Schedule description. |
| `schedule_expression` | `string` | — | `cron(...)`, `rate(...)` or `at(...)` (validated; `at` is the one-time form). |
| `schedule_expression_timezone` | `string` | — | IANA timezone the schedule evaluates in (e.g. `Europe/Berlin`). |
| `start_date` / `end_date` | `string` | — | ISO-8601 activation window. |
| `state` | `string` | `ENABLED` | `ENABLED` or `DISABLED` (validated). |
| `kms_key_arn` | `string` | — | KMS key encrypting the schedule payload (pair with `aws/kms`). |
| `flexible_time_window` | `object` | `{mode = "OFF"}` | `{mode = "OFF"\|"FLEXIBLE" (validated), maximum_window_in_minutes (1–1440, validated)}`. |
| `target` | `object` | — | `{arn, role_arn (required on Scheduler), input (validated JSON), dead_letter_arn, action_after_completion ("DELETE"\|"NONE", validated — DELETE deletes the one-time schedule itself after its final fire), retry_policy {maximum_event_age_in_seconds (60–86400), maximum_retry_attempts (0–185)}}`. |

### `schedule_groups` object

`{name, tags}` — group name up to 64 chars of alphanumerics/`.` `-` `_`
(validated).

## Outputs

`bus_arns` — map of bus key => bus ARN.
`bus_names` — map of bus key => bus name.
`rule_arns` — map of rule key => rule ARN.
`rule_names` — map of rule key => rule name.
`target_arns` — map of `"rule-key.target-key"` => target ARN (the input
ARN echoed back; targets carry no AWS-issued id — see `aws/sns`'s
subscription ARNs for the issued case).
`archive_arns` — map of `"bus-key.archive-key"` => archive ARN.
`schedule_arns` — map of schedule key => schedule ARN.
`schedule_group_arns` — map of group key => group ARN.

## Example

```hcl
event_buses = {
  "orders" = {
    name = "example-orders"
  }
}
rules = {
  "orders-created" = {
    name          = "example-orders-created"
    event_bus_key = "orders"
    event_pattern = jsonencode({
      source        = ["example.app"]
      "detail-type" = ["order.created"]
    })
    targets = {
      "jobs" = {
        arn        = "arn:aws:sqs:eu-central-1:111111111111:example-jobs"
        dead_letter_arn = "arn:aws:sqs:eu-central-1:111111111111:example-events-dlq"
      }
    }
  }
}
schedules = {
  "nightly" = {
    name                = "example-nightly"
    schedule_expression = "rate(1 day)"
    target = {
      arn      = "arn:aws:sqs:eu-central-1:111111111111:example-jobs"
      role_arn = "arn:aws:iam::111111111111:role/example-scheduler"
      retry_policy = {
        maximum_retry_attempts = 5
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — two rules
  may share a `name` on different buses; the key disambiguates them.
- Rule names must be unique per bus; the module validates that two keys
  referencing the same bus do not collide.
- Targets are nested under each rule entry (`rules.targets`); to attach
  targets to a rule defined outside this module, use the
  `aws_cloudwatch_event_target` resource consumer-side.
- Scheduler schedules and schedule groups are the separate EventBridge
  Scheduler API (not classic CloudWatch events); schedules reference
  groups by literal name, so groups are created in the same call but
  wired consumer-side.
- Out of this module: API destinations/connections
  (`aws_cloudwatch_event_api_destination`, `..._connection`), Pipes, and
  archive replay (the AWS API operation; archives themselves are here).
  Target parameter blocks beyond `batch_target`, `http_target` and
  `sqs_target` (`ecs_parameters`, `kinesis_parameters`,
  `redshift_data_parameters`, `sagemaker_pipeline_parameters`,
  `input_transformer`) are not modeled.
- The provider version floor for the resources used is `>= 6.0.0`.

## Import

`aws_cloudwatch_event_bus` ← bus name.
`aws_cloudwatch_event_bus_policy` ← bus name.
`aws_cloudwatch_event_rule` ← rule name (default bus) or full rule ARN
(custom buses).
`aws_cloudwatch_event_target` ← `<rule-name>/<target-id>` for the
default bus, `<event-bus-name>/<rule-name>/<target-id>` for custom
buses (alternatively the full rule ARN).
`aws_cloudwatch_event_archive` ← archive name.
`aws_scheduler_schedule` ← `<group-name>/<schedule-name>` (the `default`
group is implicit).
`aws_scheduler_schedule_group` ← group name.

Some of these import addresses changed shape across provider
releases — verify against the provider version your consumer pins.
