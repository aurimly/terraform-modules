# hetzner/network

Map-keyed module for Hetzner Cloud networks.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `networks` | `map(object)` | — | Map of networks keyed by an arbitrary unique ID. |

### `networks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Network name, unique per project, 1–255 characters (validated). |
| `ip_range` | `string` | — | Overall IPv4 range, a private RFC1918 CIDR (validated). Changing it replaces the network. The range can only be extended after creation, never reduced. |
| `labels` | `map(string)` | `{}` | User-defined labels; keys optionally carry a `<prefix>/` prefix, values are at most 63 characters and may be empty (validated). |
| `delete_protection` | `bool` | null | Delete protection. |
| `expose_routes_to_vswitch` | `bool` | null | Expose routes to the vSwitch connection (only takes effect with an active vSwitch). |

## Outputs

`networks` — map of network key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric network ID — also the import ID. |
| `ip_range` | Overall IPv4 range. |
| `labels` | User labels. |
| `delete_protection` | Whether delete protection is enabled. |
| `expose_routes_to_vswitch` | Whether routes are exposed to the vSwitch. |

## Example

```hcl
module "network" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/network?ref=v0.1.0"

  networks = {
    "nz-fsn" = {
      name     = "nz-fsn"
      ip_range = "10.0.0.0/16"
      labels = { env = "npd" }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- Subnets (`hcloud_network_subnet`) and routes (`hcloud_network_route`)
  are separate resources downstream; this module only creates the network
  container.
- `ip_range` and the internal subnets must be within one RFC1918 range
  (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16).
- Map-key renames and `ip_range` changes destroy and recreate the
  network, orphaning attached subnets and server IPs.
- Plan-time validations mirror the provider's validators (RFC1918 range,
  name bounds, cross-key name uniqueness, label shape).
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_network` ← numeric network ID.
