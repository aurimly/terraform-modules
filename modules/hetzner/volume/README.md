# hetzner/volume

Map-keyed module for Hetzner Cloud volumes.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `volumes` | `map(object)` | — | Map of volumes keyed by an arbitrary unique ID. |

### `volumes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Volume name, unique per project (shape and uniqueness validated). |
| `size` | `number` | — | Size in GB, 10–10240 (validated). Resizing later only grows, never shrinks. |
| `location` | `string` | null | Location name; exactly one of this or `server_id` (validated). Changing it replaces the volume. |
| `server_id` | `number` | null | Server to create attached to; the volume is created in the server's location. Detach by removing the attribute (passing `0` is not valid; validated `> 0`). |
| `automount` | `bool` | null | Only takes effect with `server_id` at creation (validated `automount ⇒ server_id`). Post-create changes have no effect. |
| `format` | `string` | null | Filesystem: `xfs` or `ext4` (validated). Create-time only; changing it later has no effect — recreate the volume instead. |
| `labels` | `map(string)` | `{}` | User-defined labels; keys optionally carry a `<prefix>/` prefix, values are at most 63 characters and may be empty (validated). |
| `delete_protection` | `bool` | null | Delete protection. |

## Outputs

`volumes` — map of volume key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric volume ID — also the import ID. |
| `name` | Volume name. |
| `size` | Size in GB. |
| `location` | Location name. |
| `server_id` | Attached server ID, or null. |
| `linux_device` | Device path on the attached server (null when unattached). |
| `delete_protection` | Whether delete protection is enabled. |
| `labels` | User labels. |

Feed `server_id` from `hetzner/server`'s `id` output via `tonumber(...)`.

## Example

```hcl
module "volume" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/volume?ref=v0.1.0"

  volumes = {
    "data-fsn" = {
      name     = "data"
      size     = 100
      location = "fsn1"
      format   = "xfs"
      labels = { env = "npd" }
    }
  }
}
```

## Notes

- When `server_id` is set the volume is created in that server's
  location; `location` must be omitted.
- Multiple volumes on one server → create additional volumes with
  `location` equal to the server's and attach them; the provider's
  `hcloud_volume_attachment` resource covers this (a future
  `hetzner/volume-attachment` module).
- `format` and `automount` are create-time only: they have no update path,
  so changing them later produces no effect and a perpetual diff — decide
  at creation and recreate to change.
- Destroy detaches the volume before deleting it.
- Map-key renames and `location` changes destroy and recreate the volume.
- Plan-time validations mirror the API contract: size bounds, name shape
  and uniqueness, exactly-one-of location/server_id, automount coupling,
  format enum, cross-key name uniqueness, label shape.
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_volume` ← numeric volume ID.
