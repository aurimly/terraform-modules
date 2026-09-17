# stackit/sqlserverflex_database

Map-keyed module for STACKIT SQLServer Flex databases inside an existing
SQLServer Flex instance (see stackit/sqlserverflex_instance).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `databases` | `map(object)` | — | Map of databases keyed by an arbitrary unique ID. |

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the database. |
| `instance_id` | `string` | — | UUID of the SQLServer Flex instance the database is created in (e.g. from stackit/sqlserverflex_instance's `instances` output, validated). Changing it replaces the database. |
| `name` | `string` | — | Database name (validated non-empty). Changing it replaces the database. |
| `owner` | `string` | — | Username of the database owner — must be an existing SQLServer Flex user; this module does not create users (validated non-empty). Changing it replaces the database. |
| `collation` | `string` | `null` | Collation of the database. Changing it replaces the database. |
| `compatibility` | `number` | `null` | Compatibility level of the database (valid values per SQLServer version — see the STACKIT/SQLServer documentation). Changing it replaces the database. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the database. |

## Outputs

`databases` — map of database key => object:

| Attribute | Description |
|---|---|
| `database_id` | Database ID (number). |
| `id` | `"{project_id},{region},{instance_id},{name}"` — the import ID. |

## Example

```hcl
module "sqlserverflex_database" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/sqlserverflex_database?ref=v2.1.0"

  databases = {
    "app" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      instance_id = module.sqlserverflex_instance.instances["app-db"].instance_id
      name        = "example_app"
      owner       = "example_app"
      region      = "eu01"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **Everything replaces on change**: `name`, `owner`, `collation` and
  `compatibility` (and the computed import ID ending in `name`) replace
  the database — adjust the config, not the resource, to recreate.
- `owner` should reference an existing SQLServer Flex user — create
  users via stackit/sqlserverflex_user; this module does not create
  users and exposes no credentials.
- Renaming a map key destroys and recreates the database.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs) and the documented rules (non-empty name and owner);
  `compatibility` is left unvalidated — valid levels depend on the
  SQLServer version.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_sqlserverflex_database` ← `{project_id},{region},{instance_id},{name}`
