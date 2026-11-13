# snowflake/stream

Map-keyed module for Snowflake streams on tables inside existing schemas.
Each entry creates one `snowflake_stream_on_table`; the `database` and
`schema` must already exist, and the source `table` is referenced by fully
qualified name (e.g. the `table_fully_qualified_names` output of
`snowflake/table`).

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

The provider splits streams by source: this module covers stream-on-table
only. Streams on views, external tables and directory tables use separate
provider resources and are not mapped here; add sibling modules if the repo
needs them.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `streams` | `map(object)` | `{}` | Map of streams keyed by an arbitrary unique ID. |

Plan-time validation: `database`, `schema` and `name` contain none of the
characters the provider excludes on identifiers (`"`, `|`, `.`), `table` is
non-blank, `at` and `before` never coexist, each `at`/`before` sets exactly
one of its four forms, and (database, schema, name) triples are unique across
entries case-insensitively.

### `streams` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `database` | `string` | — | Existing database identifier containing the stream. |
| `schema` | `string` | — | Existing schema identifier containing the stream. |
| `name` | `string` | — | Stream identifier; unique within the schema. |
| `table` | `string` | — | Fully qualified source-table name (quoted form, e.g. from `snowflake/table`'s `table_fully_qualified_names` output). Changing it means recreation. |
| `append_only` | `bool` | `null` | Append-only stream (shows inserted rows only, no change history). Fixed at creation — changing it means recreation. |
| `show_initial_rows` | `bool` | `null` | Include pre-existing rows in the initial read offset. Fixed at creation — changing it means recreation. |
| `copy_grants` | `bool` | `false` | Preserve grants when the provider recreates the stream (source-table/anchor changes mean recreation). |
| `comment` | `string` | `null` | Free-form description shown in `SHOW STREAMS`. |
| `at` | `object` | `null` | Time Travel anchor at stream creation, exactly one of `offset` (e.g. `"-5 minutes"`), `statement` (query ID), `stream` (stream name) or `timestamp`. Cannot be changed in place. |
| `before` | `object` | `null` | Time Travel anchor immediately before the given point; same forms as `at`, mutually exclusive with it. Cannot be changed in place. |

## Outputs

| Name | Description |
|---|---|
| `stream_fully_qualified_names` | Map of key => fully qualified name (quoted `"database"."schema"."stream"` form). Feed into `snowflake/task` `when` conditions (`SYSTEM$STREAM_HAS_DATA`) and consumer-side references. |
| `stream_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
streams = {
  "raw_events" = {
    database    = "DB_ANALYTICS"
    schema      = "ETL"
    name        = "STREAM_RAW_EVENTS"
    table       = module.events.table_fully_qualified_names["events"]
    append_only = true
  }
  "cdc_orders" = {
    database = "DB_ANALYTICS"
    schema   = "ETL"
    name     = "STREAM_ORDERS"
    table    = module.orders.table_fully_qualified_names["orders"]
  }
}
```

## Notes

- The role running Terraform needs CREATE STREAM on the target schema and
  SELECT on the source table (change tracking must be enabled on the source —
  `snowflake/table`'s `change_tracking` attribute, or Snowflake enables it
  implicitly when the stream is created outside Terraform).
- The source table must be inside the same database as the stream — a stream
  reads its source's change data, which lives with the table.
- `table`, `append_only`, `at`, `before` and `show_initial_rows` cannot be
  changed in place — a change means the provider recreates the stream; with
  `copy_grants = true` grants survive. External changes to `at`/`before`/
  `show_initial_rows` are not detected — taint the resource to re-apply.
- Streams go **stale** when the source table's Time Travel retention is
  shorter than the stream's unconsumed history; the provider detects staleness
  and auto-recreates the stream. Size retention so a backlog of task
  executions cannot outlive it (see `snowflake/schema`'s
  `max_data_extension_time_in_days`).
- `insert_only` is not exposed by the provider on this resource, so it is not
  mapped here.

## Import

`terraform import 'snowflake_stream_on_table.stream["<key>"]' '"<database_name>"."<schema_name>"."<stream_name>"'`

All parts must be wrapped in literal double quotes per the provider. If
importing produces a permadiff on boolean attributes, enable the
`IMPORT_BOOLEAN_DEFAULT` experiment in the consumer's provider block before
reimporting (per the provider migration guide).
