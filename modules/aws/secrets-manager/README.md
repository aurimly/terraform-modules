# aws/secrets-manager

Map-keyed module for Secrets Manager secrets: optional in-Terraform
version payload, multi-region replicas, recovery windows, KMS encryption,
and optional rotation schedules.

## Destroy semantics (read before using)

- Destroying a secret **schedules deletion** of the primary after
  `recovery_window_in_days` (default 30; `0` = immediate and
  unrecoverable).
- **Replicas are destroyed immediately and permanently on destroy.**
  AWS refuses to delete a primary that still has replicas, so the
  provider removes all replicas first via `RemoveRegionsFromReplication`
  (no recovery window — replica data is gone at once) and only then
  schedules the primary deletion. Only the primary is recoverable within
  its recovery window.
- Removing a single `replicas` entry from config deletes just that
  replica, also immediately and permanently (same API, no recovery
  window).
- Version destroy: if `AWSCURRENT` is staged on the version, the label
  cannot be removed on delete — the version stays active until the
  secret itself is deleted or the label moves (provider note).
- Removing `rotation` cancels the schedule; an in-flight rotation can
  leave `AWSPENDING` on a partial version (provider note).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `secrets` | `map(object)` | `{}` | Map of secrets keyed by an arbitrary unique ID. |

### `secrets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Secret name, 1–512 chars of alphanumerics and `/_+=.@-` (validated). Set this **or** `name_prefix` (precondition). Immutable; changing replaces the secret. |
| `name_prefix` | `string` | — | Prefix for a provider-generated unique name (up to 486 chars, validated; leaves room for the generated suffix under the 512-char limit). |
| `description` | `string` | — | Secret description. |
| `kms_key_id` | `string` | — | KMS key ARN/ID for primary encryption; omit for the account default `aws/secretsmanager` key. Per-replica keys go in `replicas.*.kms_key_id` and must exist in the target region — see Notes. |
| `recovery_window_in_days` | `number` | `30` | Scheduled-deletion window: `0` (immediate, unrecoverable) or `7`–`30` (validated). |
| `force_overwrite_replica_secret` | `bool` | provider default `false` | Overwrite a same-named secret already present in a replica region (recreate path). |
| `type` | `string` | — | Managed-external partner secret type (doc-listed values such as `SalesforceClientSecret`); deliberately not an enum so new partner types never break the module. Immutable after create. Provider floor 6.57.1 — the attribute is written unconditionally, so any non-empty `secrets` map needs `hashicorp/aws >= 6.57.1` (keep pins at the consumer root). |
| `secret_string` | `string` | — | Text payload for the Terraform-managed version. XOR with `secret_binary` (validated). Lands in state — see Notes. |
| `secret_binary` | `string` | — | Base64-encoded binary payload. XOR with `secret_string` (validated). |
| `version_stages` | `list(string)` | AWS default `["AWSCURRENT"]` | Staging labels for the managed version; omitted → AWS moves `AWSCURRENT` to the new version on creation. Requires a payload (validated), entries non-empty (validated); a label already attached to another version of the secret is silently moved to this one. Include `AWSCURRENT` for a lone version or expect a perpetual diff. Do **not** combine with `rotation` — see Notes. |
| `replicas` | `map(object)` | `{}` | Replica regions keyed by arbitrary ID; each entry becomes a `replica` block (`region`, optional `kms_key_id`). See the `replicas` object table. |
| `rotation` | `object` | — | `{rotation_lambda_arn, rotate_immediately, rotation_rules}` — presence attaches an `aws_secretsmanager_secret_rotation`. See the `rotation` object table. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `replicas` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | — | Replica region, shape-validated (`^[a-z0-9-]{1,32}$`) — not a list of valid regions. Must differ from the provider's primary region (AWS rejects a replica in the secret's own region). |
| `kms_key_id` | `string` | — | KMS key for this replica; must exist in the replica Region (any symmetric CMK created there, or a multi-Region key replicated into it). Omit for the replica Region's `aws/secretsmanager` key. |

### `rotation` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `rotation_lambda_arn` | `string` | — | Rotation Lambda function ARN (validated `^arn:`). The module never creates the Lambda. |
| `rotate_immediately` | `bool` | provider default `true` | Rotate on apply — **immediate credential invalidation** for anything not yet reading from Secrets Manager. Set `false` to wait for the next scheduled window instead; the Lambda still runs `testSecret` once at enable-time (see Notes). Provider floor 5.33.0. |
| `rotation_rules` | `object` | — | Required. See the `rotation_rules` object table. |

### `rotation_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `automatically_after_days` | `number` | — | Fixed interval in days, 1–1000 (validated). Exactly one of this or `schedule_expression` (validated — RotateSecret rejects both). |
| `schedule_expression` | `string` | — | `cron(...)` or `rate(...)` expression (prefix-validated). Exactly one of this or `automatically_after_days` (validated). |
| `duration` | `string` | — | Rotation window duration matching `[0-9]{1,2}h` (validated); requires `schedule_expression` (validated) — the window starts per the schedule. |

## Outputs

`secret_arns` — map of secret key => secret ARN.
`secret_names` — map of secret key => resolved name (the provider fills
the generated name for `name_prefix` entries).
`secret_version_ids` — map of secret key => version ID for entries that
carry a payload (absent for out-of-band entries).

Replica ARNs are not exported by the provider (only replication status),
so there is no replica output.

## Example

```hcl
secrets = {
  "db-password" = {
    name                    = "example-db-password"
    description             = "example database password"
    recovery_window_in_days = 7
    secret_string           = jsonencode({ engine = "postgres", host = "example.db", username = "app", password = "example-value" })
    replicas = {
      "eu-west-1" = { region = "eu-west-1" }
      "us-east-1" = { region = "us-east-1" }
    }
    rotation = {
      rotation_lambda_arn = "arn:aws:lambda:eu-central-1:111111111111:function:example-rotation"
      rotation_rules = {
        automatically_after_days = 30
      }
    }
    tags = {
      Environment = "example"
    }
  }
  "api-key" = {
    name = "example-api-key"
    # payload omitted — version managed out of band
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not secret names.
- `secret_string`/`secret_binary` are stored by value in Terraform state
  (the provider's sensitivity marking redacts CLI output only — it does
  not remove them from state). Omit both fields to manage versions wholly
  out of band (the provider's write-only `secret_string_wo` is not
  exposed — same stance as the gcp module's `secret_data`).
- **Enabling rotation rotates the secret immediately on apply**
  (`rotate_immediately` defaults to `true`) — every consumer of the
  credentials must already read from Secrets Manager or break. The
  rotation Lambda must exist first, must live in the secret's primary
  region (Secrets Manager invokes it through the regional Lambda API),
  must allow `secretsmanager.amazonaws.com` to invoke it, and the
  payload must be the JSON credential structure the rotation Lambda
  expects (engine/host/username/password per the AWS rotation docs) —
  not merely a free-form string. The module never creates the Lambda; pair
  `aws/lambda` + `aws/iam-role`. The version resource is ordered before
  the rotation resource so the initial payload exists before the first
  `RotateSecret` call. Even with `rotate_immediately = false`, Secrets
  Manager runs the Lambda's `testSecret` step at enable-time (creating
  and removing an `AWSPENDING` version) to verify the configuration —
  the Lambda must be functional and invocable on apply either way.
- Managed-external partner secrets (`type`) cannot configure rotation
  through this module: partner rotation is driven by
  `external_secret_rotation_role_arn` + partner metadata, which are not
  exposed, while this module's `rotation` requires `rotation_lambda_arn`
  — the combination is rejected at apply. Omit `rotation` on `type`
  entries.
- Do not set `version_stages` on a secret that also has `rotation` in
  this module: the Lambda moves `AWSCURRENT` to each new rotated version,
  so an explicit `version_stages` containing `AWSCURRENT` on the
  Terraform version will fight every rotation. For a lone managed
  version, include `AWSCURRENT` or expect a perpetual diff (provider
  note).
- `kms_key_id` omitted → account default `aws/secretsmanager` key. A
  per-replica `kms_key_id` must simply exist in the replica Region — a
  single-Region CMK created there or a multi-Region key replicated into
  it both work, because replication decrypts the primary and re-encrypts
  with the replica-Region key (the keys need not be related); omitted →
  the replica Region's `aws/secretsmanager`. Replicating a
  CMK-encrypted secret also needs `kms:Decrypt` on the primary key and
  `kms:GenerateDataKey`/`kms:Encrypt` on the replica key, in addition to
  `secretsmanager:ReplicateSecretToRegions`.
- `force_overwrite_replica_secret` covers recreating a replica where a
  same-named secret already exists in that region.
- `type` is immutable after create; values are the doc-listed partner
  types, not an enum in the module. The attribute floors the module at
  `hashicorp/aws >= 6.57.1` regardless of whether `type` is set (the
  provider rejects unknown arguments even when null).
- Secret names may not end in `-` + six chars (AWS ARN-confusion
  warning — accepted by the API, just unwise).
- Resource policies (`aws_secretsmanager_secret_policy`) and the
  secret-level `policy` attribute are out of scope; the attribute's
  removal semantics interact with the separate policy resource in a
  foot-gun-y way (`"{}"` clears).
- `rotation_enabled` (the flag that disables AWS-managed rotation on
  secrets this module does not create, e.g. RDS
  `manage_master_user_password` secrets) is out of scope for the same
  reason; and destroying a rotation resource never re-enables rotation
  that AWS itself configured.
- Changing `name` or `name_prefix` forces replacement; with the default
  30-day window the old secret enters recovery while replicas and tags
  carry over.

## Import

`aws_secretsmanager_secret` ← secret ARN.
`aws_secretsmanager_secret_version` ← `<secret-arn>|<version-id>`.
`aws_secretsmanager_secret_rotation` ← secret ARN.
