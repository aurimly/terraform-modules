# snowflake/resource-monitor

Map-keyed module for Snowflake resource monitors. Each entry creates one
`snowflake_resource_monitor` in the account configured on the provider.

A resource monitor does nothing on its own: it has to be attached to one or
more warehouses (`resource_monitor` attribute on `snowflake_warehouse`) or to
the account to track credit usage. Attaching to the account is not yet
provider-supported — use a `snowflake_execute` step at the consumer side.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `resource_monitors` | `map(object)` | `{}` | Map of resource monitors keyed by an arbitrary unique ID. |

Plan-time validation: `name` contains none of the characters Snowflake
excludes on resource monitor identifiers (`"`, `|`, `.`), `frequency` is one
of the supported values (case-insensitive), `frequency` and `start_timestamp`
are set together or neither, and names are unique across entries
case-insensitively (Snowflake-enforced account-wide uniqueness).

### `resource_monitors` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Monitor identifier; unique across the account. Cannot contain `"` \| or `.`. Changing it forces replacement. |
| `credit_quota` | `number` | `null` | Number of credits allocated per frequency interval; at 100% of quota the configured triggers fire. |
| `frequency` | `string` | `null` | Interval the quota resets on: `MONTHLY`, `DAILY`, `WEEKLY`, `YEARLY` or `NEVER` (case-insensitive, passed through as configured). Removing it from config does **not** unset it on the Snowflake side. |
| `start_timestamp` | `string` | `null` | `IMMEDIATELY` or a timestamp (`YYYY-MM-DD 00:00`). Required together with `frequency`. Removing it keeps the old value on the Snowflake side. |
| `end_timestamp` | `string` | `null` | Timestamp after which the monitor suspends assigned warehouses. Updates in place; removing it unsets the value. |
| `notify_triggers` | `list(number)` | `null` | Percentages of `credit_quota` (each ≥ 1) that notify `notify_users`. Values over 100 are supported (above-quota notifications). |
| `suspend_trigger` | `number` | `null` | Percentage (≥ 1) at which assigned warehouses suspend, letting running queries finish. Values over 100 are supported. |
| `suspend_immediate_trigger` | `number` | `null` | Percentage (≥ 1) at which assigned warehouses suspend and running queries are cancelled. Values over 100 are supported. |
| `notify_users` | `list(string)` | `null` | Snowflake users (fully qualified names) notified by notify triggers. Users only receive the emails if they enabled notifications for themselves in the Snowflake UI. |

## Outputs

| Name | Description |
|---|---|
| `resource_monitor_fully_qualified_names` | Map of key => fully qualified name. Use for warehouse attachment (the `resource_monitor` attribute of the `snowflake_warehouse` resource) or when elsewhere referencing the monitor. |
| `resource_monitor_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
resource_monitors = {
  "warehouse-limits" = {
    name                      = "RM_WAREHOUSE_LIMITS"
    credit_quota              = 100
    frequency                 = "WEEKLY"
    start_timestamp           = "IMMEDIATELY"
    notify_triggers           = [50, 90]
    suspend_trigger           = 100
    suspend_immediate_trigger = 120
    notify_users              = ["ONCALL_SVC"]
  }
}
```

## Notes

- A monitor without `credit_quota` and at least one trigger is created but
  performs no work; callers can attach additional triggers afterwards.
- Triggers cannot be fully removed once set: Snowflake requires at least one
  trigger on a monitor, and the provider recreates the monitor to unset them
  all.
- The role running Terraform needs CREATE RESOURCE MONITOR on the account to
  create these; attaching to a warehouse additionally needs MODIFY on the
  warehouse.
- Changing `name` forces replacement; the other attributes update in place.
- Trigger percentages are enforced at plan time by the provider with a lower
  bound of 1 (0 is rejected); values over 100 are supported and fire above
  quota.

## Import

`terraform import 'snowflake_resource_monitor.monitor["<key>"]' '"<name>"'`

The resource monitor name must be wrapped in literal double quotes per the
provider ("`\"<resource_monitor_name>\"`").
