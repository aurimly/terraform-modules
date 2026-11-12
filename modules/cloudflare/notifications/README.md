# cloudflare/notifications

Map-keyed module for Cloudflare Notifications: notification policies (any
alert type, with filters and re-alert intervals) plus webhook destinations.
Webhook mechanisms on policies wire in-module by `webhooks` map key;
email and PagerDuty destinations are referenced by ID (the provider has no
resource managing them).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | — | Cloudflare account ID; all resources live in this account. |
| `webhooks` | `map(object)` | `{}` | Map of webhook destinations keyed by an arbitrary unique ID. |
| `policies` | `map(object)` | `{}` | Map of notification policies keyed by an arbitrary unique ID. |

Plan-time validation: `alert_type` matches the provider's alert-type enum
(case-insensitive; new Cloudflare alert types need a module release), and
`filters.incident_impact` entries match the API validators
(case-insensitive). Which `mechanisms.webhooks` keys exist is checked as a
lifecycle precondition on the policy resource.

### `webhooks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Destination name; included in the webhook request body. |
| `url` | `string` | — | POST endpoint. The API infers the destination type from the URL — `type` is not settable on this resource (provider v5) and surfaces as the `webhook_types` output. |
| `secret` | `string` | `null` | Passed in the `cf-webhook-auth` header (or formatted for supported destinations). Write-only: never returned by the API, so client-side changes are invisible to plan. |

### `policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy name. |
| `alert_type` | `string` | — | Event that triggers the notification (validated against the full provider enum). |
| `description` | `string` | `null` | Free-form description. |
| `enabled` | `bool` | `true` | Whether the policy dispatches. |
| `alert_interval` | `string` | `null` | How often to re-alert on the same incident (e.g. `30m`); not supported on all alert types — the API rejects unsupported values at apply. |
| `filters` | `object` | `{}` | Alert-type-specific filters; see below. Only select alert types accept filters. |
| `mechanisms` | `object` | — | Destinations; see below. |

### `filters` object

All 44 attributes are `optional(list(string))` — including
`filters.enabled`, which takes `"true"`/`"false"` **strings**. Keys map 1:1
to the API; usage is alert-type specific (the provider descriptions say
which alert type uses which key — e.g. `tunnel_id`/`new_status` for
`tunnel_health_event`, `limit`/`product` for `billing_usage_alert`,
`health_check_id`/`status` for `health_check_status_notification`).

`token_id` (Access service-token IDs, for `expiring_service_token_alert` —
omit it to include all current and future tokens) is a newer provider
attribute that recent provider releases know about; on older pinned
versions setting it fails with an unexpected-attribute error.

### `mechanisms` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `email` | `list(string)` | `null` | Destination **addresses — must already be verified** in the Cloudflare dashboard; there is no provider resource (or data source) managing verified addresses, and the API rejects unverified ones at apply. |
| `pagerduty` | `list(string)` | `null` | PagerDuty integration IDs (UUIDs created in PagerDuty/the dashboard). |
| `webhooks` | `list(string)` | `null` | Keys of the `webhooks` map — resolved to the created destination IDs by this module. Referencing a key that doesn't exist fails at plan (precondition). |

## Outputs

| Name | Description |
|---|---|
| `policy_ids` | Map of policy key => policy UUID. |
| `webhook_ids` | Map of webhook key => webhook destination UUID. |
| `webhook_types` | Map of webhook key => API-inferred destination type (`datadog`, `discord`, `feishu`, `gchat`, `generic`, `opsgenie`, `slack`, `splunk`). |

## Example

```hcl
webhooks = {
  "slack" = {
    name   = "example-slack"
    url    = "https://hooks.slack.com/services/example/example/example"
    secret = "example-secret"
  }
}

policies = {
  "tunnel-health" = {
    name       = "example tunnel health"
    alert_type = "tunnel_health_event"
    filters = {
      tunnel_id  = ["example-tunnel-id"]
      new_status = ["UNHEALTHY"]
    }
    alert_interval = "1h"
    mechanisms = {
      webhooks = ["slack"]
    }
  }
  "cert-expiry" = {
    name       = "example certificate expiry"
    alert_type = "universal_ssl_event_type"
    mechanisms = {
      email     = ["ops@example.com"]
      pagerduty = ["f174e90afafe4643bbbc4a0ed4fc8415"]
    }
  }
}
```

## Notes

- `alert_type` accepts the full provider enum (case-sensitive). When
  Cloudflare adds new alert types, extend the list — plan-time validation
  rejects them until then.
- Webhook destination `type` is API-computed (inferred from the URL) in
  provider v5 — set it by choosing the right URL, read it from the
  `webhook_types` output.
- Webhook secrets are write-only: changes made outside Terraform never
  surface as drift. Rotate via config and re-apply deliberately.
- Policies reference webhook destinations created by this module; for
  destinations managed elsewhere, adopt them into the `webhooks` map here
  (import them — see below) or manage such policies consumer-side: the
  precondition only accepts keys of this module's `webhooks` map.
- Filters and `alert_interval` are only accepted for select alert types —
  the API rejects unsupported combinations at apply; the provider
  descriptions name which filter keys map to which alert types.

## Import

`cloudflare_notification_policy` ← `<account_id>/<policy_id>`.
`cloudflare_notification_policy_webhooks` ← `<account_id>/<webhook_id>`.
