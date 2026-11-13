# snowflake/table

Map-keyed module for Snowflake tables inside existing schemas. Each entry
creates one `snowflake_table`; the `database` and `schema` must already exist
(e.g. from `snowflake/database` and `snowflake/schema` or outside Terraform).

**Provider preview feature** — `snowflake_table` requires
`preview_features_enabled = ["snowflake_table_resource"]` in the consumer's
`snowflake` provider block, or the resource is unknown to Terraform. Preview
resources can change without a provider major bump.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `tables` | `map(object)` | `{}` | Map of tables keyed by an arbitrary unique ID. |

Plan-time validation: `database`, `schema` and `name` contain none of the
characters the provider excludes on identifiers (`"`, `|`, `.`), each table has
at least one column, column names are within the same identifier rules and
unique within a table (case-insensitive), `default` and `identity` never
coexist on a column, a `default` sets exactly one of
`constant`/`expression`/`sequence`, and `data_retention_time_in_days` is 0–90.

`columns` is a **list**, not a map: column order is load-bearing (it becomes
the table's column order), and nothing downstream references columns by key.
This is the one deliberate deviation from the repo's map-keyed convention.

### `tables` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `database` | `string` | — | Existing database identifier containing the table. |
| `schema` | `string` | — | Existing schema identifier containing the table. |
| `name` | `string` | — | Table identifier; unique within the schema. Renames apply in place (`ALTER TABLE ... RENAME TO`); a rename fails if the target name already exists. |
| `columns` | `list(object)` | — | Ordered columns (at least one); see the column object below. |
| `cluster_by` | `list(string)` | `null` | Cluster keys (columns and/or expressions, e.g. `TO_DATE(ts)`). |
| `change_tracking` | `bool` | `null` | Enable change tracking for stream consumption on the table. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW TABLES`. |
| `data_retention_time_in_days` | `number` | `null` | Time Travel retention in days (0–90). Unset ⇒ inherits the parent schema's setting. |

### `columns` entries

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Column identifier, unique within the table. |
| `type` | `string` | — | Snowflake data type: `NUMBER(38,0)`, `VARCHAR(16777216)`, `TIMESTAMP_NTZ(9)`, `VARIANT`, `BOOLEAN`, `DATE`, ... (free string, no enum). |
| `nullable` | `bool` | `null` | NULLs allowed on the column. Unset ⇒ Snowflake default (true). |
| `collate` | `string` | `null` | Collation specification, e.g. `en-ci`. |
| `comment` | `string` | `null` | Free-form column description. |
| `masking_policy` | `string` | `null` | Fully qualified masking policy name. |
| `default` | `object` | `null` | Column default — exactly one of `constant` (literal, e.g. `"0"`), `expression` (e.g. `"CURRENT_TIMESTAMP()"`) or `sequence` (fully qualified sequence name). Mutually exclusive with `identity`. **Provider limitation:** updates to `default` are not applied in place — a change means dropping/recreating the column by hand. |
| `identity` | `object` | `null` | Identity (auto-increment) columns: `start_num` and `step_num` (Snowflake defaults both to 1 when unset). Mutually exclusive with `default`. |

`default` and `identity` are nested objects, not blocks — inline maps:

```hcl
default = { sequence = "DB_EXAMPLE.SCH_EXAMPLE.SEQ_EXAMPLE" }
```

## Outputs

| Name | Description |
|---|---|
| `table_fully_qualified_names` | Map of key => fully qualified name (quoted `"database"."schema"."table"` form). Feed into `snowflake/stream` `table`, `snowflake/pipe` `copy_statement` and consumer-side references. |
| `table_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
tables = {
  "events" = {
    database = "DB_ANALYTICS"
    schema   = "RAW"
    name     = "EVENTS"
    columns = [
      {
        name     = "EVENT_ID"
        type     = "NUMBER(38,0)"
        nullable = false
        default = {
          sequence = "DB_ANALYTICS.RAW.SEQ_EVENT_ID"
        }
      },
      {
        name             = "PAYLOAD"
        type             = "VARIANT"
        comment          = "Raw event body"
        masking_policy   = "DB_ANALYTICS.RAW.POLICY_PII"
      },
      {
        name       = "CREATED_AT"
        type       = "TIMESTAMP_NTZ(9)"
        nullable   = false
        default = {
          expression = "CURRENT_TIMESTAMP()"
        }
      },
    ]
    cluster_by                  = ["CREATED_AT"]
    data_retention_time_in_days = 30
  }
  "lookup_countries" = {
    database = "DB_ANALYTICS"
    schema   = "REFERENCE"
    name     = "COUNTRIES"
    columns = [
      { name = "CODE", type = "VARCHAR(2)", nullable = false },
      { name = "NAME", type = "VARCHAR(100)" },
    ]
    change_tracking = true
  }
}
```

## Notes

- The role running Terraform needs CREATE TABLE on the target schema (or the
  corresponding granted privilege via `snowflake/grant-privileges`).
- Column `type` accepts any Snowflake data type string — validate against
  [Snowflake's data-type summary](https://docs.snowflake.com/en/sql-reference/data-types-summary).
- Stream consumption requires `change_tracking = true` on the source table
  (streams create it implicitly on tables outside Terraform; explicit is
  cleaner here) or an append-only stream on a table with natural change
  tracking.
- Primary keys and constraints: the provider's `primary_key` block is
  deprecated — use the `snowflake_table_constraint` resource consumer-side if
  needed. Tags are not mapped, consistent with the other snowflake modules.
- Renames apply in place (`ALTER TABLE ... RENAME TO`). Column changes apply
  per column (ADD/DROP/MODIFY): dropping a column discards its data, and
  ADD COLUMN accepts only constant defaults (e.g. `"0"`); non-constant forms
  and defaults on existing columns are rejected by Snowflake — see the
  `default` attribute.

## Import

`terraform import 'snowflake_table.table["<key>"]' '<database_name>|<schema_name>|<table_name>'`

Note the pipe-separated (unquoted) form — unlike most snowflake resources,
which take the quoted fully qualified name.
