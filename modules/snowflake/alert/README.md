# snowflake/alert

Map-keyed module for Snowflake alerts. Each entry creates one
`snowflake_alert` in the given database/schema, running its condition SQL on
the given warehouse on a schedule.

The alert resource is a **provider preview feature** (`snowflake_alert_resource`):
enable it in the provider configuration on the consumer unit with
`preview_features_enabled = ["snowflake_alert_resource"]`, or the resource is
unknown to Terraform entirely. Preview features can change without a
provider major bump.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `alerts` | `map(object)` | `{}` | Map of alerts keyed by an arbitrary unique ID. |

Plan-time validation: `alert_schedule` sets exactly one of `interval` or
`cron`, `interval` is between 1 and 1439 minutes, `cron` fields are non-empty,
and `database`/`schema`/`name` contain no `"|"` (the import identifier is
pipe-separated).

### `alerts` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `database` | `string` | — | Database the alert lives in. |
| `schema` | `string` | — | Schema the alert lives in. |
| `name` | `string` | — | Alert identifier; unique within the schema. |
| `warehouse` | `string` | — | Warehouse the alert runs on; must be running for scheduled alert evaluation to consume credits. |
| `condition` | `string` | — | SELECT/SHOW/CALL returning one or more rows when the alert should fire. |
| `action` | `string` | — | SQL statement executed when the condition returns rows — e.g. a `SYSTEM$SEND_EMAIL` call referencing an email notification integration (`snowflake/email-notification-integration`). |
| `enabled` | `bool` | `false` | Start the alert enabled (`RESUMED`) after creation or leave it suspended. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW ALERTS`. |
| `alert_schedule` | `object` | `null` | Omitting the schedule is valid — the alert then only runs when triggered manually. Either `interval` (minutes) or `cron`. |
| `alert_schedule.interval` | `number` | `null` | Period in minutes, 1–1439. |
| `alert_schedule.cron.expression` | `string` | — | 5-field cron: `minute hour day-of-month month day-of-week`. |
| `alert_schedule.cron.time_zone` | `string` | — | IANA time zone for the schedule, e.g. `Europe/Paris` (required when `cron` is set). |

## Outputs

| Name | Description |
|---|---|
| `alert_fully_qualified_names` | Map of key => fully qualified name (`database.schema.name`) — use when the alert is referenced elsewhere in the provider (GRANT statements, references in other SQL). |
| `alert_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
alerts = {
  "failed-logins" = {
    database  = "SECURITY"
    schema    = "MONITORING"
    name      = "ALERT_FAILED_LOGINS"
    warehouse = "WH_MONITORING"
    condition = "SELECT COUNT(*) FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY WHERE IS_SUCCESS = 'NO' AND EVENT_TIMESTAMP > DATEADD('MINUTE', -10, CURRENT_TIMESTAMP())"
    action    = "SELECT SYSTEM$SEND_EMAIL('ntf_monitoring', 'oncall@example.com', 'Failed logins detected', 'More than one failed login in the last 10 minutes')"
    enabled   = true
    alert_schedule = {
      interval = 10
    }
  }
}
```

## Notes

- The role running Terraform needs CREATE ALERT privileges on the schema and
  USAGE on the database, schema and warehouse. At runtime the executing role
  also needs the privileges the `action` SQL implies (EXECUTE ALERT on the
  alert, plus whatever e.g. `SYSTEM$SEND_EMAIL` needs on the notification
  integration); without them an enabled alert fails when it fires.
- The schedule only defines when the condition is evaluated; alerts consume
  warehouse credits every time condition and action run.
- `name` must be unique within its schema (Snowflake-enforced) — the module
  validates nothing cross-entry; names and the database/schema fields provided
  here land in different schemas per entry, so collisions stay the consumer's
  concern.

## Import

`terraform import 'snowflake_alert.alert["<key>"]' 'dbName|schemaName|alertName'`
