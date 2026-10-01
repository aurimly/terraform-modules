# hetzner/floating_ip

Map-keyed module for Hetzner Cloud floating IPs.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `floating_ips` | `map(object)` | — | Map of floating IPs keyed by an arbitrary unique ID. |

### `floating_ips` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `ipv4` or `ipv6` (validated). |
| `name` | `string` | null | Name. |
| `home_location` | `string` | null | Home location name (e.g. `fsn1`); the IP is created unassigned. Exactly one of `home_location`/`server_id` must be set (validated). Changing it replaces the floating IP. |
| `server_id` | `number` | null | Server the IP is created on and assigned to. Exactly one of `home_location`/`server_id` must be set (validated); must be `> 0` (validated). Updating it reassigns in place; removing it unassigns the IP. |
| `description` | `string` | null | Description. |
| `labels` | `map(string)` | `{}` | User-defined labels; values at most 63 characters, may be empty (validated). |
| `delete_protection` | `bool` | null | Delete protection. |

## Outputs

`floating_ips` — map of floating IP key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric floating IP ID (import ID). |
| `type` | `ipv4` or `ipv6`. |
| `ip_address` | Single IP address. |
| `ip_network` | IPv6 /64 subnet; only set for `ipv6` (null for `ipv4`). |
| `home_location` | Home location. |
| `server_id` | Assigned server, if any. |
| `name` | Floating IP name. |
| `delete_protection` | Whether delete protection is enabled. |
| `labels` | User labels. |

## Example

```hcl
module "floating_ip" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/floating_ip?ref=v0.1.0"

  floating_ips = {
    "edge-fsn" = {
      type          = "ipv4"
      home_location = "fsn1"
      description   = "edge entry point"
      labels = { role = "edge" }
    }
    "edge-hel" = {
      type      = "ipv6"
      server_id = 42
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- Consumers feeding the numeric ID into other hcloud resources
  (e.g. `firewall_ids`, `hcloud_server`) must convert it back:
  `tonumber(module.floating_ip.floating_ips["edge-fsn"].id)`.
- `home_location` replaces the IP; `server_id` reassigns in place, and
  removing it unassigns the IP.
- Plan-time validations mirror the provider's validators (type enum,
  exactly-one-of home/server, positive server_id, label shape).
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_floating_ip` ← numeric floating IP ID.
