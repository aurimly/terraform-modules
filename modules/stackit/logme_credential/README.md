# stackit/logme_credential

Map-keyed module for STACKIT LogMe credentials on an existing LogMe
instance (see stackit/logme_instance).

> **No rotation trigger**: unlike stackit/rabbitmq_credential and
> stackit/mariadb_credential, the LogMe credential resource has no
> `rotate_when_changed` attribute. Rotation is only possible by
> destroying and recreating the credential.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `credentials` | `map(object)` | — | Map of credentials keyed by an arbitrary unique ID. |

### `credentials` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the credential. |
| `instance_id` | `string` | — | ID of the LogMe instance the credential is created on (e.g. from stackit/logme_instance's `instances` output, validated). Changing it replaces the credential. |
| `region` | `string` | provider region | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the credential. |

There are no `username` inputs on this resource — username and password
are both API-generated (the credential resource is the provider's user
resource; there is no separate LogMe user resource).

## Outputs

`credentials` (**sensitive**) — map of credential key => object:

| Attribute | Description |
|---|---|
| `username` | API-generated username, only returned at creation. |
| `password` | API-generated password, only returned at creation. |
| `credential_id` | Credential UUID. |
| `host` | Connection host. |
| `port` | Connection port (number). |
| `uri` | Connection URI, only returned at creation. |
| `id` | `"{project_id},{region},{instance_id},{credential_id}"` — the import ID. |

## Example

```hcl
module "logme_credential" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/logme_credential?ref=v2.2.0"

  credentials = {
    "app" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      instance_id = module.logme_instance.instances["app-logs"].instance_id
      region      = "eu01"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **Username and password are both API-generated and never settable**;
  they are only returned at creation. The sensitive output must be
  pulled from the state/pipeline, not logs.
- **No `rotate_when_changed`** — the upstream resource does not
  implement a rotation trigger and forbids updates in place. To rotate
  a credential, destroy and recreate it by **renaming the map key**
  (or changing `instance_id`/`project_id`, which is rarely what you
  want); a brief window exists where the old password stops working.
- Renaming a map key destroys and recreates the credential — new
  username and password are generated.
- Whether the API returns the password on later reads is not
  documented upstream; treat username/password as creation-only values
  and pull them from state.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs for `project_id`/`instance_id`) as forward-checking.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_logme_credential` ← `{project_id},{region},{instance_id},{credential_id}`

Upstream docs note: the provider doc import example and the `id`
attribute agree on the 4-part ID.
