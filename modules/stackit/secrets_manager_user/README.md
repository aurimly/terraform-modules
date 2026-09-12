# stackit/secrets_manager_user

Map-keyed module for STACKIT Secrets Manager users on an existing Secrets
Manager instance (see stackit/secrets_manager).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `users` | `map(object)` | — | Map of users keyed by an arbitrary unique ID. |

### `users` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the user. |
| `instance_id` | `string` | — | UUID of the Secrets Manager instance the user is created on (e.g. from stackit/secrets_manager's `instances` output, validated). Changing it replaces the user. |
| `description` | `string` | — | Free text to tell users apart. See the description caveat below — treat it as create-time. |
| `write_enabled` | `bool` | — | Whether the user has write access to the secrets engine. |
| `rotate_when_changed` | `map(string)` | `null` | Rotation trigger: any change destroys and recreates the user, producing a new API-generated password. |

## Outputs

`users` (**sensitive**) — map of user key => object:

| Attribute | Description |
|---|---|
| `username` | API-generated username. |
| `password` | API-generated password, only returned at creation. |
| `user_id` | User UUID. |
| `id` | `"{project_id},{instance_id},{user_id}"` — the import ID. |

## Example

```hcl
module "secrets_manager_user" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/secrets_manager_user?ref=v1.3.0"

  users = {
    "reader" = {
      project_id    = "12345678-1234-1234-1234-123456789012"
      instance_id   = module.secrets_manager.instances["app"].instance_id
      description   = "example read-only user"
      write_enabled = false
    }
    "writer" = {
      project_id          = "12345678-1234-1234-1234-123456789012"
      instance_id         = module.secrets_manager.instances["app"].instance_id
      description         = "example user with write access"
      write_enabled       = true
      rotate_when_changed = {
        rotation = "2026-09-12"
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **`username` is API-generated — there is no username input.**
- **The password is API-generated and never settable**; it is only
  returned at creation. To obtain a new password, change
  `rotate_when_changed` (destroy + create; a brief window exists where
  the old password stops working). Because the output is sensitive,
  values must be pulled from the state/pipeline, not logs.
- **Imported users have an empty password** (the provider warns about
  this at import time) — rotate via `rotate_when_changed` to obtain
  one.
- **`description` caveat**: the provider schema allows the change to
  update in place, but the STACKIT docs say it can't be changed after
  creation. A changed description may be silently ignored by the API
  and surface as permanent drift on the next refresh — treat
  `description` as create-time.
- Renaming a map key destroys and recreates the user.
- The resource has no `region` attribute — the region comes from the
  provider configuration at the consumer's unit level, which must set
  one or the apply fails provider-side.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs for `project_id`/`instance_id`) plus a non-empty
  `description` check as forward-checking — the provider has no
  description validator.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_secretsmanager_user` ←
`{project_id},{instance_id},{user_id}`
