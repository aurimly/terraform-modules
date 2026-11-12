# snowflake/schema

Map-keyed module for Snowflake schemas inside existing databases. Each entry
creates one `snowflake_schema`; the `database` must already exist (e.g. from
`snowflake/database` or outside Terraform).

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

The resource additionally takes Iceberg parameters (`catalog`,
`external_volume`, `storage_serialization_policy`, ...), task parameters
(`suspend_task_after_num_failures`, `user_task_*`, ...) and `timeouts` blocks
that are intentionally not mapped here; add them to the module if the repo
needs them.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `schemas` | `map(object)` | `{}` | Map of schemas keyed by an arbitrary unique ID. |

Plan-time validation: `database` and `name` contain none of the characters the
provider excludes on schema identifiers (`"`, `|`, `.`), `log_level` matches
its provider enum (case-insensitive), `data_retention_time_in_days` is 0–90
(transient schemas: 0 or 1), and (database, name) pairs are unique across
entries case-insensitively.

### `schemas` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `database` | `string` | — | Existing database identifier containing the schema. |
| `name` | `string` | — | Schema identifier; unique within the database. Renaming means recreation (the data in the schema moves with it). |
| `with_managed_access` | `bool` | `null` | Managed-access schema: privileges on new objects are centralized with the schema owner/manager role instead of the creating role. Not set ⇒ Snowflake default. |
| `is_transient` | `bool` | `null` | Transient schema: no Fail-safe, Time Travel capped at 0 or 1 day. Fixed at creation — a type change needs recreation. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW SCHEMAS`. |
| `data_retention_time_in_days` | `number` | `null` | Time Travel retention in days for this schema (0–90; 0 or 1 for transient). |
| `max_data_extension_time_in_days` | `number` | `null` | Maximum days Snowflake may extend retention to prevent streams from falling off. |
| `default_ddl_collation` | `string` | `null` | Default collation specification applied to new tables and columns. |
| `log_level` | `string` | `null` | Log ingest level: `TRACE`–`OFF`. |

## Outputs

| Name | Description |
|---|---|
| `schema_fully_qualified_names` | Map of key => fully qualified name (quoted `"database"."schema"` form). Feed into `snowflake/grant-privileges` schema-level targets and consumer-side references. |
| `schema_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
schemas = {
  "analytics_raw" = {
    database                    = "DB_ANALYTICS"
    name                        = "RAW"
    with_managed_access         = true
    data_retention_time_in_days = 30
  }
  "analytics_report" = {
    database = "DB_ANALYTICS"
    name     = "REPORT"
  }
}
```

## Notes

- The role running Terraform needs CREATE SCHEMA on the database (or the
  corresponding granted privilege via `snowflake/grant-privileges`).
- Managed-access schemas centralize privilege management on the schema owner;
  grants still flow through `snowflake/grant-privileges` with the quoted
  fully qualified name from the outputs.
- If `with_managed_access` is left unset, the provider stores its `default`
  sentinel in state — setting the attribute later is an in-place update
  (enable/disable managed access). `is_transient` is create-only, so changing
  it later needs recreation.
- A schema cannot be dropped while it holds network rule–policy associations —
  the provider does not unassign them; remove the associations first.
- Dropping the parent database does not honour a child schema's own retention —
  Snowflake retains the schema for the database's retention period instead.
- Schema names must be unique within their database — PUBLIC and
  INFORMATION_SCHEMA are reserved by Snowflake.

## Import

`terraform import 'snowflake_schema.schema["<key>"]' '"<database_name>"."<schema_name>"'`

Both parts must be wrapped in literal double quotes per the provider. Set
`with_managed_access` and `is_transient` explicitly in config before importing
— the provider does not detect these flags on import, and an unset attribute
diffing against a managed-access or transient schema can end in recreation.
