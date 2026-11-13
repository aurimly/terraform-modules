# snowflake/task

Map-keyed module for Snowflake tasks inside existing schemas. Each entry
creates one `snowflake_task`; the `database` and `schema` must already exist
(e.g. from `snowflake/database` and `snowflake/schema` or outside Terraform).

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer; configure it at the
consumer unit level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `tasks` | `map(object)` | `{}` | Map of tasks keyed by an arbitrary unique ID. |

Plan-time validation: `database`, `schema`, `name` and `execute_as_user`
contain none of the characters the provider excludes on identifiers (`"`, `|`,
`.`), `schedule` sets exactly one time form, `target_completion_interval`
sets exactly one unit, `schedule` never coexists with `after`/`finalize`
(provider-documented conflicts), `warehouse` never coexists with
`user_task_managed_initial_warehouse_size`, `after` entries are non-empty,
`config` parses as JSON without `$$`, the warehouse-size strings match the
provider's accepted sizes, `log_level`/`log_event_level` match their provider
enums (all case-insensitive), and (database, schema, name) triples are unique
across entries.

### `tasks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `database` | `string` | — | Existing database identifier containing the task. |
| `schema` | `string` | — | Existing schema identifier containing the task. |
| `name` | `string` | — | Task identifier; unique within the schema. |
| `sql_statement` | `string` | — | The single SQL statement the task runs (multi-statement work belongs in a stored procedure). |
| `started` | `bool` | `false` | Start (resume) the task. Tasks are created suspended by default — start the root task of a DAG; child tasks follow the root. |
| `warehouse` | `string` | `null` | Warehouse the task runs on (server-managed). Prefer the upper-case name — due to Snowflake limitations the provider documents that this identifier consists of only upper-cased letters. Mutually exclusive with `user_task_managed_initial_warehouse_size`. |
| `when` | `string` | `null` | Condition, e.g. `SYSTEM$STREAM_HAS_DATA('MY_STREAM')` over a stream from `snowflake/stream`. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW TASKS`. |
| `config` | `string` | `null` | JSON string with task-level configuration, read via `SYSTEM$READ_PRETTY_TASK_CONFIG` / `read_task_config` in `sql_statement`. Stored in Terraform state — keep credentials out of it. |
| `after` | `list(string)` | `null` | Predecessor tasks as **fully qualified names** (not Terraform `depends_on`); see DAG wiring below. |
| `finalize` | `string` | `null` | Fully qualified root-task name for a finalizer task (runs when the root DAG completes). Conflicts with `schedule`. |
| `schedule` | `object` | `null` | Exactly one of `seconds`/`minutes`/`hours` (numbers) or `using_cron` (cron string). Conflicts with `after`/`finalize` — scheduled tasks cannot be DAG children. |
| `target_completion_interval` | `object` | `null` | Serverless tasks: target interval, exactly one of `seconds`/`minutes`/`hours`. |
| `allow_overlapping_execution` | `bool` | `null` | Allow overlapping runs of this task. Unset ⇒ Snowflake default. |
| `error_integration` | `string` | `null` | Error notification integration name. |
| `execute_as_user` | `string` | `null` | Run the task with this user's rights (owner-task or explicit user; must match the identifier rules). |
| `user_task_managed_initial_warehouse_size` | `string` | `null` | Serverless tasks: initial warehouse size (e.g. `XSMALL`, `X4LARGE`). Mutually exclusive with `warehouse`. |
| `serverless_task_min_statement_size` | `string` | `null` | Serverless tasks: minimum warehouse size for statements. |
| `serverless_task_max_statement_size` | `string` | `null` | Serverless tasks: maximum warehouse size for statements. |
| `suspend_task_after_num_failures` | `number` | `null` | Auto-suspend the task after this many consecutive failures. |
| `task_auto_retry_attempts` | `number` | `null` | Auto-retry attempts for failed task runs. |
| `user_task_timeout_ms` | `number` | `null` | Timeout for the task run in milliseconds. |
| `user_task_minimum_trigger_interval_in_seconds` | `number` | `null` | Minimum interval between trigger-based runs. |
| `log_level` | `string` | `null` | Log ingest level: `TRACE`–`OFF`. |
| `log_event_level` | `string` | `null` | Trace event level: `TRACE`–`OFF`. |

Roughly 40 further session parameters are intentionally not mapped, same as
the schema/database modules; add them to the module if the repo needs them.

## Outputs

| Name | Description |
|---|---|
| `task_fully_qualified_names` | Map of key => fully qualified name (quoted `"database"."schema"."task"` form). Feed into `snowflake/grant-privileges`, and pass back into `after`/`finalize` from another instance of this module to wire task DAGs. |
| `task_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
tasks = {
  "load_root" = {
    database      = "DB_ANALYTICS"
    schema        = "ETL"
    name          = "LOAD"
    sql_statement = "CALL DB_ANALYTICS.ETL.LOAD_EVENTS()"
    warehouse     = "WH_ETL"
    schedule = {
      using_cron = "0 2 * * * UTC"
    }
    comment = "Root task: load raw events each night"
  }
  "transform_child" = {
    database      = "DB_ANALYTICS"
    schema        = "ETL"
    name          = "TRANSFORM"
    sql_statement = "CALL DB_ANALYTICS.ETL.TRANSFORM_EVENTS()"
    warehouse     = "WH_ETL"
    after = [
      "\"DB_ANALYTICS\".\"ETL\".\"LOAD\"",
    ]
    when = "SYSTEM$STREAM_HAS_DATA('DB_ANALYTICS.ETL.STREAM_RAW_EVENTS')"
  }
}
```

## Notes

- The role running Terraform needs CREATE TASK on the target schema, EXECUTE
  TASK on the account, and USAGE on the warehouse; the task's role needs
  privileges on whatever `sql_statement` touches.
- `error_integration` points at an error notification integration, e.g. one
  from `snowflake/email-notification-integration` or an external notification
  integration managed outside Terraform.
- DAG wiring: set `after` (and `finalize`) to predecessor tasks' fully
  qualified names (`"<database>"."<schema>"."<task>"`). For tasks in a
  different module instance, reference `task_fully_qualified_names` from the
  root instance — the computed reference creates the Terraform dependency, so
  the root task is created first. For tasks within the same instance, write
  the FQN literal (a module's outputs cannot feed its own inputs). A DAG
  cycle fails at apply (Snowflake-side), not at plan.
- Scheduled tasks cannot be DAG children — `schedule` conflicts with both
  `after` and `finalize` (validated at plan time).
- Serverless tasks (`user_task_managed_initial_warehouse_size`) cannot run on
  multiple statements and have their own sizing attributes; they also need
  `target_completion_interval` for sensible billing behavior.
- `config` and `sql_statement` are sent to Snowflake verbatim; align
  whitespace to avoid permadiffs. Neither is sensitive to the provider —
  both land in Terraform state, so keep credentials out of them.

## Import

`terraform import 'snowflake_task.task["<key>"]' '"<database_name>"."<schema_name>"."<task_name>"'`

All parts must be wrapped in literal double quotes per the provider.
