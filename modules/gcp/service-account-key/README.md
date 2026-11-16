# gcp/service-account-key

Map-keyed module for service account keys (credentials) on existing Google
Cloud service accounts. Each entry creates one
`google_service_account_key` — the module does not create accounts (pair
with `gcp/service-account`).

The private key material is persisted in plaintext in the Terraform state
file. The upstream API offers no encrypted-delivery path (no PGP, unlike
AWS access keys) — if your state storage is not trusted, create keys
outside Terraform or accept the exposure knowingly.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `service_account_keys` | `map(object)` | — | Map of keys keyed by an arbitrary unique ID. |

Plan-time validation: `service_account` is the account email or its
resource name (a shape check — the API also accepts a bare account id
with the project inferred, and `-` as the project wildcard);
`key_algorithm`, `public_key_type` and `private_key_type`
use the API's enumerated values; `public_key_data` conflicts with
`key_algorithm` and `private_key_type` and must be base64-decodable;
`deletion_policy` is `DELETE`/`ABANDON`/`PREVENT`.

### `service_account_keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service_account` | `string` | — | The account's email (`name@project.iam.gserviceaccount.com`) or resource name (`projects/{project}/serviceAccounts/{email-or-unique-id}`). |
| `key_algorithm` | `string` | `KEY_ALG_RSA_2048` | `KEY_ALG_RSA_1024` or `KEY_ALG_RSA_2048`. Only used at creation. |
| `public_key_type` | `string` | `TYPE_X509_PEM_FILE` | `TYPE_X509_PEM_FILE` or `TYPE_RAW_PUBLIC_KEY`. |
| `private_key_type` | `string` | `TYPE_GOOGLE_CREDENTIALS_FILE` | `TYPE_GOOGLE_CREDENTIALS_FILE` or `TYPE_PKCS12_FILE`. |
| `public_key_data` | `string` | `null` | Base64 X509 PEM for bring-your-own-key. Conflicts with `key_algorithm` and `private_key_type`. |
| `keepers` | `map(string)` | `null` | Arbitrary values that, when changed, force replacement — the rotation trigger (pair with e.g. `time_rotating`). |
| `deletion_policy` | `string` | `DELETE` | `DELETE`, `ABANDON` or `PREVENT`. |

## Outputs

| Name | Description |
|---|---|
| `keys` | Map of key => `{name, public_key, private_key, valid_after, valid_before}` (sensitive). `private_key` is the base64-encoded credentials JSON — decode with `base64decode(...)` to get the file. |
| `key_names` | Map of key => key resource name (`projects/{project}/serviceAccounts/{account}/keys/{key-id}`); the bare key id is the last path segment. |

## Example

```hcl
service_account_keys = {
  "api" = {
    service_account = "api-rt@example-prj.iam.gserviceaccount.com"
    key_algorithm   = "KEY_ALG_RSA_2048"
    keepers = {
      rotation_epoch = "1"
    }
  }
}
```

## Notes

- **State warning**: `private_key` and `public_key` persist in the remote
  state in plaintext. Rotate via `keepers` changes; each rotation mints a
  replacement key with fresh credentials.
- `private_key` is only populated at creation (and on rotation) — later
  plans return it from state, not the API.
- `key_algorithm` is used at creation only; changing it replaces the key.
- Deleting an entry destroys the key and its credentials stop working.
  Keys created outside Terraform cannot be adopted (import is not
  supported) — either keep managing them outside Terraform, or create
  fresh keys here and retire the old ones (keys are additive per
  account; nothing conflicts).
- The caller needs IAM permissions to create/list/delete service account
  keys on the target accounts.

## Import

Not supported — `google_service_account_key` cannot be imported.
