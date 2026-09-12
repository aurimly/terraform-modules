# stackit/postgresflex_user

Map-keyed module for STACKIT PostgreSQL Flex database users on an existing
PostgreSQL Flex instance (see stackit/postgresflex_instance).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `users` | `map(object)` | — | Map of users keyed by an arbitrary unique ID. |

### `users` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the user. |
| `instance_id` | `string` | — | UUID of the PostgreSQL Flex instance the user is created on (e.g. from stackit/postgresflex_instance's `instances` output, validated). Changing it replaces the user. |
| `username` | `string` | — | Database username. Updates in place; changing it does not regenerate the password. |
| `roles` | `set(string)` | — | Database access levels for the user (e.g. `["login"]`). Updates in place. The provider does not validate role names — see the STACKIT PostgresFlex documentation for valid values. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the user. |
| `rotate_when_changed` | `map(string)` | `null` | Rotation trigger: any change destroys and recreates the user, producing a new API-generated password. |

## Outputs

`users` (**sensitive**) — map of user key => object:

| Attribute | Description |
|---|---|
| `username` | Database username. |
| `password` | API-generated password, only returned at creation. |
| `user_id` | User ID. |
| `id` | `"{project_id},{region},{instance_id},{user_id}"` — the import ID. |

## Example

```hcl
module "postgresflex_user" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/postgresflex_user?ref=v1.3.0"

  users = {
    "app" = {
      project_id   = "12345678-1234-1234-1234-123456789012"
      instance_id  = module.postgresflex_instance.instances["app-db"].instance_id
      username     = "example_app"
      roles        = ["login"]
      region       = "eu01"
    }
    "app-rotate" = {
      project_id          = "12345678-1234-1234-1234-123456789012"
      instance_id         = module.postgresflex_instance.instances["app-db"].instance_id
      username            = "example_app_rotated"
      roles               = ["login"]
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
- **The password is API-generated and never settable**; it is only
  returned at creation. Changing `username` or `roles` updates the user
  in place but does not regenerate the password — to obtain a new
  password, change `rotate_when_changed` (destroy + create; a brief
  window exists where the old password stops working). Because the
  output is sensitive, values must be pulled from the state/pipeline,
  not logs.
- **Imported users have an empty password** (the provider warns about
  this at import time) — rotate via `rotate_when_changed` to obtain
  one.
- Renaming a map key destroys and recreates the user.
- The deprecated `host`/`port`/`uri` attributes of the resource are
  intentionally not exposed; connection info comes from the
  stackit/postgresflex_instance module.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs for `project_id`/`instance_id`) plus a non-empty `username`
  check as forward-checking; the `roles` content is left unvalidated —
  the provider does not enumerate valid values, see the STACKIT docs
  for the role list.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_postgresflex_user` ←
`{project_id},{region},{instance_id},{user_id}`
