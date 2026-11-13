# snowflake/view

Map-keyed module for Snowflake views inside existing schemas. Each entry
creates one `snowflake_view` from its SELECT statement; the `database` and
`schema` must already exist (e.g. from `snowflake/database` and
`snowflake/schema` or outside Terraform).

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `views` | `map(object)` | `{}` | Map of views keyed by an arbitrary unique ID. |

Plan-time validation: `database`, `schema` and `name` contain none of the
characters the provider excludes on identifiers (`"`, `|`, `.`), `statement`
is non-blank, (database, schema, name) triples are unique across entries
case-insensitively, and column aliases are unique within a view
(case-insensitive).

### `views` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `database` | `string` | — | Existing database identifier containing the view. |
| `schema` | `string` | — | Existing schema identifier containing the view. |
| `name` | `string` | — | View identifier; unique within the schema. |
| `statement` | `string` | — | The view's SELECT statement, sent to Snowflake verbatim. The provider normalizes blank characters to spaces, so align your config's whitespace with the statement to avoid permadiffs. |
| `is_secure` | `bool` | `null` | Secure view: hides the definition from non-owners. `SHOW VIEWS` does not show secure views — manage them with the owning role. |
| `is_recursive` | `bool` | `null` | Recursive view (references itself). Changing it later means recreation. |
| `change_tracking` | `bool` | `null` | Enable change tracking for stream consumption on the view. |
| `copy_grants` | `bool` | `false` | Preserve grants when the provider recreates the view (changing `statement`, `is_recursive`, `is_temporary` or `copy_grants` itself means recreation). |
| `comment` | `string` | `null` | Free-form description shown in `SHOW VIEWS`. |
| `columns` | `list(object)` | `null` | Column aliases for the SELECT output, in order: `column_name` (required) and `comment` (optional). List, not map — aliases map positionally to the statement's output. |

## Outputs

| Name | Description |
|---|---|
| `view_fully_qualified_names` | Map of key => fully qualified name (quoted `"database"."schema"."view"` form). Feed into `snowflake/grant-privileges` and consumer-side references. |
| `view_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
views = {
  "daily_orders" = {
    database  = "DB_ANALYTICS"
    schema    = "REPORT"
    name      = "DAILY_ORDERS"
    statement = "SELECT ORDER_DATE, SUM(AMOUNT) AS TOTAL FROM ${module.orders.table_fully_qualified_names["orders"]} GROUP BY ORDER_DATE"
    is_secure = true
    columns = [
      { column_name = "ORDER_DATE", comment = "Order date" },
      { column_name = "TOTAL", comment = "Sum of order amounts" },
    ]
  }
}
```

## Notes

- The role running Terraform needs CREATE VIEW on the target schema and
  SELECT on every table referenced in `statement`.
- The statement is an opaque string — Terraform cannot infer references to
  tables or views inside it. Interpolate table/view module outputs into the
  statement where possible (as in the example), or add explicit
  `depends_on`; the view resource has no provider-side dependency attribute.
- `is_temporary` is intentionally not mapped: a temporary view is dropped
  after the Terraform operation finishes — an anti-pattern under IaC.
- Row access policies, aggregation policies, masking/projection policies and
  data metric functions are intentionally not mapped (the repo has no policy
  modules yet), and neither is the `timeouts` block; add them to the module if
  the repo needs them.
- The statement is not sensitive to the provider and lands in Terraform state
  and Snowflake metadata; avoid embedding regulated data literals in it. The
  provider replaces blank characters in the statement with a space — align
  your config's whitespace to avoid permadiffs.
- Grants on a recreated view are lost unless `copy_grants = true`; recreation
  (not in-place update) is triggered by changing `statement`, `is_recursive`
  or `is_temporary`.

## Import

`terraform import 'snowflake_view.view["<key>"]' '"<database_name>"."<schema_name>"."<view_name>"'`

All parts must be wrapped in literal double quotes per the provider.
