# stackit/kms_key

Map-keyed module for STACKIT KMS keys inside an existing keyring (see
stackit/kms_keyring).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `keys` | `map(object)` | — | Map of keys keyed by an arbitrary unique ID. |

### `keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the key is created in (validated). Changing it replaces the key — since destroys schedule deletion (see Notes), a replacement schedules deletion of the old key and creates a new one. |
| `keyring_id` | `string` | — | UUID of the keyring the key lives in (validated), e.g. from stackit/kms_keyring's `keyrings` output. Changing it replaces the key. |
| `display_name` | `string` | — | Display name distinguishing keys (validated non-empty). Changing it replaces the key. |
| `algorithm` | `string` | — | Encryption algorithm of the key (validated against the documented enum). Changing it replaces the key. |
| `protection` | `string` | — | Underlying system protecting the key material, e.g. `software` (not enumerated by the provider — validated non-empty only). Changing it replaces the key. |
| `purpose` | `string` | — | Purpose of the key (validated against the documented enum). Changing it replaces the key. Values: `symmetric_encrypt_decrypt`, `asymmetric_encrypt_decrypt`, `message_authentication_code`, `asymmetric_sign_verify`. |
| `access_scope` | `string` | API default (`PUBLIC`) | Access scope of the key: `PUBLIC` or `SNA` (validated). Changing it replaces the key. |
| `description` | `string` | `null` | Description distinguishing keys. Changing it replaces the key. |
| `import_only` | `bool` | API default (`false`) | Whether key versions can only be imported, not created. Updatable in place. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the key. |

## Outputs

`keys` — map of key key => object:

| Attribute | Description |
|---|---|
| `key_id` | Key ID (e.g. referenced by a service's KMS encryption config). |
| `id` | `"{project_id},{region},{keyring_id},{key_id}"` — the import ID. |

## Example

```hcl
module "kms_key" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/kms_key?ref=v1.19.0"

  keys = {
    "app-creds" = {
      project_id   = "12345678-1234-1234-1234-123456789012"
      keyring_id   = module.kms_keyring.keyrings["app-creds"].keyring_id
      display_name = "example-app-encryption-key"
      algorithm    = "aes_256_gcm"
      protection   = "software"
      purpose      = "symmetric_encrypt_decrypt"
      region       = "eu01"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **Keys are not instantly destroyed** by `terraform destroy`/`tofu
  destroy` — destroy schedules the key's deletion via the API and drops
  the resource from state; the key can be recovered within the
  grace-period window. Do not count on destroy for immediate cleanup.
- Every input except `import_only` is immutable (replace-on-change);
  as a consequence, changing e.g. `algorithm` schedules deletion of the
  old key and creates a new one.
- `algorithm`, `purpose` and `access_scope` are validated consumer-side
  against the documented values as forward-checking — the provider does
  not enumerate them plan-time and invalid values fail at apply.
- `protection` is not enumerated by the provider either (e.g. `software`
  per the provider docs); an invalid value fails at apply.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, non-empty `display_name`/`protection`) plus the enum checks
  noted above.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_kms_key` ← `{project_id},{region},{keyring_id},{key_id}`
