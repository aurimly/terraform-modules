# snowflake/database

Map-keyed module for Snowflake databases. Each entry creates one
`snowflake_database` in the account configured on the provider.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

The resource additionally takes Iceberg parameters (`catalog`,
`external_volume`, `storage_serialization_policy`), task/session parameters
(`trace_level`, `suspend_task_after_num_failures`, ...) and `timeouts` blocks
that are intentionally not mapped here; add them to the module if the repo
needs them.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `databases` | `map(object)` | `{}` | Map of databases keyed by an arbitrary unique ID. |

Plan-time validation: `name` contains none of the characters the provider
excludes on database identifiers (`"`, `|`, `.`), `log_level` matches its
provider enum (case-insensitive), `data_retention_time_in_days` is 0–90
(transient databases: 0 or 1), replication account identifiers are the plain
two-segment `org.account` form, and names are unique across entries
case-insensitively.

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Database identifier; unique across the account. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW DATABASES`. |
| `is_transient` | `bool` | `null` | Transient database: no Fail-safe, Time Travel limited to 0 or 1 day. Changing the type later needs recreation — the provider does not detect external type changes, so align config and state manually. |
| `data_retention_time_in_days` | `number` | `null` | Time Travel retention in days (0–90; 0 or 1 for transient). Snowflake default is 1 (Enterprise+ accounts can raise it). |
| `max_data_extension_time_in_days` | `number` | `null` | Maximum days Snowflake may extend retention to prevent streams from falling off. |
| `drop_public_schema_on_creation` | `bool` | `null` | Do not create the PUBLIC schema on creation. Applies at creation only — changing it later does nothing. |
| `default_ddl_collation` | `string` | `null` | Default collation specification applied to new tables and columns. |
| `log_level` | `string` | `null` | Log ingest level: `TRACE`–`OFF`. |
| `replication` | `object` | `null` | Replication configuration; promotes this database to a primary. See below. |

### `replication` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enable_to_account` | `list(object)` | — (required) | One entry per target account. |
| `enable_to_account[*].account_identifier` | `string` | — | Target account in the plain `<org>.<account>` form, e.g. `ORG_ACME.SECONDARY`. Quoted identifiers are valid in Snowflake but rejected by this module's validation. |
| `enable_to_account[*].with_failover` | `bool` | `null` | Enable failover to the target account (needs Business Critical Edition and appropriate replication policies). |
| `ignore_edition_check` | `bool` | `null` | Skip the check that the accounts share the same Snowflake edition. |

## Outputs

| Name | Description |
|---|---|
| `database_fully_qualified_names` | Map of key => fully qualified name. Use in grants (object references must be quoted fully qualified names) and consumer-side references. |
| `database_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
databases = {
  "reporting" = {
    name                        = "DB_REPORTING"
    data_retention_time_in_days = 30
    comment                     = "Reporting database"
    replication = {
      enable_to_account = [
        { account_identifier = "ORG_ACME.SECONDARY", with_failover = true }
      ]
      ignore_edition_check = false
    }
  }
  "scratch" = {
    name                        = "DB_SCRATCH"
    is_transient                = true
    data_retention_time_in_days = 1
  }
}
```

## Notes

- The role running Terraform needs CREATE DATABASE on the account.
- Replication is available on all editions; failover/failback between accounts
  requires Business Critical Edition or higher. Cross-region and cross-cloud
  replication is billed separately for data transfer.
- Dropping a database fails while network-rule associations exist — the
  provider does not unassign them; remove the associations first.
- Schemas inside the database come from `snowflake/schema`; grants from
  `snowflake/grant-privileges`.

## Import

`terraform import 'snowflake_database.database["<key>"]' '"<name>"'`

The database name must be wrapped in literal double quotes per the provider.
Set `is_transient` explicitly in config before importing — the provider does
not detect the database type on import, and an unset attribute diffing against
a transient database can end in recreation.
