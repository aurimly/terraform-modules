# stackit/volume

Map-keyed module for STACKIT block-storage volumes, optionally created
from a volume, image, snapshot or backup source, and optionally
encrypted with STACKIT KMS key encryption keys.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `volumes` | `map(object)` | — | Map of volumes keyed by an arbitrary unique ID. |

### `volumes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the volume is created in. Changing it replaces the volume. |
| `availability_zone` | `string` | — | Availability zone (e.g. `eu01-3`). Required. Changing it replaces the volume. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the volume. |
| `name` | `string` | `null` | Volume name; validated against the STACKIT name rule (1–63 characters, starts/ends with a letter or digit; spaces, `_`, `.`, `-` allowed in between). |
| `description` | `string` | `null` | Volume description, 1–127 characters. |
| `performance_class` | `string` | `null` | e.g. `storage_premium_perf1`, `storage_premium_perf2`, `storage_standard`. Changing it replaces the volume. |
| `size` | `number` | `null` | Volume size in GB. Grow-only: decreasing it forces replacement. At least one of `size` or `source` must be set. |
| `source` | `object` | `null` | Create the volume from an existing source instead of empty: `type` (`volume`, `image`, `snapshot` or `backup`) and `id` (UUID). Changing it replaces the volume. |
| `encryption_parameters` | `object` | `null` | STACKIT KMS encryption parameters, see sub-table. |
| `labels` | `map(string)` | `{}` | Labels attached to the volume. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. |

### `encryption_parameters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service_account` | `string` | — | Service account linked to the key within the STACKIT KMS. |
| `kek_keyring_id` | `string` | — | KMS keyring UUID holding the key encryption key. |
| `kek_key_id` | `string` | — | KMS key (KEK) UUID. |
| `kek_key_version` | `number` | — | KMS key version. |
| `key_payload_base64` | `string` | `null` | Base64-encoded, KMS-encrypted key payload. The write-only `key_payload_base64_wo`/`key_payload_base64_wo_version` variants require OpenTofu/Terraform >= 1.11 and are intentionally not exposed here — pass them by sourcing the provider directly if needed. |

## Outputs

`volumes` — map of volume key => object:

| Attribute | Description |
|---|---|
| `volume_id` | Volume UUID. |
| `server_id` | Server the volume is attached to, if any. |
| `size` | Resolved volume size in gigabytes. |
| `encrypted` | Whether the volume is encrypted. |
| `id` | `"{project_id},{region},{volume_id}"` — the import ID. |

## Example

```hcl
volumes = {
  "data" = {
    project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region            = "eu01"
    availability_zone = "eu01-3"
    name              = "app-data"
    size              = 100
    performance_class = "storage_premium_perf2"
    labels = {
      "env" = "prod"
    }
  }
  "from-image" = {
    project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region            = "eu01"
    availability_zone = "eu01-3"
    name              = "app-boot"
    size              = 20
    source = {
      type = "image"
      id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
  }
  "encrypted" = {
    project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region            = "eu01"
    availability_zone = "eu01-3"
    size              = 50
    encryption_parameters = {
      service_account    = "some-sa@some-project.iam.sa.stackit.cloud"
      kek_keyring_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      kek_key_id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      kek_key_version    = 1
      key_payload_base64 = "QmFzZTY0RW5jcnlwdGVkS2V5"
    }
  }
}
```

## Notes

- The IaaS (Compute Engine) service must be enabled on the STACKIT
  project before volumes can be created — unlike some other STACKIT
  services, creating IaaS resources does not auto-enable it.
- `availability_zone`, `region`, `performance_class` and `source` are
  replace-on-change. `size` is grow-only: shrinking forces replacement
  via the provider's resize modifier — extend in place by increasing
  `size`, and replace intentionally otherwise.
- `encryption_parameters` never come back from the API; they live in
  state only. Removal of the block does not decrypt an existing volume,
  but changing the parameters replaces it. The write-only
  `key_payload_base64_wo` variant is left to consumers needing
  OpenTofu/Terraform >= 1.11.
- Volumes are attached via a server's `boot_volume.source` (see
  `modules/stackit/server`) or by other means outside this module's
  scope.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_volume` ← `{project_id},{region},{volume_id}`
