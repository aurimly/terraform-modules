# hetzner/ssh_key

Map-keyed module for Hetzner Cloud SSH keys.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `ssh_keys` | `map(object)` | — | Map of SSH keys keyed by an arbitrary unique ID. |

### `ssh_keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Key name, unique per project (validated). In-place update. |
| `public_key` | `string` | — | OpenSSH public key. Changing it replaces the key. |
| `labels` | `map(string)` | `{}` | User-defined labels; keys optionally carry a `<prefix>/` prefix, values are at most 63 characters and may be empty (validated). |

## Outputs

`ssh_keys` — map of SSH key key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric SSH key ID — also the import ID. |
| `name` | Key name. |
| `public_key` | The public key material. |
| `fingerprint` | MD5 fingerprint of the public key, as computed by the API. |
| `labels` | User labels. |

Feed `id` to other modules (e.g. `hetzner/server` `ssh_keys`) as a string —
use `tonumber(...)` when a numeric key ID is required.

## Example

```hcl
module "ssh_key" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/ssh_key?ref=v0.1.0"

  ssh_keys = {
    "deploy" = {
      name       = "deploy"
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... ci@example.org"
    }
  }
}
```

## Notes

- Keys are project-global, not per-server; servers reference them by name
  or ID at create time.
- `public_key` changes destroy and recreate the key (RequiresReplace);
  the API rejects a second key with the same fingerprint per project, and
  the module mirrors that with a plan-time duplicate check.
- Map-key renames destroy and recreate the key.
- Plan-time validations mirror the API contract: cross-key `name`
  uniqueness, cross-key `public_key` uniqueness, label shape.
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_ssh_key` ← numeric SSH key ID.
