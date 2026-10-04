# hetzner/rdns

Map-keyed module for Hetzner Cloud reverse DNS (rDNS) entries: one PTR
record per entry, set on an IP belonging to a server, primary IP,
floating IP or load balancer.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `rdns_entries` | `map(object)` | — | Map of rDNS entries keyed by an arbitrary unique ID. |

### `rdns_entries` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ip_address` | `string` | — | IP address that should point to `dns_ptr`; a valid IPv4 or IPv6 address (validated). Changing it replaces the entry. |
| `dns_ptr` | `string` | — | Domain name `ip_address` should point to. Updating it rewrites the PTR in place. Removing an entry clears the PTR. |
| `server_id` | `number` | null | Server the IP belongs to. Positive ID (validated). Exactly one of the four target IDs must be set (validated). Changing it replaces the entry. |
| `primary_ip_id` | `number` | null | Primary IP the IP belongs to. Same rules as `server_id`. |
| `floating_ip_id` | `number` | null | Floating IP the IP belongs to. Same rules as `server_id`. |
| `load_balancer_id` | `number` | null | Load balancer the IP belongs to. Same rules as `server_id`. |

## Outputs

`rdns_entries` — map of rDNS entry key => object:

| Attribute | Description |
|---|---|
| `id` | Composite string `"<prefix>-<resource ID>-<ip_address>"` with prefixes `s` (server), `p` (primary IP), `f` (floating IP), `l` (load balancer) — also the import ID. |
| `ip_address` | The IP address holding the PTR. |
| `dns_ptr` | The domain name the IP points to. |
| `server_id` | Server target, when set. |
| `primary_ip_id` | Primary IP target, when set. |
| `floating_ip_id` | Floating IP target, when set. |
| `load_balancer_id` | Load balancer target, when set. |

Feed IDs into the target attributes from sibling module outputs
(`hetzner/server`, `hetzner/primary_ip`, `hetzner/floating_ip`,
`hetzner/load_balancer`) as strings — use `tonumber(...)` where a
numeric value is required.

## Example

```hcl
module "rdns" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/rdns?ref=v0.1.0"

  rdns_entries = {
    "web-v4" = {
      ip_address = module.server.servers["web-fsn"].ipv4_address
      dns_ptr    = "web.example.com"
      server_id  = tonumber(module.server.servers["web-fsn"].id)
    }
    "edge-v4" = {
      ip_address     = module.floating_ip.floating_ips["edge-fsn"].ip_address
      dns_ptr        = "edge.example.com"
      floating_ip_id = tonumber(module.floating_ip.floating_ips["edge-fsn"].id)
    }
    "lb-v4" = {
      ip_address       = module.load_balancer.load_balancers["main"].ipv4
      dns_ptr          = "lb.example.com"
      load_balancer_id = tonumber(module.load_balancer.load_balancers["main"].id)
    }
  }
}
```

## Notes

- One PTR exists per (resource, IP): the module rejects entries that
  duplicate the same (target kind, target ID, `ip_address`) triple because
  their writes would silently overwrite each other and drift. The API
  itself accepts duplicate entries — the guard is module-level. The same
  IP addressed via different resources (e.g. a server and its primary
  IP) conflicts the same way but is not plan-detectable here.
- Replace surface: all four target IDs and `ip_address` are replace-only;
  `dns_ptr` updates in place. Map-key renames recreate the entry.
- IPv6 floating/primary IPs cover a /64 — one entry per address that
  needs a PTR.
- Keys are arbitrary unique identifiers, not names.
- Plan-time validations mirror the provider's validators and the known
  API contract (target exactly-one-of and positive IDs, IP shape); the
  duplicate-triple check is the module's own consistency guard and there
  is no `dns_ptr` format validation — the provider has none and the API
  contract is unverified.
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_rdns` ← the composite ID, e.g. `s-4711-203.0.113.10` (server),
`p-4711-2001:db8::1` (primary IP), `f-4711-203.0.113.7` (floating IP),
`l-4711-203.0.113.25` (load balancer).
