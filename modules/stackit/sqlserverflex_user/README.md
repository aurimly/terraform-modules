# stackit/sqlserverflex_user

Map-keyed module for STACKIT SQLServer Flex database users on an
existing SQLServer Flex instance (see stackit/sqlserverflex_instance).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `users` | `map(object)` | — | Map of users keyed by an arbitrary unique ID. |

### `users` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the user. |
| `instance_id` | `string` | — | ID of the SQLServer Flex instance the user is created on (e.g. from stackit/sqlserverflex_instance's `instances` output, validated). Changing it replaces the user. |
| `username` | `string` | — | Database username (validated non-empty). Changing it replaces the user. |
| `roles` | `set(string)` | — | Database access levels for the user. Required with no provider-side default — the default role set to pass is `##STACKIT_DatabaseManager##`, `##STACKIT_LoginManager##`, `##STACKIT_ProcessManager##`, `##STACKIT_ServerManager##`, `##STACKIT_SQLAgentManager##`, `##STACKIT_SQLAgentUser##` (the provider does not fill these in for you). Changing it replaces the user. |
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
| `id` | `"{project_id},{region},{instance_id},{user_id}"` — the import ID. |

No `uri` output — this resource does not expose one (unlike
mongodbflex_user).

## Example

```hcl
module "sqlserverflex_user" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/sqlserverflex_user?ref=v2.1.0"

  users = {
    "app" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      instance_id = module.sqlserverflex_instance.instances["app-db"].instance_id
      username    = "example_app"
      roles       = ["##STACKIT_DatabaseManager##", "##STACKIT_LoginManager##"]
      region      = "eu01"
    }
    "app-rotate" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      instance_id = module.sqlserverflex_instance.instances["app-db"].instance_id
      username    = "example_app_rotated"
      roles       = ["##STACKIT_DatabaseManager##", "##STACKIT_LoginManager##"]
      region      = "eu01"
      rotate_when_changed = {
        rotation = "2026-09-12"
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **`roles` is required with no provider-side default** — the
  `##STACKIT_*##` values documented upstream are the recommended
  default set to pass, not values the provider applies by itself.
- **The password is API-generated and never settable**; it is only
  returned at creation. Changing `username` or `roles` replaces the
  user but does not regenerate the password by itself — to obtain a new
  password, change `rotate_when_changed` (destroy + create; a brief
  window exists where the old password stops working). Because the
  output is sensitive, values must be pulled from the state/pipeline,
  not logs.
- **Imported users have an empty password** — rotate via
  `rotate_when_changed` to obtain one.
- Renaming a map key destroys and recreates the user — a new password
  is generated.
- This resource does not expose a `uri` (unlike mongodbflex_user);
  connect with `host` and `port`.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs for `project_id`/`instance_id`, non-empty `username`) plus the
  forward-checking note on `roles` content above.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_sqlserverflex_user` ← `{project_id},{region},{instance_id},{user_id}`
