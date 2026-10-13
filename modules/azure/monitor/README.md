# azure/monitor

Map-keyed module for Azure Monitor alerting and observability: action groups,
metric alerts, activity log alerts, v2 scheduled query rules and diagnostic
settings. Each top-level entry creates one resource in the named resource
group; alerts reference the action groups by ARM ID — either ones the module
created (see `action_group_ids`) or any pre-existing group.

Scheduled query rules ship v2 only (`azurerm_monitor_scheduled_query_rules_alert_v2`);
the legacy v1 resource is deprecated upstream. Autoscale (`azurerm_monitor_autoscale_setting`)
is intentionally out of scope — it is scaling, not observability.

## Destroy semantics (read before using)

- Removing an alert or query-rule key destroys only that alert/rule.
- Removing a diagnostic-setting key detaches the setting from the target
  resource only — the target and every destination are untouched.
- Removing an action-group key that alerts still reference is a consumer
  plan error — rewire the alerts' action lists first.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `action_groups` | `map(object)` | — | Action groups keyed by an arbitrary unique ID. |
| `metric_alerts` | `map(object)` | — | Metric alerts keyed by an arbitrary unique ID. |
| `activity_log_alerts` | `map(object)` | — | Activity log alerts keyed by an arbitrary unique ID. |
| `scheduled_query_rules` | `map(object)` | — | v2 scheduled query rules keyed by an arbitrary unique ID. |
| `diagnostic_settings` | `map(object)` | — | Diagnostic settings keyed by an arbitrary unique ID. |

Plan-time validation: `short_name` ≤ 12 characters; receiver names unique
case-insensitively across all receiver types within a group; ITSM
`ticket_configuration` valid JSON with the `PayloadRevision`/`WorkItemType`
keys; metric alerts with exactly one criteria flavor, severity 0–4, documented
window/frequency ISO-8601 sets with window > frequency, static/dynamic
operator and dimension-operator enums, multi/RG/subscription scopes requiring
`target_resource_type` + `target_resource_location`; activity-log alerts with
a documented `location` and category, recommendation fields only with
category Recommendation; query rules with exactly one scope, severity 0–4,
ISO-8601 window/frequency/mute durations with window and mute ≥ frequency,
`auto_mitigation_enabled` never with muting, failing periods 1–6 with
min ≤ count, `metric_measure_column` iff aggregation ≠ Count; diagnostic
settings with at least one destination ID and exactly one of
category/category_group per `logs` entry; map keys on every level without
`.`; tags respecting the 50/512/256 limits; `identity.identity_ids`
required when the identity type includes `UserAssigned`.

### `action_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Action-group name. |
| `resource_group_name` | `string` | — | Resource group the group lives in. |
| `short_name` | `string` | — | Short name shown to receivers, ≤ 12 characters (validated). |
| `location` | `string` | `null` | `global` (the Azure default when omitted) or a region. Changing it replaces the group. |
| `enabled` | `bool` | `true` | Set `false` to keep the group configured but idle. |
| `arm_role_receivers` | `map(object)` | `{}` | Entra role receivers — see the receiver tables. |
| `email_receivers` | `map(object)` | `{}` | Email receivers — see the receiver tables. |
| `itsm_receivers` | `map(object)` | `{}` | ITSM (ServiceNow) receivers — see the receiver tables and Notes. |
| `webhook_receivers` | `map(object)` | `{}` | Webhook receivers — see the receiver tables and Notes. |
| `automation_runbook_receivers` | `map(object)` | `{}` | Automation runbook receivers — see the receiver tables. |
| `azure_app_push_receivers` | `map(object)` | `{}` | Azure app (push notification) receivers — see the receiver tables. |
| `azure_function_receivers` | `map(object)` | `{}` | Azure function receivers — see the receiver tables. |
| `event_hub_receivers` | `map(object)` | `{}` | Event Hub receivers — see the receiver tables. |
| `logic_app_receivers` | `map(object)` | `{}` | Logic App receivers — see the receiver tables. |
| `sms_receivers` | `map(object)` | `{}` | SMS receivers — see the receiver tables. |
| `voice_receivers` | `map(object)` | `{}` | Voice (call) receivers — see the receiver tables. |
| `tags` | `map(string)` | `{}` | Tags on the action group. Authoritative — a change replaces the whole set. |

Receiver names must be unique case-insensitively across all receiver types
in a group (validated) — the Azure API rejects duplicates across types at
apply time, not just within one type.

### Receiver objects

Every receiver map is keyed by an arbitrary identifier and every receiver
carries a required `name` that must be unique case-insensitively across all
receiver types in the group (validated). The remaining fields per receiver
type:

| Receiver type entry | Attribute | Description |
|---|---|---|
| `arm_role_receivers` | `role_id` | Entra role (built-in or custom) ARM ID: `"/providers/Microsoft.Authorization/roleDefinitions/<guid>"` or subscription/RG-scoped. |
| `arm_role_receivers` | `use_common_alert_schema` | `bool`, optional — send the shared v3 alert schema instead of the raw per-monitor payload. |
| `email_receivers` | `email_address` | Recipient address. |
| `email_receivers` | `use_common_alert_schema` | `bool`, optional, as above. |
| `itsm_receivers` | `workspace_id` | Composite `"<subscription-id>|<workspace-id>"` as returned by the ITSM workspace registration in ServiceNow; `{}` `ticket_configuration` fails to save — Notes has the shape. |
| `itsm_receivers` | `connection_id` | ARM ID of the registered ITSM connection. |
| `itsm_receivers` | `ticket_configuration` | JSON string with the `PayloadRevision` and `WorkItemType` keys (validated). |
| `itsm_receivers` | `region` | ITSM connection region, e.g. `westeurope`. |
| `webhook_receivers` | `service_uri` | Webhook URL. |
| `webhook_receivers` | `use_common_alert_schema` | `bool`, optional, as above. |
| `webhook_receivers` | `aad_auth` | Optional object — `{ object_id, identifier_uri, tenant_id }`; `object_id` required. |
| `automation_runbook_receivers` | `automation_account_id` | ARM ID of the Automation account. |
| `automation_runbook_receivers` | `runbook_name` | Runbook to trigger. |
| `automation_runbook_receivers` | `webhook_resource_id` | ARM ID of the runbook's webhook. |
| `automation_runbook_receivers` | `is_global_runbook` | `bool` — `true` for the standard global ones. |
| `automation_runbook_receivers` | `service_uri` | Webhook URL of the runbook. |
| `automation_runbook_receivers` | `use_common_alert_schema` | `bool`, optional, as above. |
| `azure_app_push_receivers` | `email_address` | Azure app user to push to. |
| `azure_function_receivers` | `function_app_resource_id` | ARM ID of the function app. |
| `azure_function_receivers` | `function_name` | Function to trigger. |
| `azure_function_receivers` | `http_trigger_url` | HTTP-trigger URL with the function key. |
| `azure_function_receivers` | `use_common_alert_schema` | `bool`, optional, as above. |
| `event_hub_receivers` | `event_hub_name` | Event Hub name. |
| `event_hub_receivers` | `event_hub_namespace` | Event Hubs namespace name. |
| `event_hub_receivers` | `subscription_id` | Optional — defaults to the action group's subscription. |
| `event_hub_receivers` | `tenant_id` | Optional — hub's tenant when it differs from the group's. |
| `event_hub_receivers` | `use_common_alert_schema` | `bool`, optional, as above. |
| `logic_app_receivers` | `resource_id` | ARM ID of the Logic App. |
| `logic_app_receivers` | `callback_url` | Trigger callback URL from the Logic App definition. |
| `logic_app_receivers` | `use_common_alert_schema` | `bool`, optional, as above. |
| `sms_receivers` / `voice_receivers` | `country_code` | Phone country calling code without the leading `+`, e.g. `1`. |
| `sms_receivers` / `voice_receivers` | `phone_number` | Subscriber number. |

### `metric_alerts` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Alert-rule name. |
| `resource_group_name` | `string` | — | Resource group the rule lives in. |
| `scopes` | `list(string)` | — | At least one ARM resource ID to monitor. A subscription, a resource group or multiple scopes require `target_resource_type` + `target_resource_location` (validated). |
| `description` | `string` | `null` | Human-facing description. |
| `severity` | `number` | `null` | 0 (critical) – 4 (verbose, validated). |
| `window_size` | `string` | `null` | ISO-8601 evaluation window: PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H or P1D (validated); window > frequency (validated). |
| `frequency` | `string` | `null` | ISO-8601 check frequency: PT1M, PT5M, PT15M, PT30M or PT1H (validated). |
| `enabled` | `bool` | `true` | Set `false` to keep the rule disabled. |
| `auto_mitigate` | `bool` | `true` | Auto-resolve the alert when the condition clears. |
| `criteria` | `map(object)` | `{}` | Static criteria entries — see the `criteria` object table. Exactly one of criteria/dynamic_criteria/web_test_criteria per alert (validated). |
| `dynamic_criteria` | `object` | `null` | Dynamic threshold rule — see the `dynamic_criteria` object table. |
| `web_test_criteria` | `object` | `null` | Application Insights availability: `{ web_test_id, component_id, failed_location_count }`. |
| `target_resource_type` | `string` | `null` | e.g. `Microsoft.Compute/virtualMachines` — required for subscription/RG/multi-scope (validated). |
| `target_resource_location` | `string` | `null` | Region of the target resource — required alongside the type. |
| `actions` | `map(object)` | `{}` | Action blocks — `{ action_group_id, webhook_properties }`. |
| `tags` | `map(string)` | `{}` | Tags on the rule. Authoritative — a change replaces the whole set. |

### `criteria` object (metric alerts)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `metric_namespace` | `string` | — | e.g. `Microsoft.Compute/virtualMachines` — `skip_metric_validation` covers unreleased namespaces. |
| `metric_name` | `string` | — | Metric to evaluate. |
| `aggregation` | `string` | — | `Average`, `Minimum`, `Maximum`, `Total` or `Count` (validated). |
| `operator` | `string` | — | `Equals`, `GreaterThan`, `GreaterThanOrEqual`, `LessThan` or `LessThanOrEqual` (validated). |
| `threshold` | `number` | — | Metric-value threshold. |
| `skip_metric_validation` | `bool` | `null` | Skip API-side validation of the metric name (custom/unreleased metrics). |
| `dimensions` | `map(object)` | `{}` | Dimension filters keyed arbitrarily — `{ name, operator, values }` with operator `Include`, `Exclude` or `StartsWith` (validated). |

### `dynamic_criteria` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `metric_namespace` | `string` | — | As static criteria. |
| `metric_name` | `string` | — | As static criteria. |
| `aggregation` | `string` | — | As static criteria (validated). |
| `operator` | `string` | — | `GreaterThan`, `LessThan` or `GreaterOrLessThan` (validated — a distinct set from static criteria). |
| `alert_sensitivity` | `string` | — | Threshold strictness: `Low`, `Medium` or `High` (validated). |
| `evaluation_total_count` | `number` | `null` | Periods evaluated, 1–10. |
| `evaluation_failure_count` | `number` | `null` | Periods failing to trigger, 1–10. |
| `ignore_data_before` | `string` | `null` | ISO timestamp the learned baseline may use data from. |
| `skip_metric_validation` | `bool` | `null` | As static criteria. |
| `dimensions` | `map(object)` | `{}` | As static criteria. |

### `activity_log_alerts` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Alert-rule name. |
| `resource_group_name` | `string` | — | Resource group the rule lives in. |
| `scopes` | `list(string)` | — | ARM resource IDs to cover — the subscription `/subscriptions/<id>` form watches the whole subscription. |
| `location` | `string` | `global` | Module default — the provider requires the attribute; documented values are `global`, `westeurope`, `northeurope`, `eastus2euap` (validated). |
| `description` | `string` | `null` | Human-facing description. |
| `enabled` | `bool` | `true` | Set `false` to keep the rule disabled. |
| `criteria` | `object` | — | Rule criteria — see the table above (required). |
| `actions` | `map(object)` | `{}` | Action blocks — `{ action_group_id, webhook_properties }`. |
| `tags` | `map(string)` | `{}` | Tags on the rule. Authoritative — a change replaces the whole set. |

### `criteria` object (activity log alerts)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `category` | `string` | — | `Administrative`, `ServiceHealth`, `ResourceHealth`, `Autoscale`, `Security`, `Recommendation` or `Policy` (validated). |
| `caller` | `string` | `null` | Identity that performed the event, including anonymous `null` callers via `"@"`. |
| `operation_name` | `string` | `null` | `<rp>/<type>/<op>` filter — e.g. an admin-event rule. |
| `resource_providers` | `list(string)` | `null` | RP filter list. |
| `resource_types` | `list(string)` | `null` | `<rp>/<type>` filter list. |
| `resource_groups` | `list(string)` | `null` | RG filter list. |
| `resource_ids` | `list(string)` | `null` | Resource filter list. |
| `statuses` | `list(string)` | `null` | Event status list — e.g. Succeeded, Failed. |
| `sub_statuses` | `list(string)` | `null` | Event sub-status list. |
| `recommendation_type` | `string` | `null` | Advisor recommendation name — Recommendation category only (validated). |
| `recommendation_category` | `string` | `null` | `Cost`, `Reliability`, `OperationalExcellence`, `HighAvailability`, `Performance` or `Security` (validated, Recommendation only). |
| `recommendation_impact` | `string` | `null` | `High`, `Medium` or `Low` (validated, Recommendation only). |
| `resource_health` | `object` | `null` | ResourceHealth filters — `{ current, previous, reason }` lists. |
| `service_health` | `object` | `null` | ServiceHealth filters — `{ events, locations, services }` lists. |

The provider's singular filter attributes (`resource_provider`, `status`,
...) are mutually exclusive with the plural ones; the module always emits the
plural attribute with each list — one-element lists give the singular
behaviour, so the exclusivity rule can never trip.

### `scheduled_query_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name. |
| `resource_group_name` | `string` | — | Resource group the rule lives in. |
| `location` | `string` | — | Required — changing it forces replacement (see Notes). |
| `scopes` | `list(string)` | — | Exactly one ARM resource ID (validated) — a resource group/sub subscription scope pairs with `target_resource_types`. |
| `description` | `string` | `null` | Human-facing description. |
| `display_name` | `string` | `null` | Displayed rule name. |
| `enabled` | `bool` | `true` | Set `false` to keep the rule disabled. |
| `severity` | `number` | — | 0 (critical) – 4 (verbose, validated). |
| `evaluation_frequency` | `string` | — | ISO-8601: PT1M, PT5M, PT10M, PT15M, PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, PT6H or P1D (validated). |
| `window_duration` | `string` | — | ISO-8601 window (validated format) ≥ frequency (validated); the 48h lookback cap is the API's — see Notes. |
| `mute_actions_after_alert_duration` | `string` | `null` | ISO-8601 quiet period after firing (validated ≥ frequency). Mutually exclusive with `auto_mitigation_enabled` (validated). |
| `query_time_range_override` | `string` | `null` | ISO-8601 — the query's fetch window defaults to the rule's window. |
| `auto_mitigation_enabled` | `bool` | `null` | Flag-triggered alert resolution (instead of the mute period). |
| `skip_query_validation` | `bool` | `null` | Accept the query without a validation round-trip. |
| `workspace_alerts_storage_enabled` | `bool` | `null` | Keep alert payloads in the workspace storage. |
| `target_resource_types` | `list(string)` | `null` | RP types the rule targets when scoped to a resource group. |
| `identity` | `object` | `null` | Optional identity block — `{ type, identity_ids }`; `identity_ids` required when the type includes `UserAssigned` (validated). |
| `criteria` | `map(object)` | `{}` | Query conditions — see the `criteria` object table. |
| `action` | `object` | `null` | The single action block — `{ action_groups, custom_properties, email_subject }`; `action_groups` is the list of action-group ARM IDs (Notes covers the wiring). |
| `tags` | `map(string)` | `{}` | Tags on the rule. Authoritative — a change replaces the whole set. |

### `criteria` object (scheduled query rules)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `query` | `string` | — | Log Analytics query (Application Insights or Log Analytics resource). |
| `operator` | `string` | — | `Equal`, `GreaterThan`, `GreaterThanOrEqual`, `LessThan` or `LessThanOrEqual` (validated). |
| `threshold` | `number` | — | Aggregated-value threshold. |
| `time_aggregation_method` | `string` | — | `Count`, `Average`, `Minimum`, `Maximum` or `Total` (validated). |
| `metric_measure_column` | `string` | `null` | Column carrying the measured value; required iff `time_aggregation_method != "Count"`, rejected with Count (validated). |
| `resource_id_column` | `string` | `null` | Column naming the affected resource — the alert context splits on it. |
| `dimension` | `map(object)` | `{}` | Split conditions — keyed arbitrarily, `{ name, operator, values }` with operator `Include` or `Exclude` (validated). |
| `failing_periods` | `object` | `null` | `{ minimum_failing_periods_to_trigger_alert, number_of_evaluation_periods }` — both 1–6, min ≤ count (validated). |

### `diagnostic_settings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Diagnostic-setting name — one per combination on the target; the name `service` is undeletable through the Azure API (avoid it). |
| `target_resource_id` | `string` | — | ARM ID of the resource to bridge (e.g. a Key Vault, VM or Data Factory). |
| `logs` | `list(object)` | `[]` | Enabled platform logs — each entry exactly one of category/category_group (validated). |
| `metric_categories` | `list(string)` | `[]` | Enabled platform metric categories — usually `["AllMetrics"]`. |
| `log_analytics_workspace_id` | `string` | `null` | Workspace ARM ID — pair with the `azure/log-analytics` module's output. |
| `log_analytics_destination_type` | `string` | `null` | `Dedicated` or `AzureDiagnostics` (validated) — workspace-side table layout. |
| `storage_account_id` | `string` | `null` | Storage-account ARM ID destination. |
| `eventhub_authorization_rule_id` | `string` | `null` | Namespace-scoped Event Hub authorization-rule ARM ID (see Notes). |
| `eventhub_name` | `string` | `null` | Only with the authorization-rule destination (validated). |
| `partner_solution_id` | `string` | `null` | Partner solution (third-party) ARM ID destination. |

## Outputs

| Name | Description |
|---|---|
| `action_group_ids` | Map of action-group key => full ARM resource ID — the one the other variables consume. |
| `metric_alert_ids` | Map of metric-alert key => full ARM resource ID. |
| `activity_log_alert_ids` | Map of activity-log-alert key => full ARM resource ID. |
| `scheduled_query_rule_ids` | Map of scheduled-query-rule key => full ARM resource ID. |
| `diagnostic_setting_ids` | Map of diagnostic-setting key => full ARM resource ID. |

The v2 query-rule identity block exports the managed identity's
`principal_id`; consumers assigning it roles reference
`azurerm_monitor_scheduled_query_rules_alert_v2.scheduled_query_rule["<key>"].identity[0].principal_id`
(no dedicated output in v1).

## Example

```hcl
action_groups = {
  "ops-eu" = {
    name                = "aa-ops-eu"
    resource_group_name = "rg-monitor-prod"
    short_name          = "ops-eu"

    email_receivers = {
      "sre" = {
        name                    = "sre"
        email_address           = "sre@example.invalid"
        use_common_alert_schema = true
      }
    }

    webhook_receivers = {
      "pagerduty" = {
        name        = "pagerduty"
        service_uri = "https://events.pagerduty.example.invalid/webhook"

        aad_auth = {
          object_id      = "00000000-0000-0000-0000-000000000000"
          identifier_uri = "https://example.invalid"
          tenant_id      = "11111111-2222-3333-4444-555555555555"
        }
      }
    }
  }
}

metric_alerts = {
  "vm-cpu" = {
    name                = "ma-vm-cpu"
    resource_group_name = "rg-monitor-prod"
    scopes              = ["/subscriptions/<id>/resourceGroups/rg-app/providers/Microsoft.Compute/virtualMachines/vm-01"]
    severity            = 1
    window_size         = "PT15M"
    frequency           = "PT5M"

    criteria = {
      "cpu" = {
        metric_namespace = "Microsoft.Compute/virtualMachines"
        metric_name      = "Percentage CPU"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 90

        dimensions = {
          "vm" = {
            name     = "VMName"
            operator = "Include"
            values   = ["vm-01"]
          }
        }
      }
    }

    actions = {
      "ops-eu" = {
        action_group_id = "/subscriptions/<id>/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/actionGroups/aa-ops-eu"
      }
    }
  }
}

activity_log_alerts = {
  "admin-write" = {
    name                = "ala-admin-write"
    resource_group_name = "rg-monitor-prod"
    scopes              = ["/subscriptions/<id>"]

    criteria = {
      category          = "Administrative"
      operation_name    = "Microsoft.Network/networkSecurityGroups/write"
      statuses          = ["Succeeded"]
    }

    actions = {
      "ops-eu" = {
        action_group_id = "/subscriptions/<id>/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/actionGroups/aa-ops-eu"
      }
    }
  }
}

scheduled_query_rules = {
  "storage-4xx" = {
    name                 = "sqr-storage-4xx"
    resource_group_name  = "rg-monitor-prod"
    location             = "westeurope"
    scopes               = ["/subscriptions/<id>/resourceGroups/rg-app/providers/Microsoft.Storage/storageAccounts/stapplogseu01"]
    severity             = 2
    evaluation_frequency = "PT5M"
    window_duration      = "PT1H"

    identity = {
      type = "SystemAssigned"
    }

    criteria = {
      "requests" = {
        query                   = "StorageBlobLogs | where StatusText startswith '4'"
        operator                = "GreaterThan"
        threshold               = 100
        time_aggregation_method = "Count"

        failing_periods = {
          minimum_failing_periods_to_trigger_alert = 1
          number_of_evaluation_periods             = 1
        }
      }
    }

    action = {
      action_groups = ["/subscriptions/<id>/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/actionGroups/aa-ops-eu"]
      email_subject = "blob 4xx spike"
    }
  }
}

diagnostic_settings = {
  "key-vault" = {
    name                       = "ds-key-vault"
    target_resource_id         = "/subscriptions/<id>/resourceGroups/rg-app/providers/Microsoft.KeyVault/vaults/kv-app"
    log_analytics_workspace_id = "/subscriptions/<id>/resourceGroups/rg-monitor-prod/providers/Microsoft.OperationalInsights/workspaces/log-ops-eu-01"

    logs = [
      {
        category = "AuditEvent"
      },
      {
        category_group = "allLogs"
      }
    ]

    metric_categories = ["AllMetrics"]
  }
}
```

## Notes

- **Action wiring per alert type**: metric and activity log alerts take
  repeatable `action` blocks carrying one `action_group_id` each (that is
  the `actions` map in this module); the v2 query rule takes a single
  `action` block whose `action_groups` field is the list of action-group
  ARM IDs. The module's `action_group_ids` output feeds both shapes.
- **ITSM ticket_configuration**: valid JSON like
  `{"PayloadRevision":0,"WorkItemType":"incident"}` — an empty object or
  missing keys fails when the group is saved (validated at plan time).
- **Webhook and state posture**: `service_uri` and ITSM connection
  identifiers land in state in plaintext; `aad_auth` keeps well-behaved
  Entra-signed calls. Flag the state protection accordingly.
- **v2 identity**: a `SystemAssigned`/`UserAssigned` identity is required
  whenever the query reads its source with the rule's own credentials.
  Consumers wire the role assignment to the identity's `principal_id`
  (see Outputs).
- **v2 location forces replacement**: moving the rule's region recreates
  it (alert definition is preserved; the evaluation history is not).
- **v2 scopes**: the API accepts exactly one scope; to cover a whole
  resource group, scope the RG and pass `target_resource_types`. The
  lookback (window × failing periods) is capped at 48h by the API and
  `number_of_evaluation_periods = 1` only works when the query projects a
  timestamp column — neither is plan-detectable.
- **Activity-log location**: the provider requires the attribute; the
  module defaults it to `global` so most deployments need nothing.
- **Diagnostic destinations**: `eventhub_authorization_rule_id` is the
  namespace-scoped rule's ARM ID (not the hub's); the `service` setting
  name is reserved by Azure's legacy ACL support and cannot be deleted.
- **Import**: see the section below — diagnostic settings import through
  a pipe-composite ID, everything else through plain ARM IDs.
- Tags are authoritative — a change replaces the whole tag set per
  resource.

## Import

Action groups import by ARM ID; the rules import by their own:

```
tofu import 'azurerm_monitor_action_group.action_group["ops-eu"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Insights/actionGroups/<name>"
tofu import 'azurerm_monitor_metric_alert.metric_alert["vm-cpu"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Insights/metricAlerts/<name>"
tofu import 'azurerm_monitor_activity_log_alert.activity_log_alert["admin-write"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Insights/activityLogAlerts/<name>"
tofu import 'azurerm_monitor_scheduled_query_rules_alert_v2.scheduled_query_rule["storage-4xx"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Insights/scheduledQueryRules/<name>"
tofu import 'azurerm_monitor_diagnostic_setting.diagnostic_setting["key-vault"]' "<target_resource_id>|<name>"
```
