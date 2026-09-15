# stackit/kms_keyring

Map-keyed module for STACKIT KMS keyrings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `keyrings` | `map(object)` | — | Map of keyrings keyed by an arbitrary unique ID. |

### `keyrings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the keyring is created in (validated). Changing it replaces the keyring — since keyrings are not destroyed (see Notes), a change is only a state removal plus a new keyring. |
| `display_name` | `string` | — | Display name distinguishing keyrings (validated non-empty). Changing it replaces the keyring. |
| `description` | `string` | `null` | Description distinguishing keyrings. Changing it replaces the keyring. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the keyring. |

## Outputs

`keyrings` — map of keyring key => object:

| Attribute | Description |
|---|---|
| `keyring_id` | Auto-generated keyring UUID (e.g. referenced by stackit/kms_key's `keyring_id`). |
| `id` | `"{project_id},{region},{keyring_id}"` — the import ID. |

## Example

```hcl
module "kms_keyring" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/kms_keyring?ref=v1.19.0"

  keyrings = {
    "app-creds" = {
      project_id   = "12345678-1234-1234-1234-123456789012"
      display_name = "example-app-credentials"
      description  = "keyring for the payments app"
      region       = "eu01"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **Keyrings are not destroyed** by `terraform destroy`/`tofu destroy` —
  the resource is only removed from state, the keyring itself stays
  alive on the API side indefinitely. Do not count on destroy for
  cleanup, and do not be surprised by leftover keyrings. (The recovery
  grace period the provider docs mention applies to keys, not to the
  keyring's lifetime.)
- Every input is immutable (replace-on-change); as a consequence the
  keyring listed in the state changes but no keyring is ever deleted.
- Use stackit/kms_key for the keys inside the keyring, feeding
  `keyring_id` from this module's `keyrings` output.
- Plan-time validations mirror the provider's plan-time validators
  (UUID for `project_id`) plus a non-empty `display_name` check as
  forward-checking.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_kms_keyring` ← `{project_id},{region},{keyring_id}`
