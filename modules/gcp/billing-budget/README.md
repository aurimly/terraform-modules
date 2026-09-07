# gcp/billing-budget

Map-keyed module for Google Cloud billing budgets with threshold and
notification rules.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `budgets` | `map(object)` | — | Map of budgets keyed by an arbitrary unique ID. |

### `budgets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `billing_account` | `string` | — | Billing account id, shape-validated (`A1B2C3-D4E5F6-G7H8I9` form). |
| `display_name` | `string` | — | Human-readable name, at most 60 characters (validated). Need not be unique — the map key disambiguates. |
| `ownership_scope` | `string` | — | One of `ALL_USERS`, `BILLING_ACCOUNT` (validated). Omit for the API default scope. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). `PREVENT` guards long-lived budgets from accidental destroy. |
| `amount` | `object` | — | Required; see the `amount` object table. |
| `budget_filter` | `object` | — | Scope the budget to projects/services/periods; see the `budget_filter` object table. |
| `threshold_rules` | `list(object)` | `[]` | Alert thresholds as `{threshold_percent, spend_basis}` objects; `spend_basis` defaults to `CURRENT_SPEND`. |
| `all_updates_rule` | `object` | — | Where all budget updates are published; see the `all_updates_rule` object table. |

### `amount` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `last_period_amount` | `bool` | — | Set to `true` to budget the last billing period's spend. Mutually exclusive with `specified_amount` (validated). The provider rejects `false`. |
| `specified_amount` | `object` | — | Fixed budget: `{currency_code, units, nanos}`; `currency_code` defaults to `USD`. Mutually exclusive with `last_period_amount` (validated). |

### `budget_filter` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `projects` | `list(string)` | — | Project resource names, `projects/{project_number}` form (not project ids). |
| `resource_ancestors` | `list(string)` | — | Ancestor resource names (`organizations/{id}`, `folders/{id}`, `projects/{number}`). |
| `credit_types_treatment` | `string` | `INCLUDE_ALL_CREDITS` | One of `INCLUDE_ALL_CREDITS`, `EXCLUDE_ALL_CREDITS`, `INCLUDE_SPECIFIED_CREDITS` (validated). `credit_types` is required with `INCLUDE_SPECIFIED_CREDITS` and must be empty otherwise (validated). |
| `credit_types` | `list(string)` | — | Credit types to subtract from cost, e.g. `PROMOTION`, `FREE_TIER`; only with `INCLUDE_SPECIFIED_CREDITS`. |
| `services` | `list(string)` | — | Service filters, e.g. `services/24E5-7123-9D39` (Compute Engine). |
| `subaccounts` | `list(string)` | — | Billing subaccount resource names. |
| `labels` | `map(string)` | — | Label filters; values may be `*` wildcards. |
| `calendar_period` | `string` | — | One of `MONTH`, `QUARTER`, `YEAR` (validated). Mutually exclusive with `custom_period` (validated). |
| `custom_period` | `object` | — | `{start_date {year, month, day}, end_date {year, month, day}}`; `start_date` required, `end_date` optional (open-ended when omitted). Months/days range-validated. |

### `all_updates_rule` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `pubsub_topic` | `string` | — | Pub/Sub topic for budget updates (`projects/{project}/topics/{topic}`). |
| `schema_version` | `string` | `1.0` | Must be `1.0` — the only version the API accepts today (validated). |
| `monitoring_notification_channels` | `list(string)` | — | Monitoring notification channel names; at most 5 (validated). |
| `disable_default_iam_recipients` | `bool` | `false` | Stop notifying default billing-account IAM recipients. |
| `enable_project_level_recipients` | `bool` | — | Also notify project-level owners (requires schema 1.0). |

## Outputs

`budget_names` — map of budget key => full resource name
(`billingAccounts/{billing_account}/budgets/{budget}`). The provider's `id` and
`name` are identical for this resource.

## Example

```hcl
budgets = {
  "prod-monthly" = {
    billing_account = "A1B2C3-D4E5F6-G7H8I9"
    display_name    = "example-prod-monthly"
    amount = {
      specified_amount = {
        currency_code = "USD"
        units         = "1000"
      }
    }
    budget_filter = {
      calendar_period = "MONTH"
      projects        = ["projects/123456789012"]
    }
    threshold_rules = [
      { threshold_percent = 0.5 },
      { threshold_percent = 0.9, spend_basis = "FORECASTED_SPEND" },
    ]
    all_updates_rule = {
      monitoring_notification_channels = ["projects/example-project-1234/notificationChannels/abc123"]
    }
  }
  "npd-last-period" = {
    billing_account = "A1B2C3-D4E5F6-G7H8I9"
    display_name    = "example-npd-last-period"
    amount = {
      last_period_amount = true
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not display names — two budgets may
  share a display name (unlike name-keyed designs); the key disambiguates them.
- Threshold rules alone do not notify anyone: pair thresholds with
  `all_updates_rule.monitoring_notification_channels` or `pubsub_topic`.
- `budget_filter.projects` takes project resource names with numbers
  (`projects/123456789012`), not project ids. `services` takes resource-name
  form too (e.g. `services/24E5-7123-9D39`).
- `budget_filter` with neither `calendar_period` nor `custom_period` is accepted
  and defers to the API's default period behavior; the module only rejects
  setting both (the API rejects that).
- Enable the Billing API (`billingbudgets.googleapis.com`) in the project that
  owns the Terraform run — pair with `gcp/project-services`. When running with
  user ADCs instead of a service account, the provider needs `billing_project`
  and `user_project_override = true`, or the API returns 403.

## Import

`google_billing_budget` ← `billingAccounts/{billing_account}/budgets/{budget}`
(also `{billing_account}/{budget}`, or the bare `{budget}`).
