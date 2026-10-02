# hetzner/placement_group

Map-keyed module for Hetzner Cloud placement groups.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `placement_groups` | `map(object)` | — | Map of placement groups keyed by an arbitrary unique ID. |

### `placement_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Placement group name, unique per project (validated). In-place update. |
| `type` | `string` | — | Only `spread` is supported (validated); it cannot be changed after creation. |
| `labels` | `map(string)` | `{}` | User-defined labels; keys optionally carry a `<prefix>/` prefix, values are at most 63 characters and may be empty (validated). |

## Outputs

`placement_groups` — map of placement group key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric placement group ID — also the import ID. |
| `name` | Placement group name. |
| `labels` | User labels. |
| `servers` | Member server IDs as strings. Sorted lexically for determinism, not numerically (`10` sorts before `2`). |

Feed `id` to `hetzner/server` (`placement_group_id`) as a string — use
`tonumber(...)` when a numeric value is required.

## Example

```hcl
module "placement_group" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/placement_group?ref=v0.1.0"

  placement_groups = {
    "pg-euw" = {
      name = "pg-euw"
      type = "spread"
      labels = { env = "npd" }
    }
  }
}
```

## Notes

- Spread groups keep the member servers as far apart as possible from each
  other on the cloud infrastructure.
- Documentation limits: max 10 servers per spread group and max 50
  placement groups per project.
- Adding a server to a placement group and removing it both require the
  server to be powered off (`server_not_stopped` is documented for the
  add path; the removal guard comes from the provider and Hetzner docs —
  see the `hetzner/server` README for the same restriction on inline
  placement group changes).
- Map-key renames destroy and recreate the group.
- Plan-time validations mirror the API contract: `spread`-only type,
  cross-key name uniqueness, label shape.
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_placement_group` ← numeric placement group ID.
