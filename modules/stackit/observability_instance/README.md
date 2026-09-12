# stackit/observability_instance

Map-keyed module for STACKIT Observability (Argus) instances: plan, ACL,
retention, Grafana admin, and alerting configuration.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of Observability instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance is created in (validated). Changing it replaces the instance. |
| `name` | `string` | — | Instance name, 1–200 characters (validated). |
| `plan_name` | `string` | — | Region-suffixed plan name (e.g. `Observability-Starter-EU01`), 1–200 characters (validated). The plan catalog is region- and time-dependent — see the STACKIT Observability documentation for the current list. |
| `acl` | `list(string)` | `null` | IPv4 CIDRs allowed to reach the instance (validated). Applied via a separate ACL endpoint after create/update — see the drift note. |
| `alert_config` | `object` | `null` | Alerting configuration; see the `alert_config` object table. Rejected at apply by plans without alerting. |
| `grafana_admin_enabled` | `bool` | API default (`true`) | Grafana admin user enabled. The provider recommends `false` plus STACKIT SSO (Owner / Observability Grafana Server Admin role). Rejected at apply by plans without Grafana. |
| `logs_retention_days` | `number` | API default (`7`) | Log retention in days. Rejected at apply by plans without log storage. |
| `traces_retention_days` | `number` | API default (`7`) | Trace retention in days. Rejected at apply by plans without trace storage. |
| `metrics_retention_days` | `number` | API default (`90`) | Raw metric retention in days. Rejected at apply by plans without metric samples. |
| `metrics_retention_days_5m_downsampling` | `number` | API default (`90`) | 5m-downsampled metric retention in days; must be less than `metrics_retention_days` (validated when both are set). |
| `metrics_retention_days_1h_downsampling` | `number` | API default (`90`) | 1h-downsampled metric retention in days; must be less than `metrics_retention_days_5m_downsampling` (validated when both are set). |
| `parameters` | `map(string)` | `null` | Plan-specific parameters, passed through unvalidated. |

### `alert_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `receivers` | `list(object)` | — | At least one receiver; see the `receivers` object table. A list, not a map — receiver order is semantic (first-match routing) and entries have no natural key. |
| `route` | `object` | — | Root route; see the `route` object table. |
| `global` | `object` | `null` | Global alertmanager settings; see the `global` object table. Upstream replaces the entire global block on any change to it — partial updates are not possible. |

### `receivers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Receiver name referenced by routes. |
| `email_configs` | `list(object)` | `null` | At least one entry when set: `{auth_identity, auth_password, auth_username, from, send_resolved, smart_host, to}`. `auth_password` is provider-sensitive. |
| `opsgenie_configs` | `list(object)` | `null` | At least one entry when set: `{api_key, api_url, priority, send_resolved, tags}`; `priority` is `P1`–`P5`. |
| `webhooks_configs` | `list(object)` | `null` | At least one entry when set: `{url, ms_teams, google_chat, send_resolved}`. `url` is provider-sensitive. `ms_teams` and `google_chat` cannot both be `true` (validated). |

`send_resolved` defaults to `true` upstream for all three config types;
`ms_teams`/`google_chat` default to `false`.

### `route` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `receiver` | `string` | — | Default receiver name for unmatched alerts. |
| `group_by` | `list(string)` | `null` | Labels to group alerts by. |
| `group_wait` | `string` | `null` | Wait before sending the first notification. |
| `group_interval` | `string` | `null` | Wait between notifications for a group. |
| `repeat_interval` | `string` | `null` | Wait before re-notifying a group. |
| `routes` | `list(object)` | `null` | Child routes: `{receiver, continue, group_by, group_wait, group_interval, matchers, repeat_interval}`. Single level — child routes cannot nest further upstream. `matchers` is the replacement for the deprecated `match`/`match_regex` attributes, which are intentionally not exposed. |

### `global` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `opsgenie_api_key` | `string` | `null` | Opsgenie API key (provider-sensitive). |
| `opsgenie_api_url` | `string` | `null` | Opsgenie API URL. |
| `resolve_timeout` | `string` | `null` | Alert resolve timeout. |
| `smtp_auth_identity` | `string` | `null` | SMTP auth identity. |
| `smtp_auth_password` | `string` | `null` | SMTP auth password (provider-sensitive). |
| `smtp_auth_username` | `string` | `null` | SMTP auth username. |
| `smtp_from` | `string` | `null` | Sender address. |
| `smtp_smart_host` | `string` | `null` | SMTP smart host. |

## Outputs

`instances` — map of instance key => object:

| Attribute | Description |
|---|---|
| `instance_id` | Instance UUID. |
| `plan_id` | Plan UUID the instance runs on. |
| `dashboard_url` | Dashboard URL. |
| `grafana_url` | Grafana URL. |
| `grafana_public_read_access` | Whether public read access is enabled (provider-reported). |
| `alerting_url` | Alerting API URL. |
| `metrics_url` | Metrics query URL. |
| `metrics_push_url` | Metrics push URL. |
| `targets_url` | Scrape targets URL. |
| `logs_url` | Logs query URL. |
| `logs_push_url` | Logs push URL. |
| `jaeger_traces_url` | Jaeger traces URL. |
| `jaeger_ui_url` | Jaeger UI URL. |
| `otlp_grpc_traces_url` | OTLP/gRPC traces URL. |
| `otlp_http_logs_url` | OTLP/HTTP logs URL. |
| `otlp_http_traces_url` | OTLP/HTTP traces URL. |
| `otlp_traces_url` | OTLP traces URL. |
| `zipkin_spans_url` | Zipkin spans URL. |
| `is_updatable` | Whether the plan allows in-place updates (provider-reported). |
| `id` | `"{project_id},{instance_id}"` — the import ID. |

## Example

```hcl
module "observability_instance" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/observability_instance?ref=v1.3.0"

  instances = {
    "ops" = {
      project_id             = "12345678-1234-1234-1234-123456789012"
      name                   = "example-observability"
      plan_name              = "Observability-Starter-EU01"
      acl                    = ["10.1.0.0/16"]
      grafana_admin_enabled  = false
      metrics_retention_days = 90
      alert_config = {
        receivers = [
          {
            name = "team-mail"
            email_configs = [
              {
                to            = "team@example.com"
                from          = "alerts@example.com"
                auth_username = "alerts@example.com"
                auth_password = "example-password"
              },
            ]
          },
        ]
        route = {
          receiver = "team-mail"
        }
      }
    }
  }
}
```

## Notes

- **No `region` input** — the resource has no region attribute; the
  region comes from the provider configuration. Instances in multiple
  regions need multiple provider configurations/aliases on the consumer
  side.
- Plan-dependent restrictions are enforced apply-time by the provider
  (an API check during plan/apply): plans without Grafana reject
  `grafana_admin_enabled`, plans without alerting reject
  `alert_config`, plans without metric samples reject all three
  `metrics_retention_days*`, and plans without log/trace storage reject
  `logs_retention_days`/`traces_retention_days`. These cannot be caught
  at plan time module-side — a plan that passes validation can still
  fail at apply on an unsupported plan.
- The retention-ordering checks (5m < raw, 1h < 5m) only fire when both
  sides of the comparison are set: the module cannot see the
  provider-applied defaults, so e.g. a lone
  `metrics_retention_days_1h_downsampling = 120` passes validation and
  fails upstream. Set the full chain explicitly to rely on the checks.
- Sensitive values in `alert_config` — webhook `url`, email
  `auth_password`, `global.smtp_auth_password`,
  `global.opsgenie_api_key` — are provider-sensitive;
  `opsgenie_configs.api_key` is not marked sensitive upstream but is
  still a credential. Supply all of them from a secrets manager, not
  literals.
- Push URLs (`metrics_push_url`, `logs_push_url`) are not credentials
  but should be treated as semi-secret; write credentials come from
  `stackit_observability_credential`, which is not covered here (nor
  are alert groups, scrape configs, or load balancer observability
  credentials). Grafana dashboards have no Terraform resource upstream
  — manage them via the Grafana UI/API.
- `acl` is applied via a separate ACL endpoint after create/update, and
  the API re-lists it on every read: out-of-band ACL edits show up as
  perpetual diffs until reconciled through Terraform.
- The deprecated upstream attributes — `grafana_initial_admin_user` /
  `grafana_initial_admin_password` outputs (removal after 2026-07-05)
  and child-route `match`/`match_regex` (removal after 2026-03-10,
  replaced by `matchers`) — are intentionally not exposed.
- Keys are arbitrary unique identifiers, not instance names.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, name/plan length, CIDRs, webhook mutual exclusion) plus the
  documented retention-ordering API rules.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_observability_instance` ← `{project_id},{instance_id}`
