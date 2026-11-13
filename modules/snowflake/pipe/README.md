# snowflake/pipe

Map-keyed module for Snowflake pipes inside existing schemas. Each entry
creates one `snowflake_pipe` around its COPY statement; the `database` and
`schema` must already exist (e.g. from `snowflake/database` and
`snowflake/schema` or outside Terraform).

**Provider preview feature** — `snowflake_pipe` requires
`preview_features_enabled = ["snowflake_pipe_resource"]` in the consumer's
`snowflake` provider block, or the resource is unknown to Terraform. Preview
resources can change without a provider major bump.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `pipes` | `map(object)` | `{}` | Map of pipes keyed by an arbitrary unique ID. |

Plan-time validation: `database`, `schema` and `name` contain none of the
characters the provider excludes on identifiers (`"`, `|`, `.`),
`copy_statement` is non-blank, `auto_ingest = true` requires a notification
source (`aws_sns_topic_arn` or `integration`), `log_event_level` matches its
provider enum (case-insensitive), and (database, schema, name) triples are
unique across entries case-insensitively.

### `pipes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `database` | `string` | — | Existing database identifier containing the pipe. |
| `schema` | `string` | — | Existing schema identifier containing the pipe. |
| `name` | `string` | — | Pipe identifier; unique within the schema. |
| `copy_statement` | `string` | — | The pipe's single `COPY INTO` statement, sent to Snowflake verbatim. Use **fully qualified** names for the table, stage and file format inside it — the provider does not run `USE DATABASE`/`USE SCHEMA` before `CREATE PIPE`, so unqualified names resolve against the session and fail. Stored in Terraform state — keep credentials out of it. |
| `auto_ingest` | `bool` | `null` | Enable auto-ingest from a notification source. Unset ⇒ Snowflake default (false). |
| `aws_sns_topic_arn` | `string` | `null` | SNS topic ARN carrying stage notifications (AWS). Required for auto-ingest on AWS. |
| `integration` | `string` | `null` | Notification integration name (Azure Event Grid / GCP Pub/Sub). Required for auto-ingest outside AWS. |
| `error_integration` | `string` | `null` | Error notification integration name. |
| `pipe_execution_paused` | `bool` | `null` | Pause (suspend) the pipe. Unset ⇒ Snowflake default (false). |
| `log_event_level` | `string` | `null` | Trace event level: `TRACE`–`OFF`. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW PIPES`. |

## Outputs

| Name | Description |
|---|---|
| `pipe_fully_qualified_names` | Map of key => fully qualified name (quoted `"database"."schema"."pipe"` form). Feed into consumer-side references and grant workflows. |
| `pipe_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
pipes = {
  "load_events" = {
    database       = "DB_ANALYTICS"
    schema         = "RAW"
    name           = "PIPE_LOAD_EVENTS"
    copy_statement = "COPY INTO ${module.raw_tables.table_fully_qualified_names["events"]} FROM \"DB_ANALYTICS\".\"RAW\".\"STAGE_RAW\" FILE_FORMAT = (TYPE = PARQUET)"
    auto_ingest       = true
    aws_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:stage-events"
  }
  "streaming_telemetry" = {
    database       = "DB_ANALYTICS"
    schema         = "RAW"
    name           = "PIPE_TELEMETRY"
    copy_statement = "COPY INTO ${module.raw_tables.table_fully_qualified_names["telemetry"]} FROM (SELECT * FROM TABLE(DATA_SOURCE(TYPE => 'STREAMING'))) FILE_FORMAT = (TYPE = PARQUET)"
  }
}
```

## Notes

- The role running Terraform needs CREATE PIPE on the target schema plus
  USAGE on the stage and INSERT on the target table; the pipe reads
  notifications through the stage's notification channel.
- `copy_statement` is the pipe's identity: changing it updates the pipe. Use
  fully qualified names inside the statement (see the attribute description)
  and interpolate `snowflake/table`'s `table_fully_qualified_names` output
  rather than writing the table name twice.
- `error_integration` points at an error notification integration, e.g. one
  from `snowflake/email-notification-integration` or an external notification
  integration managed outside Terraform.
- Credentials: the provider does not mark `copy_statement` sensitive, so it
  lands in Terraform state. Never embed storage `CREDENTIALS` clauses or keys
  in it — create a storage integration (managed outside this module) and let
  the stage use it; the pipe inherits the stage's authentication.
- Snowpipe Streaming: same resource; the statement reads from
  `TABLE(DATA_SOURCE(TYPE => 'STREAMING'))` and no notification source is
  set (the second example).
- The deprecated read-only `notification_channel` and `owner` attributes are
  not surfaced as outputs; read them from `SHOW PIPES` /
  `snowflake_pipe.pipe[...].show_output` consumer-side if needed.

## Import

`terraform import 'snowflake_pipe.pipe["<key>"]' '"<database_name>"."<schema_name>"."<pipe_name>"'`

All parts must be wrapped in literal double quotes per the provider.
