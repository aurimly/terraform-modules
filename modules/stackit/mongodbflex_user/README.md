# stackit/mongodbflex_user

Map-keyed module for STACKIT MongoDB Flex database users on an existing
MongoDB Flex instance (see stackit/mongodbflex_instance).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `users` | `map(object)` | — | Map of users keyed by an arbitrary unique ID. |

### `users` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the user. |
| `instance_id` | `string` | — | ID of the MongoDB Flex instance the user is created on (e.g. from stackit/mongodbflex_instance's `instances` output, validated). Changing it replaces the user. |
| `username` | `string` | — | Database username: 3–63 characters, starts with a letter, ends in a letter or digit (validated with the provider's own rule). Required in this module — see Notes. Changing it replaces the user. |
| `roles` | `set(string)` | — | Database access levels for the user (e.g. `["read"]`) — follow MongoDB built-in role names. Updates in place. |
| `database` | `string` | — | Database the roles apply to (validated non-empty). Changing it replaces the user. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the user. |
| `rotate_when_changed` | `map(string)` | `null` | Rotation trigger: any change destroys and recreates the user, producing a new API-generated password. |

## Outputs

`users` (**sensitive**) — map of user key => object:

| Attribute | Description |
|---|---|
| `username` | Database username. |
| `password` | API-generated password, only returned at creation. |
| `user_id` | User ID. |
| `host` | Connection host. |
| `port` | Connection port (number). |
| `uri` | Connection URI, API-generated, only returned at creation. |
| `id` | `"{project_id},{region},{instance_id},{user_id}"` — the import ID. |

## Example

```hcl
module "mongodbflex_user" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/mongodbflex_user?ref=v1.19.0"

  users = {
    "app" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      instance_id = module.mongodbflex_instance.instances["app-db"].instance_id
      username    = "example_app"
      roles       = ["readWrite"]
      database    = "example_app"
      region      = "eu01"
    }
    "app-rotate" = {
      project_id          = "12345678-1234-1234-1234-123456789012"
      instance_id         = module.mongodbflex_instance.instances["app-db"].instance_id
      username            = "example_app_rotated"
      roles               = ["readWrite"]
      database            = "example_app"
      region              = "eu01"
      rotate_when_changed = {
        rotation = "2026-09-12"
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **`username` is required in this module** even though the provider
  would let it be unset (API-generated username in that case) — an
  auto-generated username is not useful for consumers. This is a
  module-level restriction, not a provider constraint.
- **The password is API-generated and never settable**; it is only
  returned at creation. Changing `username`, `roles` or `database`
  updates or replaces the user but does not regenerate the password by
  itself — to obtain a new password, change `rotate_when_changed`
  (destroy + create; a brief window exists where the old password stops
  working). Because the output is sensitive, values must be pulled from
  the state/pipeline, not logs.
- **Imported users have an empty password and URI** (the provider warns
  about this at import time) — rotate via `rotate_when_changed` to
  obtain one.
- Renaming a map key destroys and recreates the user — a new password
  is generated.
- Unlike stackit/postgresflex_user, `host`/`port`/`uri` are exposed
  here: they are not deprecated on this resource and are the only
  connection info the user resource offers.
- `roles` are not enumerated by the provider; values follow MongoDB
  built-in role names (e.g. `read`, `readWrite`, `readWriteAnyDatabase`)
  — see the STACKIT/MongoDB documentation.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs for `project_id`/`instance_id`, the username regex) plus a
  non-empty `database` check as forward-checking; the `roles` content
  is left unvalidated — the provider does not enumerate valid values.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_mongodbflex_user` ← `{project_id},{region},{instance_id},{user_id}`
