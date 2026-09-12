# stackit/postgresflex_database

Map-keyed module for STACKIT PostgreSQL Flex databases inside an existing
PostgreSQL Flex instance (see stackit/postgresflex_instance).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `databases` | `map(object)` | — | Map of databases keyed by an arbitrary unique ID. |

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the database. |
| `instance_id` | `string` | — | UUID of the PostgreSQL Flex instance the database is created in (e.g. from stackit/postgresflex_instance's `instances` output, validated). Changing it replaces the database. |
| `name` | `string` | — | Database name. Updates in place. |
| `owner` | `string` | — | Username of the database owner — must be an existing PostgresFlex user; this module does not create users. Updates in place. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the database. |

## Outputs

`databases` — map of database key => object:

| Attribute | Description |
|---|---|
| `database_id` | Database UUID. |
| `id` | `"{project_id},{region},{instance_id},{database_id}"` — the import ID. |

## Example

```hcl
module "postgresflex_database" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/postgresflex_database?ref=v1.3.0"

  databases = {
    "app" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      instance_id = module.postgresflex_instance.instances["app-db"].instance_id
      name        = "example_app"
      owner       = "example_owner"
      region      = "eu01"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- `owner` must reference an existing PostgresFlex user — create users
  consumer-side or via a future `postgresflex_user` module; this module
  does not create users and exposes no credentials.
- Renaming a map key destroys and recreates the database.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs) and the documented rules (non-empty name and owner).
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_postgresflex_database` ←
`{project_id},{region},{instance_id},{database_id}`
