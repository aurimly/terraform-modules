# stackit/secrets_manager

Map-keyed module for STACKIT Secrets Manager instances.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance is created in (validated). |
| `name` | `string` | — | Instance name, at least 1 character (validated). |
| `acls` | `set(string)` | `null` | Access control list for the instance: each entry is an IP or IP range permitted to access, in CIDR notation (validated). |
| `kms_key` | `object` | `null` | STACKIT KMS key for secret encryption/decryption; see the `kms_key` object table. |

### `kms_key` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `key_id` | `string` | — | UUID of the key within the STACKIT KMS to use for the encryption (validated). |
| `key_ring_id` | `string` | — | UUID of the keyring where the key is located (validated). |
| `key_version` | `number` | — | Version of the key within the STACKIT KMS, at least 1 (validated). |
| `service_account_email` | `string` | — | Service account linked to the key within the STACKIT KMS. |

## Outputs

`instances` — map of instance key => object:

| Attribute | Description |
|---|---|
| `instance_id` | Instance UUID. |
| `id` | `"{project_id},{instance_id}"` — the import ID. |

## Example

```hcl
module "secrets_manager" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/secrets_manager?ref=v1.3.0"

  instances = {
    "app" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-app"
      acls       = ["10.0.0.0/8"]
    }
    "kms-encrypted" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-kms"
      kms_key = {
        key_id                = "87654321-4321-8765-4321-210987654321"
        key_ring_id           = "11111111-2222-3333-4444-555555555555"
        key_version           = 1
        service_account_email = "example-key@serviceaccount.project.iam.stackit.cloud"
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- Users and credentials are managed via stackit/secrets_manager_user;
  this module exposes no credentials or instance URL.
- The resource has no `region` attribute — the region comes from the
  provider configuration at the consumer's unit level, which must set
  one or the apply fails provider-side.
- `acls` gates API access to the instance; `kms_key` links a STACKIT KMS
  key used for secret encryption.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, name length, ACL CIDR notation); the `kms_key` UUID and
  version checks are forward-checking beyond the provider's validators.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_secretsmanager_instance` ← `{project_id},{instance_id}`
