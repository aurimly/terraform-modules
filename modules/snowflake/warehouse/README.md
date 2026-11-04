# snowflake/warehouse

Map-keyed module for Snowflake warehouses. Each entry creates one
`snowflake_warehouse` in the account configured on the provider.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `warehouses` | `map(object)` | `{}` | Map of warehouses keyed by an arbitrary unique ID. |

Plan-time validation: `name` contains none of the characters the provider
excludes on warehouse identifiers (`"`, `|`, `.`), `warehouse_type`,
`scaling_policy`, `warehouse_size`, `generation` and `resource_constraint`
match the provider's accepted values (case-insensitive), the
type↔generation/resource_constraint pairing holds, cluster counts are
coherent (`min_cluster_count <= max_cluster_count`, both >= 1),
`auto_suspend` >= 0, the query-acceleration scale factor is 0–100, and names
are unique across entries case-insensitively.

### `warehouses` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Warehouse identifier; unique across the account. |
| `warehouse_type` | `string` | `null` | `STANDARD` (provider default) or `SNOWPARK-OPTIMIZED`. Type changes need a suspended warehouse — the provider auto-handles the suspension/resumption. |
| `warehouse_size` | `string` | `null` | Size: canonical `XSMALL`–`X6LARGE` names or their hyphenated/nominal aliases (`X-SMALL`, `2X-LARGE`, ...), case-insensitive. **Removing it from config results in resource recreation.** Snowpark-optimized warehouses default to MEDIUM. |
| `min_cluster_count` | `number` | `null` | Minimum clusters (Auto-scale vs Maximized mode). Requires Enterprise Edition or higher with values > 1. |
| `max_cluster_count` | `number` | `null` | Maximum clusters; the upper bound varies by warehouse size (see Snowflake's multi-cluster warehouses docs). |
| `scaling_policy` | `string` | `null` | `STANDARD` (minimize queuing) or `ECONOMY` (conserve credits), case-insensitive. |
| `auto_suspend` | `number` | `null` | Idle seconds before suspension (0 = never suspend — avoid); the suspension process polls every ~30s, so sub-30s values are unreliable. |
| `auto_resume` | `bool` | `null` | Resume on submitted statements (Snowflake default: true). Not set ⇒ Snowflake default. |
| `initially_suspended` | `bool` | `null` | Create suspended. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW WAREHOUSES`. |
| `enable_query_acceleration` | `bool` | `null` | Query acceleration service (needs Enterprise Edition). Not set ⇒ Snowflake default. |
| `query_acceleration_max_scale_factor` | `number` | `null` | Compute-leasing multiplier for query acceleration (0–100; 0 removes the cap). |
| `resource_constraint` | `string` | `null` | `MEMORY_1X`/`MEMORY_16X`/`MEMORY_64X` (+ `_x86` variants) — Snowpark-optimized only. See Snowflake's required minimum warehouse sizes per constraint (e.g. MEMORY_16X needs MEDIUM+). |
| `generation` | `string` | `null` | `"1"` or `"2"` — standard-warehouse generations only. X6LARGE isn't usable with the Gen2 constraint, and Gen2 warehouses are not available in all regions (see Snowflake's Gen2 region availability docs). |
| `resource_monitor` | `string` | `null` | Fully qualified resource-monitor name (from `snowflake/resource-monitor` outputs) explicitly assigned to this warehouse. |
| `max_concurrency_level` | `number` | `null` | Concurrency level for statements on the warehouse. |
| `statement_timeout_in_seconds` | `number` | `null` | Cancel running statements after this many seconds. |
| `statement_queued_timeout_in_seconds` | `number` | `null` | Cancel queued statements after this many seconds. |

## Outputs

| Name | Description |
|---|---|
| `warehouse_fully_qualified_names` | Map of key => fully qualified name. Use in `snowflake/user` `default_warehouse`, grants (object references must be quoted fully qualified names) and consumer-side references. |
| `warehouse_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
warehouses = {
  "analytics" = {
    name              = "WH_ANALYTICS"
    warehouse_size    = "MEDIUM"
    min_cluster_count = 1
    max_cluster_count = 2
    scaling_policy    = "ECONOMY"
    auto_suspend        = 300
    initially_suspended = true
    resource_monitor    = "\"RM_WAREHOUSE_LIMITS\""
  }
}
```

## Notes

- Assigning `resource_monitor` requires the role running Terraform to be
  ACCOUNTADMIN — either manage the warehouse with ACCOUNTADMIN, or attach the
  monitor with a consumer-side `snowflake_execute` step instead, and omit
  `resource_monitor` here.
- Size constraints interplay (Snowflake-enforced at apply): X5LARGE/X6LARGE
  need the MEMORY_16X constraint on Snowpark-optimized warehouses and are not
  usable with the Gen2 standard constraint.
- The role running Terraform needs CREATE WAREHOUSE on the account.

## Import

`terraform import 'snowflake_warehouse.warehouse["<key>"]' '"<name>"'`

The warehouse name must be wrapped in literal double quotes per the provider.
