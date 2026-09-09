# gcp/kms

Map-keyed module for Google Cloud KMS key rings, crypto keys, and IAM bindings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `keyrings` | `map(object)` | — | Map of key rings keyed by an arbitrary unique ID. |

### `keyrings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Key ring name, 1–63 chars; letters, digits, `_`, `-` (validated). Immutable; changing forces replacement. |
| `location` | `string` | — | Key ring location: a region (`us-central1`), `us`, `eu`, or `global`. Immutable. |
| `project_id` | `string` | — | Project the key ring lives in; defaults to the provider-level project. Format validated. |
| `keys` | `map(object)` | `{}` | Crypto keys in this key ring, keyed by an arbitrary ID; see the `keys` object table. |
| `role_bindings` | `map(object)` | `{}` | IAM bindings on the key ring; see the `role_bindings` object table. |

### `keyrings.keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Crypto key name, 1–63 chars; letters, digits, `_`, `-` (validated). Immutable. |
| `purpose` | `string` | `ENCRYPT_DECRYPT` | One of `ENCRYPT_DECRYPT`, `ASYMMETRIC_SIGN`, `ASYMMETRIC_DECRYPT`, `RAW_ENCRYPT_DECRYPT`, `MAC`, `KEY_ENCAPSULATION`, `AES_WRAPPING` (validated). Immutable. There are no `HARDWARE_*` purposes — hardware-backed keys use `version_template.protection_level = "HSM"`. |
| `rotation_period` | `string` | — | Auto-rotation period, seconds-suffixed (e.g. `86400s`), minimum one day (validated). Required for `MAC` keys. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `version_template` | `object` | — | `{algorithm, protection_level}` for new key versions. `algorithm` required (e.g. `GOOGLE_SYMMETRIC_ENCRYPTION`, `HMAC_SHA256`, `RSA_SIGN_PKCS1_3072_SHA256`); `protection_level` one of `SOFTWARE`, `HSM`, `EXTERNAL`, `EXTERNAL_VPC` (validated). |
| `destroy_scheduled_duration` | `string` | — | DESTROY_SCHEDULED dwell time, seconds-suffixed, 24h–120h (`86400s`–`432000s`, validated). Immutable. |
| `import_only` | `bool` | — | Key may contain imported versions only. Immutable. |
| `skip_initial_version_creation` | `bool` | — | Create the key without an initial version (versions come from `google_kms_crypto_key_version` or import jobs). |
| `deletion_policy` | `string` | — | One of `DELETE` (default), `PREVENT`, `ABANDON` (validated). `PREVENT` makes destroy fail — recommended for production data keys, since destroying a crypto key renders previously encrypted data irrecoverable. |
| `role_bindings` | `map(object)` | `{}` | IAM bindings on this crypto key; same shape as the key ring table. |

### `role_bindings` object (key ring and key level)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/cloudkms.cryptoKeyEncrypterDecrypter`. Must be unique per key ring / per key (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role. |

## Outputs

`keyring_ids` — map of keyring key => fully-qualified key ring id
(`projects/.../locations/.../keyRings/...`).
`crypto_key_ids` — map of composite key (`keyring key/key key`) => fully-qualified
crypto key id (`projects/.../keyRings/.../cryptoKeys/...`) — the value to pass to
`gcp/bucket` `encryption.default_kms_key_name`, `gcp/artifact-registry`
`kms_key_name`, or `gcp/filestore` `kms_key_name`.
`crypto_key_names` — map of composite key => short crypto key name.
`keyring_binding_roles` — map of key ring binding composite key => role.
`crypto_key_binding_roles` — map of crypto key binding composite key => role.

## Example

```hcl
keyrings = {
  "app" = {
    name     = "example-app"
    location = "us-central1"

    keys = {
      "gcs" = {
        name            = "example-app-gcs"
        purpose         = "ENCRYPT_DECRYPT"
        rotation_period = "7776000s" # 90 days
        deletion_policy = "PREVENT"
      }
    }

    role_bindings = {
      "admins" = {
        role    = "roles/cloudkms.admin"
        members = ["group:example-kms-admins@example.com"]
      }
    }
  }
}
```

Then, in the consumer unit, bind the project's GCS service agent to the key so
`gcp/bucket` CMEK works (this needs a data source the module does not have, so it
stays consumer-side):

```hcl
data "google_storage_project_service_account" "gcs" {
  project = "example-project-1234"
}

resource "google_kms_crypto_key_iam_member" "gcs_cmek" {
  crypto_key_id = module.kms.crypto_key_ids["app/gcs"]
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — key rings share the
  project namespace, crypto keys the key ring namespace; the key only decouples your
  config from the names.
- Pair with `gcp/project-services` (`cloudkms.googleapis.com`) when the target project
  does not have the KMS API enabled yet; this module does not enable APIs itself.
- Crypto keys reference their key ring by the ring's fully-qualified id, so
  `project_id` does not need to be set explicitly for key/key-ring wiring to resolve
  (it only steers where the key ring is created).
- IAM bindings are authoritative per role (`..._iam_binding`): members you omit are
  removed from that role. Use `google_kms_crypto_key_iam_member` consumer-side when
  another resource's identity must be granted access without claiming the role (the
  GCS example above).
- Key rings, key names, `purpose`, `import_only` and `destroy_scheduled_duration`
  are immutable — changing them replaces the key (and destroying a key in use
  breaks the resources encrypting with it; keep `deletion_policy = PREVENT` on
  production data keys). `rotation_period` is updatable in place.
- `MAC` keys require `rotation_period` and an `HMAC_*` algorithm in
  `version_template`; `ASYMMETRIC_*` purposes require `version_template.algorithm`.

## Import

`google_kms_key_ring` ←
`projects/{project}/locations/{location}/keyRings/{name}`.
`google_kms_crypto_key` ←
`projects/{project}/locations/{location}/keyRings/{key_ring}/cryptoKeys/{name}`.
`google_kms_key_ring_iam_binding` ← space-delimited
`{key_ring_id} roles/{role}`.
`google_kms_crypto_key_iam_binding` ← space-delimited
`{crypto_key_id} roles/{role}`.
