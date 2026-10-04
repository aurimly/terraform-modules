# hetzner/primary_ip

Map-keyed module for Hetzner Cloud primary IPs: dedicated public
IPv4/IPv6 addresses created unassigned in a location, or created
assigned to a server.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `primary_ips` | `map(object)` | — | Map of primary IPs keyed by an arbitrary unique ID. |

### `primary_ips` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name, unique per project (validated). In-place. |
| `type` | `string` | — | `ipv4` or `ipv6` (validated). Changing it replaces the IP. |
| `location` | `string` | null | Location name (`fsn1`, `nbg1`, `hel1`, `ash`, `hil`, `sin`); the IP is created unassigned there. Exactly one of `location`/`assignee_id` must be set (validated). Changing it replaces the IP. The provider's `datacenter` attribute is removed upstream (hard error) — not exposed here. |
| `assignee_id` | `number` | null | Server the IP is created on and assigned to; requires `assignee_type` (validated) and must be `> 0` (validated). Changing it reassigns in place (the server must be powered off and have no primary IP of that type — API errors `server_not_stopped`, `server_has_ipv4`, `server_has_ipv6` otherwise). |
| `assignee_type` | `string` | null | Assignee type; validated to `server` (the API's only supported value). Required when `assignee_id` is set; when set without `assignee_id` it is ignored — the provider only warns, don't set it. |
| `auto_delete` | `bool` | null | Delete the IP when its assignee is deleted. The provider warns against `true`: the IP would be deleted out-of-band with the server, breaking state. |
| `delete_protection` | `bool` | null | Delete protection. |
| `labels` | `map(string)` | `{}` | User-defined labels; values at most 63 characters, may be empty (validated). |

## Outputs

`primary_ips` — map of primary IP key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric primary IP ID (import ID). |
| `name` | Primary IP name. |
| `type` | `ipv4` or `ipv6`. |
| `ip_address` | Single IP address. |
| `ip_network` | IPv6 /64 network; only set for `ipv6` (null for `ipv4`). |
| `location` | Location name. |
| `assignee_id` | Assigned server ID; reads `0` in state until the next refresh when assignment happened server-side. |
| `assignee_type` | `server` when assigned; unassigned IPs read back `unassigned` (API change of 2026-08-01). |
| `auto_delete` | Whether auto delete is enabled. |
| `delete_protection` | Whether delete protection is enabled. |
| `labels` | User labels. |

Feed `id` to other modules (`hetzner/server` `public_net.ipv4/ipv6`,
`hetzner/rdns` `primary_ip_id`) as a string — use `tonumber(...)` where
a numeric value is required.

## Example

```hcl
module "primary_ip" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/primary_ip?ref=v0.1.0"

  primary_ips = {
    "edge-v4" = {
      name     = "edge-v4"
      type     = "ipv4"
      location = "fsn1"
      labels = { role = "edge" }
    }
    "edge-v6" = {
      name          = "edge-v6"
      type          = "ipv6"
      assignee_id   = tonumber(module.server.servers["web-fsn"].id)
      assignee_type = "server"
    }
  }
}

# Alternative: attach by ID server-side instead
#   servers = { "web-fsn" = { …
#     public_net = { ipv4 = tonumber(module.primary_ip.primary_ips["edge-v4"].id) } } }
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **Removing `assignee_id`/`assignee_type` from an entry does not
  unassign the IP** — those attributes are Optional+Computed upstream
  and keep their state value, so the change is a no-op diff artifact, not
  an unassignment. Unassign by changing the server side (e.g. the
  server's `public_net`) instead.
- When a server attaches the IP via its own `public_net`, the IP's
  `assignee_id` in state only reflects it after the next refresh.
- A primary IP can only be assigned to resources in the same location;
  the assignee server must be powered off and free of a primary IP
  of that type at apply time (API errors `server_not_stopped`,
  `server_has_ipv4`, `server_has_ipv6` are surfaced on apply).
- `auto_delete = true` deletes the IP with its assignee server — the
  provider's own warning applies: avoid it, it breaks state.
- Plan-time validations mirror the provider's validators and the API
  contract (type enum, exactly-one-of location/assignee, assignee
  coupling, assignee_type enum, positive IDs, name uniqueness, label
  shape); `assignee_type` alone is accepted because the provider only
  warns and ignores it.
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_primary_ip` ← numeric primary IP ID.
