# stackit/valkey_credential

Map-keyed module for STACKIT Valkey credentials on an existing Valkey
instance (see stackit/valkey_instance). Valkey is the successor to the
deprecated Redis service (see stackit/redis_instance); no Redis
credential module is provided here — use Valkey.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `credentials` | `map(object)` | — | Map of credentials keyed by an arbitrary unique ID. |

### `credentials` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the credential. |
| `instance_id` | `string` | — | ID of the Valkey instance the credential is created on (e.g. from stackit/valkey_instance's `instances` output, validated). Changing it replaces the credential. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the credential. |
| `rotate_when_changed` | `map(string)` | `null` | Rotation trigger: any change destroys and recreates the credential, producing a new API-generated password. |

There are no username inputs on this resource — username and password
are both API-generated, and Valkey credentials have no generated `name`
attribute either.

## Outputs

`credentials` (**sensitive**) — map of credential key => object:

| Attribute | Description |
|---|---|
| `username` | API-generated username, only returned at creation. |
| `password` | API-generated password, only returned at creation. |
| `credential_id` | Credential UUID. |
| `host` | Connection host. |
| `hosts` | List of connection hosts. |
| `load_balanced_host` | Connection host through the instance's load balancer. |
| `port` | Connection port (number). |
| `uri` | Connection URI, only returned at creation. |
| `id` | `"{project_id},{region},{instance_id},{credential_id}"` — the import ID. |

## Example

```hcl
module "valkey_credential" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/valkey_credential?ref=v2.8.0"

  credentials = {
    "app" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      instance_id = module.valkey_instance.instances["app-cache"].instance_id
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
- **Username and password are both API-generated and never settable**;
  they are only returned at creation. To obtain a new password, change
  `rotate_when_changed` (destroy + create; a brief window exists where
  the old password stops working). Because the output is sensitive,
  values must be pulled from the state/pipeline, not logs.
- **Imported credentials have empty username/password** — rotate via
  `rotate_when_changed` to obtain one.
- Renaming a map key destroys and recreates the credential — new
  username and password are generated.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs for `project_id`/`instance_id`) as forward-checking.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_valkey_credential` ← `{project_id},{region},{instance_id},{credential_id}`

The import ID has four parts. Some registry documentation examples for
the credential resources show a stale three-part form — a three-part ID
is rejected by the provider's import parser.
