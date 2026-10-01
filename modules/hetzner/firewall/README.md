# hetzner/firewall

Map-keyed module for Hetzner Cloud firewalls, including rules and the
resources they are applied to.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `firewalls` | `map(object)` | — | Map of firewalls keyed by an arbitrary unique ID. |

### `firewalls` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Firewall name, unique per project, 1–128 characters (validated). |
| `labels` | `map(string)` | `{}` | User-defined labels; values at most 63 characters, may be empty (validated). |
| `rules` | `list(object)` | `[]` | Firewall rules, up to 50 entries (validated). See below. |
| `apply_to` | `list(object)` | `[]` | Resources to attach the firewall to. Each entry sets exactly one of `server` (positive server ID) or `label_selector` (validated). |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `direction` | `string` | — | `in` or `out` (validated). |
| `protocol` | `string` | — | `tcp`, `udp`, `icmp`, `gre` or `esp` (validated). |
| `port` | `string` | null | `any`, a single port, or a range like `80-85` (validated). Required for `tcp`/`udp`, forbidden otherwise (validated). |
| `source_ips` | `list(string)` | `[]` | Allowed IPs/CIDRs for `in`; up to 100 entries with an explicit prefix (validated; single host = `/32` IPv4, `/128` IPv6). |
| `destination_ips` | `list(string)` | `[]` | Allowed IPs/CIDRs for `out` — only meaningful when `direction = "out"` (validated); up to 100 entries. |
| `description` | `string` | null | Rule description, at most 255 characters (validated). |

## Outputs

`firewalls` — map of firewall key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric firewall ID (import ID). |
| `applied_to` | Provider `apply_to` objects. `label_selector` reads back empty when the firewall is attached to a server directly and `server` reads back 0 for label-selector attachments — expect one of the two to be empty. |

## Example

```hcl
module "firewall" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/firewall?ref=v0.1.0"

  firewalls = {
    "web" = {
      name = "web"
      rules = [
        {
          direction  = "in"
          protocol   = "icmp"
          source_ips = ["0.0.0.0/0", "::/0"]
        },
        {
          direction  = "in"
          protocol   = "tcp"
          port       = "80-85"
          source_ips = ["0.0.0.0/0", "::/0"]
        },
        {
          direction       = "out"
          protocol        = "udp"
          port            = "any"
          destination_ips = ["203.0.113.0/24"]
        }
      ]
      apply_to = [{ label_selector = "role = web" }]
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- API limits: up to 50 rules per firewall (500 effective), 100 CIDR
  blocks per source/destination list; these are also enforced at plan
  time.
- The module requires the explicit CIDR prefix on
  `source_ips`/`destination_ips` (`/32`, `/128` for single hosts), which
  is stricter than the provider, where bare IPs are normalized.
- `port` rules: `any` may be used to allow all ports for a protocol; the
  port value is shape-validated only (no numeric bounds), mirroring the
  API.
- Consumers feeding the numeric ID into other resources (e.g.
  `hcloud_server.firewall_ids`) must convert it:
  `tonumber(module.firewall.firewalls["web"].id)`.
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_firewall` ← numeric firewall ID.
