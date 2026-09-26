# aws/cloudwatch

Map-keyed module for CloudWatch: log groups (retention, KMS, storage
class), classic metric alarms, and dashboards. Alarms use the
`metric_name`/`namespace`/`statistic` path; alarm actions are ARN
references (pair with `aws/sns` for topics — no topics are created
here). Dashboards take the JSON body as a string, typically built with
`jsonencode()`.

## Destroy semantics (read before using)

- Log groups with `skip_destroy = true` are removed from state but left
  in AWS (logs preserved, continues to bill for storage).
- `deletion_protection_enabled = true` blocks deletion at the AWS API;
  the destroy fails until protection is turned off. Once set, switching
  to `false` requires explicitly specifying `false` rather than removing
  the argument.
- Without retention, log groups keep logs indefinitely (storage cost).
  `retention_in_days = 0` means "never expire" — omitting the attribute
  also means never expire.
- Alarms and dashboards are deleted immediately with the module.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `log_groups` | `map(object)` | `{}` | Log groups keyed by an arbitrary unique ID. |
| `metric_alarms` | `map(object)` | `{}` | Metric alarms keyed by an arbitrary unique ID. |
| `dashboards` | `map(object)` | `{}` | Dashboards keyed by an arbitrary unique ID. |

### `log_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Log group name. Exactly one of `name`/`name_prefix` (validated). |
| `name_prefix` | `string` | — | Prefix; a unique suffix is appended by AWS. |
| `retention_in_days` | `number` | — | One of `0` (never expire), `1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653` (validated). Omit for indefinite retention. |
| `kms_key_id` | `string` | — | KMS key ARN for log encryption (pair with `aws/kms`). |
| `log_group_class` | `string` | — | `STANDARD`, `INFREQUENT_ACCESS` or `DELIVERY` (validated). With `DELIVERY`, retention is ignored and forced to 2 by AWS. |
| `skip_destroy` | `bool` | `false` | Remove from state without deleting the group. |
| `deletion_protection_enabled` | `bool` | — | API-level deletion guard (see destroy semantics). |
| `tags` | `map(string)` | `{}` | Tags; passed through unchanged (no `Name` merge). |

### `metric_alarms` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `alarm_name` | `string` | — | Alarm name; must be unique in the account/region. |
| `alarm_description` | `string` | — | Alarm description. |
| `namespace` | `string` | — | Metric namespace, e.g. `AWS/ApplicationELB`. |
| `metric_name` | `string` | — | Metric name. |
| `dimensions` | `map(string)` | `{}` | Metric dimensions. |
| `statistic` | `string` | — | `SampleCount`, `Average`, `Sum`, `Minimum` or `Maximum` (validated). Exactly one of `statistic`/`extended_statistic` (validated). |
| `extended_statistic` | `string` | — | Percentile, e.g. `p99.9`. |
| `period` | `number` | `300` | Evaluation period in seconds: `10`, `20`, `30` or a multiple of `60` (validated). |
| `evaluation_periods` | `number` | — | Periods over which the alarm is evaluated (required). |
| `datapoints_to_alarm` | `number` | — | Breaching periods required; defaults to `evaluation_periods`. Must be ≤ `evaluation_periods` (validated). |
| `threshold` | `number` | — | Threshold to compare against (required). |
| `comparison_operator` | `string` | — | `GreaterThanOrEqualToThreshold`, `GreaterThanThreshold`, `LessThanThreshold` or `LessThanOrEqualToThreshold` (validated). Anomaly band operators need `metric_query`, which is out of scope. |
| `treat_missing_data` | `string` | `missing` | `missing`, `ignore`, `breaching` or `notBreaching` (validated). |
| `unit` | `string` | — | Metric unit for the threshold, e.g. `Seconds` (the alarm fires only when the metric reports in that unit). |
| `actions_enabled` | `bool` | `true` | Whether actions run. |
| `alarm_actions` | `list(string)` | `[]` | ARNs to fire on breach (SNS topics, scaling policies, ...; validated `arn:`). |
| `ok_actions` | `list(string)` | `[]` | ARNs to fire on return to OK (validated). |
| `insufficient_data_actions` | `list(string)` | `[]` | ARNs to fire on INSUFFICIENT_DATA (validated). |
| `tags` | `map(string)` | `{}` | Tags; passed through unchanged. |

### `dashboards` object

| Attribute | Type | Description |
|---|---|---|
| `dashboard_name` | `string` | Dashboard name (1–255 chars, must be unique in the account/region). |
| `dashboard_body` | `string` | Full JSON dashboard document (validated JSON). Build with `jsonencode({ widgets = [...] })`. |

## Outputs

`log_group_names`, `log_group_arns` — log group key => name / ARN.
`alarm_names`, `alarm_arns` — alarm key => name / ARN.
`dashboard_names`, `dashboard_arns` — dashboard key => name / ARN.

## Example

```hcl
inputs = {
  log_groups = {
    "app-http" = {
      name              = "/example/app/http"
      retention_in_days = 30
      tags              = { Environment = "example" }
    }
  }
  metric_alarms = {
    "app-5xx" = {
      alarm_name          = "example-alb-5xx-high"
      namespace           = "AWS/ApplicationELB"
      metric_name         = "HTTPCode_Target_5XX_Count"
      dimensions          = { LoadBalancer = dependency.alb.outputs.load_balancer_arn_suffixes["public"] }
      statistic           = "Sum"
      period              = 60
      evaluation_periods  = 5
      datapoints_to_alarm = 3
      threshold           = 10
      comparison_operator = "GreaterThanThreshold"
      alarm_actions       = [dependency.alerts.outputs.topic_arns["ops"]]
    }
  }
  dashboards = {
    "app" = {
      dashboard_name = "example-app"
      dashboard_body = jsonencode({
        widgets = [
          {
            type = "metric"
            properties = {
              title  = "example app errors"
              view   = "timeSeries"
              region = "example-region"
              metrics = [
                ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/example/123"]
              ]
            }
          }
        ]
      })
    }
  }
}
```

## Notes

- **AWS provider >= 6.0.0 required** — alarm `dimensions` as a map
  attribute and other v6 schema details are assumed; the module
  declares no `required_providers` (like all `modules/aws/*` here), so
  pin the provider at the consumer's root.
- Alarm actions take ARNs directly; `dependency` chaining from
  `aws/sns` topics is the intended SNS source. There is no SNS policy
  wiring here — grant `cloudwatch.amazonaws.com` publish permission on
  the topic consumer-side.
- Anomaly detection (band operators, `metric_query`, composite alarms)
  is out of scope; both are backward-compatible MINOR additions later.
- Dashboard JSON bodies can get large; the CloudWatch API rejects
  documents over ~256KiB with many widgets — split large dashboards
  into multiple entries.
- Log group names are region-unique; `name_prefix` collision or a name
  that already exists outside this module fails at apply.

## Import

`aws_cloudwatch_log_group` ← log group name.
`aws_cloudwatch_metric_alarm` ← alarm name.
`aws_cloudwatch_dashboard` ← dashboard name.
