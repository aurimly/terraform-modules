# aws/dynamodb

Map-keyed module for DynamoDB tables.

## Destroy semantics (read before using)

Destroying a table entry removes the table **and all data**, streams, and
index contents; secondary indexes exist only inside the table.

- `deletion_protection_enabled = true` **(module default)** makes the AWS API refuse the delete
  (`AccessDeniedException: Table is protected`). The flag is the module's removal protection:
  the AWS-side guard stays in force even when the resource is already gone from Terraform
  state, which is exactly the kind of mistake it is meant to catch. Unlike terraform's
  `lifecycle { prevent_destroy }` (which only takes literals — hashicorp/terraform#22544),
  this flag is plan-time settable; toggling it off does not force replacement.
- `point_in_time_recovery` does not survive `terraform destroy`/`tofu
  destroy` — Amazon stops the continuous backup when the table is deleted,
  so PITR is **not** a destroy safety net. Use on-demand backups
  (`aws_dynamodb_backup`) outside this module if you need recovery after a
  delete.
- To detach a table without deleting it, remove it from state before
  taking the key out of the map: `tofu state rm
  'module.tables.aws_dynamodb_table.table["key"]'`. A `removed` block on
  the module call plans a destroy of the table — do not use it if the
  table must survive.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `tables` | `map(object)` | `{}` | Map of tables keyed by an arbitrary unique ID. |

### `tables` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Table name, 3–255 chars, letters/digits/`_.-` (validated). Immutable; changing forces replacement. |
| `hash_key` | `string` | — | Partition key attribute name; must exist in `attributes` (validated). Immutable. |
| `range_key` | `string` | — | Sort key attribute name; must exist in `attributes` (validated). Immutable. |
| `billing_mode` | `string` | `PAY_PER_REQUEST` | One of `PAY_PER_REQUEST`, `PROVISIONED` (validated); capacity fields follow the mode (validated both ways). |
| `read_capacity` / `write_capacity` | `number` | — | Provisioned table throughput; required for `PROVISIONED`, forbidden for `PAY_PER_REQUEST` (validated). |
| `table_class` | `string` | `STANDARD` | One of `STANDARD`, `STANDARD_INFREQUENT_ACCESS` (validated). |
| `deletion_protection_enabled` | `bool` | `true` | AWS-side destroy protection — see Destroy semantics. Defaults **on**; flipping it to `false` temporarily is the intended removal path. |
| `stream_enabled` | `bool` | `false` | Enable the DynamoDB stream. |
| `stream_view_type` | `string` | — | One of `KEYS_ONLY`, `NEW_IMAGE`, `OLD_IMAGE`, `NEW_AND_OLD_IMAGES` (validated); requires `stream_enabled` (validated). |
| `tags` | `map(string)` | `{}` | Tags (no `Name` tag — DynamoDB tables have no name tag convention; tags only). |
| `attributes` | `map(object)` | — | Map of attribute name => `{type}` with type one of `S`, `N`, `B` (validated). Only key attributes belong here (GSI/LSI keys included) — not every attribute stored. |
| `global_secondary_indexes` | `map(object)` | — | See the GSI object table. |
| `local_secondary_indexes` | `map(object)` | — | See the LSI object table. |
| `ttl` | `object` | — | `{attribute_name, enabled}` — presence manages TTL. |
| `point_in_time_recovery` | `object` | — | `{enabled, recovery_period_in_days}` — presence manages PITR. |
| `server_side_encryption` | `object` | — | `{enabled, kms_key_arn}` — presence manages SSE; ARN shape-validated. |

### `global_secondary_indexes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Index name (DDB-wide unique per table). |
| `hash_key` | `string` | — | Index partition key; must exist in `attributes` (validated). |
| `range_key` | `string` | — | Index sort key; must exist in `attributes` (validated). |
| `projection_type` | `string` | `ALL` | One of `ALL`, `KEYS_ONLY`, `INCLUDE` (validated). |
| `non_key_attributes` | `list(string)` | — | Required for `INCLUDE` (validated). |
| `read_capacity` / `write_capacity` | `number` | — | Required on `PROVISIONED` tables, rejected on `PAY_PER_REQUEST` (validated). |

### `local_secondary_indexes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Index name. |
| `range_key` | `string` | — | Index sort key (required — LSI shares the table hash key); must exist in `attributes` (validated). |
| `projection_type` | `string` | `ALL` | One of `ALL`, `KEYS_ONLY`, `INCLUDE` (validated). |
| `non_key_attributes` | `list(string)` | — | Required for `INCLUDE` (validated). |

## Outputs

`table_arns` — map of table key => table ARN.
`table_ids` — map of table key => table name.
`stream_arns` — map of table key => stream ARN (keys omitted when the stream is disabled).

## Example

```hcl
tables = {
  "sessions" = {
    name                        = "example-sessions"
    deletion_protection_enabled = true
    server_side_encryption = {
      enabled = true
    }
    attributes = {
      "user_id" = { type = "S" }
      "ts"      = { type = "N" }
    }
    global_secondary_indexes = {
      "by-ts" = {
        name            = "ts-index"
        hash_key        = "ts"
        projection_type = "KEYS_ONLY"
      }
    }
    ttl = {
      attribute_name = "expires_at"
      enabled        = true
    }
    point_in_time_recovery = {
      enabled = true
    }
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not table names. Multiple tables
  can share a `name` (different regions/accounts); only the key must be
  unique.
- `attributes` maps over the *key* attributes only (table keys plus every
  index key); DynamoDB does not need (or accept) a declaration for values
  — that is the point of a schemaless store.
- `hash_key`, `range_key`, index keys and `billing_mode` are immutable —
  changing them replaces the table (and its contents). Plan review should
  treat those as replacement triggers.
- Streams keep flowing after `stream_view_type` changes; the type is
  updated in place.
- This module does not manage `aws_dynamodb_table_item` seed data,
  contributor insights, alarms, autoscaling (`aws_appautoscaling_*`) or
  global table replicas; pair it with those consumer-side when needed.

## Import

`aws_dynamodb_table` ← table name.
