# gcp/monitoring

Map-keyed module for Google Cloud Monitoring dashboards and alert
policies. Notification channels are referenced by resource name and are
not managed here.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `dashboards` | `map(object)` | — | Map of dashboards keyed by an arbitrary unique ID. |
| `alert_policies` | `map(object)` | — | Map of alert policies keyed by an arbitrary unique ID. |

### `dashboards` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `dashboard_json` | `string` | — | Cloud Monitoring dashboard JSON (validated to parse and to contain `displayName` at plan time). |
| `project_id` | `string` | — | Project the dashboard lives in; defaults to the provider-level project. |

### `alert_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `display_name` | `string` | — | Policy display name. |
| `combiner` | `string` | — | One of `OR`, `AND`, `AND_WITH_MATCHING_RESOURCE` (validated). |
| `project_id` | `string` | — | Project the policy lives in; defaults to the provider-level project. |
| `enabled` | `bool` | `true` | Disable without deleting. |
| `notification_channels` | `list(string)` | `[]` | Channel **resource names** (`projects/x/notificationChannels/123`), managed elsewhere. |
| `user_labels` | `map(string)` | `{}` | Labels for routing/filtering. |
| `documentation` | `object` | — | `{content, mime_type, subject, links}` (`links`: `{display_name, url}`); `mime_type` one of `text/markdown`, `text/plain`. |
| `alert_strategy` | `object` | — | `{auto_close, notification_rate_limit = {period}}`. |
| `conditions` | `list(object)` | — | Required, ≥ 1 (validated); see the condition tables. |

### `conditions` object

Each entry sets exactly one of `condition_threshold`,
`condition_absent`, `condition_monitoring_query_language` or
`condition_prometheus_query_language` (validated).

| Condition | Fields |
|---|---|
| `condition_threshold` | `filter` (required), `duration` (required, e.g. `60s`), `comparison` (required; one of `COMPARISON_GT`, `COMPARISON_GE`, `COMPARISON_LT`, `COMPARISON_LE`, `COMPARISON_EQ`, `COMPARISON_NE`, validated), `threshold_value`, `trigger` (`{count}` XOR `{percent}`, validated), `evaluation_missing_data` (one of `EVALUATION_MISSING_DATA_INACTIVE`, `EVALUATION_MISSING_DATA_ACTIVE`, `EVALUATION_MISSING_DATA_NO_OP`, validated), `denominator_filter`, `aggregations` and `denominator_aggregations` (`{alignment_period, per_series_aligner, cross_series_reducer, group_by_fields}`). |
| `condition_absent` | `filter` (required), `duration` (required), `trigger` (XOR `count`/`percent`), `aggregations`. |
| `condition_monitoring_query_language` | `query` (required, MQL), `duration`, `trigger`, `evaluation_missing_data`. |
| `condition_prometheus_query_language` | `query` (required, PromQL), `duration`, `evaluation_interval`. |

## Outputs

`dashboard_ids` — map of dashboard key => dashboard id.
`alert_policy_names` — map of alert policy key => full alert policy
resource name (`projects/x/alertPolicies/123`).

## Example

```hcl
dashboards = {
  "main" = {
    dashboard_json = jsonencode({
      displayName = "Example dashboards"
      gridLayout = {
        widgets = [
          {
            title = "Cloud Run request count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\""
                  }
                }
              }]
            }
          },
        ]
      }
    })
  }
}

alert_policies = {
  "api-latency" = {
      display_name = "example-api p99 latency"
      combiner     = "OR"
      notification_channels = [
        "projects/example-prj/notificationChannels/1234567890",
      ]
      documentation = {
        content = "Check the example-api runbook at https://wiki.example.example/runbooks/api."
      }
      alert_strategy = {
        auto_close = "1800s"
        notification_rate_limit = {
          period = "300s"
        }
      }
      conditions = [
        {
          display_name = "p99 latency > 500ms"
          condition_threshold = {
            filter         = "metric.type=\"run.googleapis.com/request_latencies\" resource.type=\"cloud_run_revision\""
            duration       = "60s"
            comparison     = "COMPARISON_GT"
            threshold_value = 500
            aggregations = [
              {
                alignment_period    = "60s"
                per_series_aligner  = "ALIGN_PERCENTILE_99"
                cross_series_reducer = "REDUCE_MEAN"
                group_by_fields     = ["resource.labels.service_name"]
              },
            ]
          }
        }
    ]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers.
- Notification channels are referenced by resource name and are NOT managed
  here — a `gcp/notification-channel` module is a candidate for later.
- Dashboard JSON must follow the Cloud Monitoring JSON dashboard schema
  (`displayName` is plan-validated); keep raw JSON in `jsondecode`-safe
  `jsonencode` or heredoc form.
- Dashboard diffs on JSON drift freely (field ordering, defaults filled in
  by the API) — expect noisy plans on hand-written JSON.
- Alert conditions via `condition_matched_log` (log-based alerts) are not
  modeled here; use log metrics + `condition_threshold` instead.
- `notification_rate_limit` only applies to channel types that support it
  (e.g. PagerDuty/SMS ignore it).
- Per-project granularity is via `project_id` on each entry.

## Import

`google_monitoring_dashboard` ← `projects/{project_id}/dashboards/{dashboard_id}` or bare `{dashboard_id}`.
`google_monitoring_alert_policy` ← `{project_id}/{alert_policy_id}`
(also the space-delimited `{project_id} {alert_policy_id}` form on older
provider pins).
