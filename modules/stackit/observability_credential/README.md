# stackit/observability_credential

Map-keyed module for STACKIT Observability write credentials on an
existing Observability instance (see stackit/observability_instance).

> **Import is not supported upstream** for this resource — an existing
> credential cannot be adopted into Terraform state; destroying the
> resource in Terraform is the only lifecycle end.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `credentials` | `map(object)` | — | Map of credentials keyed by an arbitrary unique ID. |

### `credentials` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance belongs to (validated). Changing it replaces the credential. |
| `instance_id` | `string` | — | ID of the Observability instance the credential is created on (e.g. from stackit/observability_instance's `instances` output, validated). Changing it replaces the credential. |
| `description` | `string` | `null` | Free description. Changing it replaces the credential (a new username and password are generated). |
| `rotate_when_changed` | `map(string)` | `null` | Rotation trigger: any change destroys and recreates the credential, producing a new API-generated password. |

There is no `region` input — the region comes solely from the
provider's configuration (unlike most sibling services, the upstream
schema has no region attribute). There are no `username` inputs either
— username and password are both API-generated.

## Outputs

`credentials` (**sensitive**) — map of credential key => object:

| Attribute | Description |
|---|---|
| `username` | API-generated username, only returned at creation. |
| `password` | API-generated password, only returned at creation. |
| `id` | `"{project_id},{instance_id},{username}"` — contains the username, not a UUID (useful for state inspection; import is not supported). |

## Example

```hcl
module "observability_credential" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/observability_credential?ref=v2.2.0"

  credentials = {
    "app" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      instance_id = module.observability_instance.instances["app-obs"].instance_id
      description = "example app write credential"
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
  they are only returned at creation. To obtain a new password,
  change `rotate_when_changed` (destroy + create; a brief window
  exists where the old password stops working). Because the output is
  sensitive, values must be pulled from the state/pipeline, not logs.
- **Changing `description` replaces the credential** — upstream marks
  it RequiresReplace, so editing the description rotates the password.
- **No region attribute** — the region is set at the provider
  configuration level only; this module takes no region input and
  exposes no region output.
- **Import is not supported upstream** (no `ResourceWithImportState`
  implementation). Renaming a map key likewise destroys and recreates
  the credential with a new username and password.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs for `project_id`/`instance_id`) as forward-checking.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

Not supported upstream — this resource does not implement import; the
`id` output value above (`{project_id},{instance_id},{username}`) is
documented for state inspection only.
