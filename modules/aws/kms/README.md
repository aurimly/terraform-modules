# aws/kms

Map-keyed module for KMS keys: AWS-generated key material, rotation with
optional custom period, multi-region primaries, optional policy document,
and aliases attached to managed keys.

## Destroy semantics (read before using)

- Destroying the module **schedules key deletion** for
  `deletion_window_in_days` (default 30). The key is recoverable within
  the window, after which deletion is permanent and data encrypted under
  it becomes unreadable unless re-encrypted first.
- Aliases are deleted immediately with the module.
- A key whose `policy` locks out root cannot be deleted unless
  `bypass_policy_lockout_safety_check` is set — do not set it casually.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `keys` | `map(object)` | `{}` | Map of keys keyed by an arbitrary unique ID. Map keys must not contain `.` (composite output keys; validated). |

### `keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `description` | `string` | — | Key description. |
| `key_usage` | `string` | `ENCRYPT_DECRYPT` | One of `ENCRYPT_DECRYPT`, `SIGN_VERIFY`, `GENERATE_VERIFY_MAC`, `KEY_AGREEMENT` (validated). HMAC specs require `GENERATE_VERIFY_MAC`. |
| `customer_master_key_spec` | `string` | `SYMMETRIC_DEFAULT` | One of `SYMMETRIC_DEFAULT`, `HMAC_224/256/384/512`, `RSA_2048/3072/4096`, `ECC_NIST_P256/P384/P521`, `ECC_SECG_P256K1`, `ECC_NIST_EDWARDS25519`, `ML_DSA_44/65/87` (validated). |
| `is_enabled` | `bool` | `true` | Whether the key is enabled. |
| `enable_key_rotation` | `bool` | `false` | Automatic annual rotation. Symmetric-encryption keys only (validated). |
| `rotation_period_in_days` | `number` | — | Custom rotation period, 90–2560 days (validated); requires `enable_key_rotation = true` on a `SYMMETRIC_DEFAULT` key. |
| `deletion_window_in_days` | `number` | `30` | Scheduled-deletion window (7–30 days). |
| `multi_region` | `bool` | `false` | Create a multi-region primary key (`mrk-` key-ID prefix). |
| `policy` | `string` | — | JSON key policy document (validated JSON). Omit for the AWS default key policy. |
| `bypass_policy_lockout_safety_check` | `bool` | `false` | Skip the policy lockout safety check — dangerous; pair only with a fully understood policy. |
| `aliases` | `map(object)` | `{}` | Aliases attached to **this key**; each entry is `{name = "alias/..."}`. Names must match KMS alias rules, must not start with `alias/aws/` (validated) and must be unique across the whole input map (aliases are region-unique). |
| `tags` | `map(string)` | `{}` | Tags; passed through unchanged (KMS keys have no name attribute). |

### `aliases` object

| Attribute | Type | Description |
|---|---|---|
| `name` | `string` | Full alias name starting with `alias/`, followed by 1–250 characters of alphanumerics, forward slashes, underscores and hyphens (validated). |

## Outputs

`key_ids` — map of key key => key ID.
`key_arns` — map of key key => key ARN.
`alias_arns` — map of `"key-key.alias-key"` => alias ARN.
`alias_names` — map of `"key-key.alias-key"` => alias name.

## Example

```hcl
keys = {
  "app" = {
    description             = "example app data encryption"
    enable_key_rotation     = true
    deletion_window_in_days = 15
    aliases = {
      "main" = { name = "alias/example-app" }
    }
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not key names. KMS keys have no
  name attribute; aliases are the human-facing names, and `tags` is passed
  through without a `Name` merge.
- With `policy` omitted, AWS attaches the default key policy (account
  root keeps full control). Pass a policy only for cross-account or
  scoped access.
- Rotation (both `enable_key_rotation` and `rotation_period_in_days`)
  exists for symmetric encryption keys only; HMAC and asymmetric keys are
  never auto-rotated (validated).
- `rotation_period_in_days` is a newer provider attribute (floor ~5.49);
  no in-module version constraint — pins stay at the consumer's root.
- Multi-region keys are created as primaries (`mrk-` key-ID prefix).
  Replica keys (`aws_kms_replica_key`) and external/imported key material
  (`aws_kms_external_key`) are out of scope; manage them consumer-side.
- Pairing: feed `key_arns` into `aws/s3-bucket` encryption,
  `aws/sns` `kms_master_key_id`, `aws/sqs` encryption, `aws/rds`
  encryption, `aws/lambda` `kms_key_arn` and `aws/ecs-cluster`
  execute-command `kms_key_id`.

## Import

`aws_kms_key` ← key ID or key ARN.
`aws_kms_alias` ← alias name (`alias/name`).
