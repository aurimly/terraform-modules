# stackit/service_account_key

Map-keyed module for STACKIT service account keys (credential key files
for service accounts).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `service_account_keys` | `map(object)` | — | Map of service account keys keyed by an arbitrary unique ID. |

### `service_account_keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the service account lives in. Changing it replaces the key. |
| `service_account_email` | `string` | — | Full service account email (e.g. from the stackit/service_account module's output `email`). Changing it replaces the key. |
| `public_key` | `string` | `null` | RSA2048 public key to embed in the key instead of a provider-generated key pair (BYOK). Changing it replaces the key. The provider does not validate the PEM shape; a malformed key fails at the API. |
| `ttl_days` | `number` | API default (no expiry) | Key validity in days, at least 1. Changing it replaces the key. |
| `rotate_when_changed` | `map(string)` | `null` | Arbitrary key/value map; changing any value replaces the key, enabling rotation (e.g. pipe a `time_rotating` resource's `rfc3339` into it). |

## Outputs

`service_account_keys` — map of service account key => object:

| Attribute | Description |
|---|---|
| `key_id` | Key UUID. |
| `id` | `"{project_id},{service_account_email},{key_id}"` — the provider's resource identifier. |
| `json` | Credentials JSON (the key file contents), usable as e.g. a `GOOGLE_APPLICATION_CREDENTIALS`-style credential for STACKIT tooling. Only available at creation. |

## Example

```hcl
service_account_keys = {
  "ci-bot" = {
    project_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    service_account_email = "ci-bot-aBc2defg@sa.stackit.cloud"
  }
  "ci-bot-rotating" = {
    project_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    service_account_email = "ci-bot-hIj3klmn@sa.stackit.cloud"
    ttl_days              = 90
    rotate_when_changed = {
      rotation_epoch = "2026-01-01"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers.
- The `json` output is only available at creation: the provider does not
  re-read the key JSON on refresh. If the Terraform/Terragrunt state is
  lost, the JSON is unrecoverable — the key must be replaced (e.g. by
  changing `rotate_when_changed`). Store it immediately (e.g. in a
  secrets manager) if downstream consumers need it after apply.
- Keys are not importable: existing keys cannot be adopted into this
  module, whether created by Terraform state loss or out of band. To
  rotate a key at a known cadence, create it here with
  `rotate_when_changed` wired to something like a `time_rotating`
  trigger.
- All attributes are create-only (the provider sets `RequiresReplace()`
  on them): changing `project_id`, `service_account_email`,
  `public_key`, `ttl_days`, or any `rotate_when_changed` value replaces
  the key. Renaming a map key has the same effect (the resource address
  changes).
- `public_key` must be an RSA2048 public key when set; a generated key
  pair is used otherwise.
- Deleted service accounts invalidate their keys; the stackit/service_account
  module's notes cover the lifecycle on that side.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against.
- Provider authentication is configured at the consumer's unit level.
