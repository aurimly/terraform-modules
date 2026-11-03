# aws/step-functions

Map-keyed module for Step Functions: Standard and Express state machines
with logging, tracing, encryption configuration and optional version
publishing, plus worker activities for poll-based task tokens.
Definitions are raw Amazon States Language strings — substitutions stay
consumer-side via `templatefile()`.

## Destroy semantics (read before using)

- Removing a state machine key deletes the state machine immediately —
  published versions and in-flight executions become unusable. Verify
  nothing references the ARN (EventBridge targets, consumer services)
  before removing the key.
- Changing `name`, `name_prefix` or `type` forces replacement (all three
  are ForceNew; the API rejects type changes outright — "You cannot
  update the type of a state machine once it has been created").
- `definition`, `role_arn`, `logging_configuration`,
  `tracing_configuration` and `encryption_configuration` update in place.
  Removing one of the three configuration blocks does not unset it
  upstream (the provider suppresses the missing-block diff) — set
  `level = "OFF"` to stop logging and the neutral values for tracing
  (`enabled = false`) and encryption (`type = "AWS_OWNED_KEY"`) instead.
- Removing an activity key deletes it immediately: workers polling
  `GetActivityTask` fail with `ActivityDoesNotExist` and in-flight task
  tokens can no longer be completed (`SendTask*` fails) — drain workers
  before removing activity keys.
- Activity `name` is ForceNew — renaming replaces the activity with a
  new ARN that any ASL Task state referencing it must be updated to.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `state_machines` | `map(object)` | `{}` | Map of state machines keyed by an arbitrary unique ID; each entry sets exactly one of `name`/`name_prefix` (validated). |
| `activities` | `map(object)` | `{}` | Map of worker activities keyed by an arbitrary unique ID. |

### `state_machines` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | State machine name, 1–80 characters of alphanumerics/hyphens/underscores (validated, matches the provider validator). |
| `name_prefix` | `string` | — | Name prefix, 1–54 characters of the same set (validated). The provider appends 26 hex characters directly after it — no auto-hyphen, so end the prefix with `-` for readable generated names. |
| `type` | `string` | `STANDARD` | `STANDARD` or `EXPRESS` (validated, case-sensitive); ForceNew. |
| `role_arn` | `string` | — | Execution role ARN (from `aws/iam-role`). |
| `definition` | `string` | — | Amazon States Language definition, at most 1 MiB (validated); pass `templatefile()`/`file()` output consumer-side. |
| `publish` | `bool` | `false` | Publish an immutable version at create and at every subsequent update; populates `state_machine_version_arns`. |
| `logging_configuration` | `object` | — | CloudWatch execution logging; table below. |
| `tracing_configuration` | `object` | — | `{enabled}` — X-Ray tracing. |
| `encryption_configuration` | `object` | — | At-rest encryption; table below. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` on name-based entries — Name wins on collision (consumer tags win on any other key). `name_prefix` entries pass tags through unchanged (the final name is unknowable at plan time). |

### `logging_configuration` object (state machines)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `log_destination` | `string` | — | CloudWatch log-group ARN ending in `:*` (validated). The log group is consumer-created; the state machine role needs CloudWatch Logs IAM. |
| `include_execution_data` | `bool` | — | Include execution data in logs. |
| `level` | `string` | — | `ALL`, `ERROR`, `FATAL` or `OFF` (validated, case-sensitive). |

### `tracing_configuration` object (state machines)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | — | X-Ray tracing on/off. |

### `encryption_configuration` object (state machines and activities)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `AWS_OWNED_KEY` or `CUSTOMER_MANAGED_KMS_KEY` (validated, case-sensitive). |
| `kms_key_id` | `string` | — | KMS key ARN; required when `type` is `CUSTOMER_MANAGED_KMS_KEY` (validated). |
| `kms_data_key_reuse_period_seconds` | `number` | — | Data-key reuse window in seconds, 60–900 (validated on activities; the provider enforces the same bound on state machines). |

### `activities` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Activity name, 1–80 characters of alphanumerics/hyphens/underscores (validated). Stricter than the API: names with other characters (e.g. `.`, `+`, non-ASCII) are API-valid but lose CloudWatch-Logs-compatible naming. The name is the `CreateActivity` idempotency key — no `name_prefix` is offered. |
| `encryption_configuration` | `object` | — | At-rest encryption; shared table above. Create-only on activities — see notes. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (Name wins on collision, consumer tags win on any other key). |

## Outputs

`state_machine_arns` — map of state machine key => state machine ARN
(unqualified; also the import ID).
`state_machine_names` — map of state machine key => final name
(provider-generated when `name_prefix` was used; for EventBridge
targets and `StartExecution`).
`state_machine_version_arns` — map of state machine key => latest
published version ARN; `null` for machines that have never published a
version, and stays populated after `publish` is reverted to `false`.
`creation_dates` — map of state machine key => creation date (RFC3339).
`activity_arns` — map of activity key => activity ARN (also the import
ID).
`activity_names` — map of activity key => activity name.

## Example

```hcl
state_machines = {
  "orders" = {
    name      = "example-orders"
    role_arn  = "arn:aws:iam::123456789012:role/example-sfn"
    definition = templatefile("${path.module}/orders.asl.json", {
      ProcessLambda = "arn:aws:lambda:us-east-1:123456789012:function:example-process"
      ManualReview  = "arn:aws:states:us-east-1:123456789012:activity:example-manual-review"
    })
    logging_configuration = {
      log_destination = "${aws_cloudwatch_log_group.example.arn}:*"
      level           = "ERROR"
    }
  },
  "telemetry" = {
    name_prefix = "example-telemetry-"
    type        = "EXPRESS"
    role_arn    = "arn:aws:iam::123456789012:role/example-sfn"
    definition  = jsonencode({
      StartAt = "Done"
      States = {
        Done = {
          Type = "Succeed"
        }
      }
    })
    publish = true
  }
}

activities = {
  "manual-review" = {
    name = "example-manual-review"
    encryption_configuration = {
      type       = "CUSTOMER_MANAGED_KMS_KEY"
      kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
    }
  }
}

# The "orders" template's Activity Task state uses the real activity ARN —
# the arn:aws:states:::sfn:* integration pseudo-ARN does not exist for
# activities, so Resource must be the activity ARN itself:
#   { "Type": "Task", "Resource": "${ManualReview}", "End": true }
# When activities live in a separate Terragrunt unit, supply it from that
# unit's output: dependency.activities.outputs.activity_arns["manual-review"].
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — the key is
  the stable reference for outputs and consumer wiring; the AWS-side
  identity is the (possibly generated) name.
- In-place updates are safe mid-flight: "Running executions will
  continue to use the previous definition and roleArn"
  (UpdateStateMachine API) — new definitions only reach executions
  started after the update.
- Versions: `publish = true` snapshots the machine at create and
  publishes an immutable new version on every subsequent update; version
  numbers are monotonic and never reused. `state_machine_version_arns`
  tracks the latest published version and survives un-publishing — pin
  the specific version ARN you start executions against instead of
  re-reading the output on every apply.
- `definition_substitutions` does not exist on
  `aws_sfn_state_machine` (an awscc-provider-only API parameter that was
  never mapped) — do substitutions consumer-side with `templatefile()`,
  exactly what the AWS best-practices blog for Step Functions Terraform
  projects prescribes.
- `logging_configuration.log_destination` must end with `:*`; the state
  machine role needs CloudWatch Logs and X-Ray IAM per the AWS
  logging docs.
- Tags apply to the machine as a whole (shared by all published
  versions). The module's Name merge covers `name`-based entries only —
  a `name_prefix` entry's final name is unknowable at plan time.
- Activities: `CreateActivity` is idempotent on `name` (tag differences
  are ignored; names must be unique per account and region for 90 days).
  KMS at-rest encryption for activities shipped June 2024; the registry
  page's encryption `type` value `AWS_KMS_KEY` is a documentation
  discrepancy — the shared Step Functions API enum (and this module's
  validation) uses `AWS_OWNED_KEY`.
- Activity `encryption_configuration` is create-only: `CreateActivity`
  refuses updates ("EncryptionConfiguration may not be updated" when
  re-creating with the same name) and the provider's update path handles
  tags only — changing the block on an existing activity is silently
  unapplied (silent drift; no plan-time guard is possible). Re-encrypt
  by renaming the activity (ForceNew replacement, new ARN).
- `aws_sfn_state_machine` plan validates ASL server-side via the
  `ValidateStateMachineDefinition` API (provider CustomizeDiff) —
  consumer `plan` needs API access for definition changes, and
  `tofu validate`/`terragrunt validate` with the empty test map will
  not surface ASL errors.
- `version_description` exists in the provider schema but is
  intentionally out of the module surface.

## Import

`aws_sfn_state_machine` ← full state machine ARN
(`arn:aws:states:<region>:<account>:stateMachine:<name>`), not the name.
Published versions and aliases are not managed here — consumers who
adopt them mid-life import them outside this module.
`aws_sfn_activity` ← activity ARN
(`arn:aws:states:<region>:<account>:activity:<name>`).
