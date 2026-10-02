# hetzner/server

Map-keyed module for Hetzner Cloud servers.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `servers` | `map(object)` | — | Map of servers keyed by an arbitrary unique ID. |

### `servers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Server name: a valid RFC 1123 hostname, unique per project (both validated). Changing it updates the server in place. |
| `server_type` | `string` | — | Server type, e.g. `cx22`. In-place: the provider powers the server off, changes the type, and powers it back on. |
| `image` | `string` | — | Image name or ID (`ubuntu-24.04`, …). The provider marks it optional only for import flows — creating a server without it fails, so this module requires it. Changing it replaces the server. |
| `location` | `string` | null | Location name (`fsn1`, `nbg1`, `hel1`, …); omit to let the API pick. Changing it replaces the server. The provider's `datacenter` attribute is deprecated and erroring upstream — not exposed here. |
| `user_data` | `string` | null | Cloud-init data, at most 32 KiB (validated on characters, not bytes). Changing it replaces the server; the state stores only its hash. Pass it via `sensitive()` when it embeds secrets. |
| `ssh_keys` | `list(string)` | `[]` | SSH key names or IDs injected at create. Non-empty entries (validated). Changing the list replaces the server. |
| `keep_disk` | `bool` | null | Keep the disk when upgrading the server type (allows type downgrades). |
| `backups` | `bool` | null | Enable automatic backups. In-place. |
| `labels` | `map(string)` | `{}` | User-defined labels; keys optionally carry a `<prefix>/` prefix, values are at most 63 characters and may be empty (validated). |
| `public_net` | `object` | null | Public network config: `ipv4_enabled` (bool, default true), `ipv6_enabled` (bool, default true), `ipv4` (existing primary IPv4 ID), `ipv6` (existing primary IPv6 ID). An ID assigned while its enable flag is `false` is rejected (in-place updates can't do that; validated). Omit the block entirely → IPv4 and IPv6 are auto-generated. |
| `network` | `list(object)` | `[]` | Inline private-network attachments: `network_id` (network ID, required unless `subnet_id`), `subnet_id` (`<network_id>-<ip range>`, e.g. `4711-10.0.1.0/24`), `ip` (specific private IP), `alias_ips`. Prefer `subnet_id` over `network_id` alone (subnet selection without it may be unpredictable). Attachments to a subnet created in the same apply need `depends_on`. |
| `firewall_ids` | `list(number)` | `[]` | Firewall IDs applied to the server. In-place. Positive IDs (validated). |
| `ignore_remote_firewall_ids` | `bool` | null | Ignore firewalls added outside of this resource (diff-suppression knob for firewalls managed elsewhere). |
| `placement_group_id` | `number` | null | Placement group to add the server to (positive ID, validated). Removing a running server from a placement group fails (`server_not_stopped`). |
| `delete_protection` | `bool` | null | Delete protection. |
| `rebuild_protection` | `bool` | null | Rebuild protection; when changing both protections in one apply the provider requires them to match. |
| `shutdown_before_deletion` | `bool` | null | Gracefully shut down before destroy. |
| `iso` | `string` | null | ISO ID or name to mount. In-place, but triggers a reboot. |
| `rescue` | `string` | null | Rescue system type (`linux64` is currently the only documented value; provider docs still mention `linux32` while the API spec does not — no enum validation for that reason). In-place, but triggers a reboot. |

## Outputs

`servers` — map of server key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric server ID — also the import ID. |
| `name` | Server name. |
| `server_type` | Server type. |
| `image` | Image name or ID (as stored by the API). |
| `location` | Location name. |
| `status` | Server status (`running`, …). |
| `labels` | User labels. |
| `ipv4_address` | Primary IPv4 address, or null when disabled. |
| `ipv6_address` | First host address of the primary IPv6 /64, or null when disabled. |
| `ipv6_network` | Primary IPv6 /64 network, or null when disabled. |
| `primary_disk_size` | Primary disk size in GB. |
| `delete_protection` | Whether delete protection is enabled. |
| `rebuild_protection` | Whether rebuild protection is enabled. |

`user_data` is intentionally not output — the state holds only its SHA1
hash, never the value.

Feed `id` to other modules (`hetzner/volume` `server_id`,
`hetzner/floating_ip` `server_id`) as a string — use `tonumber(...)`
where a numeric value is required.

## Example

```hcl
module "server" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/server?ref=v0.1.0"

  servers = {
    "web-fsn" = {
      name        = "web-fsn"
      server_type = "cx22"
      image       = "ubuntu-24.04"
      location    = "fsn1"
      user_data   = file("cloud-init.yaml")
      ssh_keys    = ["deploy"]
      labels = { env = "npd" }
    }
  }
}
```

## Notes

- Map-key renames destroy and recreate the server.
- Replace surface: `image`, `location`, `user_data`, `ssh_keys` are
  ForceNew; everything else updates in place. `server_type` changes power
  the server off, resize, and power it back on.
- A server needs at least one network interface to power on: disabling
  both public IPs requires an inline `network` attachment.
- Spread placement groups are limited to 10 servers per group and 50
  groups per project (Hetzner docs) — see `hetzner/placement_group`.
  `server_not_stopped` is documented for adding a server to a placement
  group; removal of a running server is additionally guarded by the
  provider.
- `public_net` and `network` are provider blocks — this module collapses
  `public_net` to a single object (the API supports one public-net config)
  and takes `network` as a list of attachment objects.
- The API enforces name uniqueness per project; the module mirrors it with
  a plan-time duplicate check, plus RFC 1123 hostname shape.
- `image` is required here even though the provider marks it optional —
  the provider only relaxes it so imported server configs stay valid;
  creation without an image fails. When importing an existing server, read
  its image from the state first (see Import).
- Plan-time validations mirror the provider's validators and API contract
  (hostname shape, name/user_data bounds, network attach rules, primary IP
  coupling, positive IDs, label shape).
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_server` ← numeric server ID. Since `image` is required, the
imported configuration must be completed with the server's image before
the next refresh/plan succeeds.
