# cloudflare/d1

Map-keyed module for Cloudflare D1 databases. Each entry creates one
`cloudflare_d1_database` in the account resolved from the entry's `account_id`
or the module-level fallback.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | `""` | Fallback account ID for entries that omit `account_id`. |
| `databases` | `map(object)` | — | Map of D1 databases keyed by an arbitrary unique ID. |

Plan-time validation: (resolved account, name) pairs are unique across entries
case-insensitively, `name` is non-empty, `jurisdiction` is `eu`/`fedramp`/`us`,
`primary_location_hint` is one of `wnam`/`enam`/`weur`/`eeur`/`apac`/`oc`, and
`read_replication_mode` is `auto`/`disabled`. A missing `account_id` on both
levels fails the lifecycle precondition with a keyed message.

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Database name, unique per account, case-insensitively; the API identifier used in bindings and import. Immutable — changing it forces replacement, which destroys the database's data. |
| `account_id` | `string` | `null` | Account for this database; falls back to the module-level `account_id` when omitted. |
| `jurisdiction` | `string` | `null` | Restrict the database's data location: `eu`, `fedramp` or `us`. When set, the location hint is ignored. |
| `primary_location_hint` | `string` | `null` | Region hint for the primary: `wnam`, `enam`, `weur`, `eeur`, `apac` or `oc`. Ignored when `jurisdiction` is set; when both are omitted the primary is placed close to the caller. |
| `read_replication_mode` | `string` | `null` | Read replication: `auto` to let D1 place replicas, `disabled` to remove them (replica removal can take hours). Omit to keep the default single-primary setup. |

## Outputs

| Name | Description |
|---|---|
| `database_ids` | Map of key => database ID (the D1 UUID). |
| `database_names` | Map of key => database name. |

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

databases = {
  "app-primary" = {
    name                  = "app-db"
    jurisdiction          = "eu"
    read_replication_mode = "auto"
  }
  "analytics" = {
    name                  = "analytics-db"
    primary_location_hint = "wnam"
  }
}
```

## Notes

- Replacing a D1 database loses all of its data — the provider warns about
  this on the resource, and the module adds nothing to soften it. The
  init-only fields (`name`, `jurisdiction`, `primary_location_hint`) all force
  replacement: back up (export SQL) before touching any of them.
- The module floor is the repo-wide `>= 5.0.0`, but `read_replication` only
  exists from provider v5.4.0 and the `jurisdiction = "us"` value from v5.24.0
  — consumers pinned below those get "unsupported attribute".
  The module was researched against v5.29.0.
- `jurisdiction` and `primary_location_hint` are alternatives: the API ignores
  the hint whenever a jurisdiction is set. Both can be configured without
  error, but only one takes effect.
- D1 usage — schema migrations and queries — stays with the application
  tooling (wrangler), the same split as script content for
  `cloudflare/workers_script`. This module manages the database object only.
- `read_replication_mode = "disabled"` deletes existing replicas
  asynchronously; the provider notes it can take a few hours for all replicas
  to go away.
- The caller needs `D1 Read` and `D1 Write` on the account.

## Import

`cloudflare_d1_database` ← `<account_id>/<database_id>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/8c2625da-2ebb-4f8e-8f87-3f4b6c1f0a11`.
