# cloudflare/load-balancer

Map-keyed module for Cloudflare load balancing: health monitors and origin
pools at account level, load balancers at zone level, with monitor and pool
attachment done by module key.

Monitors and pools are account-scoped (`account_id`); load balancers are
zone-scoped — one module instance per account, with `zone_id` as a
fallback for single-zone consumers or a per-load-balancer `zone_id` for
multi-zone ones. Researched against provider 5.24.0; the
`required_providers` floor stays the repo-wide `>= 5.0.0`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | — | Cloudflare account ID owning the monitors and pools. |
| `zone_id` | `string` | `""` | Fallback zone ID used when a load balancer omits its own. |
| `monitors` | `map(object)` | `—` | Health monitors, keyed by an arbitrary unique ID. |
| `pools` | `map(object)` | `—` | Origin pools, keyed by an arbitrary unique ID. |
| `load_balancers` | `map(object)` | `—` | Load balancers, keyed by an arbitrary unique ID. |

### `monitors` object

All attributes optional (the API defaults them).

| Attribute | Type | Description |
|---|---|---|
| `type` | `string` | `http`, `https`, `tcp`, `udp_icmp`, `icmp_ping`, or `smtp`. |
| `method` | `string` | Defaults to `GET` for HTTP(S), `connection_established` for TCP. |
| `path` | `string` | Endpoint path (HTTP/HTTPS only). |
| `port` | `number` | Required for TCP/UDP-ICMP/SMTP; HTTP(S) only when non-default. |
| `expected_codes` | `string` | e.g. `"2xx"` (HTTP/HTTPS). |
| `expected_body` | `string` | Case-insensitive substring (HTTP/HTTPS). |
| `header` | `map(list(string))` | Request headers, e.g. `{ Host = ["example.com"] }` — set a `Host` header by default (HTTP/HTTPS). |
| `interval` | `number` | Seconds between checks. |
| `retries` | `number` | Retries before marking the origin unhealthy. |
| `timeout` | `number` | Seconds before a check fails. |
| `consecutive_up` | `number` | Successes required to mark the origin healthy. |
| `consecutive_down` | `number` | Failures required to mark it unhealthy. |
| `allow_insecure` | `bool` | Skip cert validation (HTTPS). |
| `follow_redirects` | `bool` | HTTP/HTTPS. |
| `probe_zone` | `string` | Emulate probing for a specific zone (HTTP/HTTPS). |
| `description` | `string` | — |

### `pools` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Pool tag; alphanumeric, hyphens, underscores. |
| `origins` | `list(object)` | — | Ordered origins — see below. |
| `monitor` | `string` | `null` | Key into the `monitors` map. |
| `monitor_group` | `string` | `null` | Raw monitor-group ID (groups are outside this module). |
| `minimum_origins` | `number` | `null` | Healthy origins required before the pool serves traffic. |
| `check_regions` | `list(string)` | `null` | Regions running health checks; null = every data center. |
| `health_sources` | `list(string)` | `null` | Only `null` or exactly `["regional", "global"]` is accepted (null behaves like `["local", "global"]`). |
| `enabled` | `bool` | `null` | Disabled pools receive no traffic and fail over their users immediately. |
| `description` | `string` | `null` | — |
| `notification_email` | `string` | `null` | Deprecated upstream — prefer Cloudflare's centralized notifications. |
| `notification_filter` | `object` | `null` | `origin` / `pool` objects each with `disable` and `healthy` bools. |
| `origin_steering` | `object` | `null` | `policy`: `random`, `hash`, `least_outstanding_requests`, `least_connections`. |
| `load_shedding` | `object` | `null` | `default_percent`, `default_policy`, `session_percent`, `session_policy`. |
| `latitude`, `longitude` | `number` | `null` | Data center coordinates; set both or neither. |

### `origins` items (ordered list)

| Attribute | Type | Description |
|---|---|---|
| `address` | `string` | IP or hostname of the origin. |
| `name` | `string` | Human-readable name. |
| `port` | `number` | Origin port. |
| `weight` | `number` | Relative weight. |
| `enabled` | `bool` | Exclude an origin from selection without removing it. |
| `flatten_cname` | `bool` | Resolve CNAME origins to A/AAAA (default true). |
| `header` | `object` | `host` — list of host header values. |
| `virtual_network_id` | `string` | Private-network scope for encrypted origins. |

The list is order-semantic (failover within the pool follows position).
Ordering drift is handled by the provider, which reorders API responses back
to plan order — a list input is safe here.

### `load_balancers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | DNS hostname to steer. Takes precedence over an existing DNS record on it. |
| `default_pools` | `list(string)` | — | Ordered pool keys — failover priority. |
| `fallback_pool` | `string` | — | Pool key used when all default pools are unhealthy. |
| `zone_id` | `string` | `null` | Zone for this LB; falls back to the module-level `zone_id`. One of the two must be set. |
| `proxied` | `bool` | `null` | Orange-cloud the hostname (recommended; `ttl` only applies when unproxied). |
| `ttl` | `number` | `null` | DNS TTL — only meaningful with `proxied = false`. |
| `steering_policy` | `string` | `null` | `off`, `geo`, `dynamic_latency`, `random`, `proximity`, `least_outstanding_requests`, `least_connections`. |
| `session_affinity` | `string` | `null` | `none`, `cookie`, `ip_cookie`, `header` (uses `session_affinity_attributes.headers`). |
| `session_affinity_attributes` | `object` | `null` | `drain_duration`, `headers`, `require_all_headers`, `samesite`, `secure`, `zero_downtime_failover`. |
| `session_affinity_ttl` | `number` | `null` | Seconds until a session may expire. |
| `region_pools` / `pop_pools` / `country_pools` | `map(list(string))` | `null` | Region / PoP / country ⇒ ordered pool keys (pop_pools is Enterprise). |
| `adaptive_routing` | `object` | `null` | `failover_across_pools` bool. |
| `location_strategy` | `object` | `null` | `mode`, `prefer_ecs` (non-proxied request steering). |
| `random_steering` | `object` | `null` | `default_weight`, `pool_weights` (pool key ⇒ weight) — with `steering_policy = "random"` or `least_outstanding_requests`. |
| `description` | `string` | `null` | — |
| `enabled` | `bool` | `null` | — |
| `networks` | `list(string)` | `null` | Networks the LB is enabled on. |

## Outputs

- `monitor_ids`, `pool_ids`, `load_balancer_ids` — keyed by input key.

## Notes

- **Key references, not raw IDs.** `pools[].monitor` is a key into
  `monitors`; `load_balancers[].default_pools`, `fallback_pool`, the
  region/pop/country maps, and `random_steering.pool_weights` carry pool
  keys. The module resolves them, and the resulting resource references
  create destroy-ordering edges: Cloudflare refuses to delete a pool still
  referenced by a load balancer (or a monitor still used by a pool), so
  applying children-before-parents and destroying parents-before-children
  matter. Adopting pre-existing pools/monitors into this module also
  imports their load balancers — importing a LB into the map while its
  pools stay outside breaks destroy ordering.
- **One owner per load balancer.** LB custom `rules` (a beta provider
  feature) are out of scope. If you manage a load balancer's rules with the
  raw resource, manage the whole LB resource with the raw resource too —
  two owners of the same object fight each other.
- `pool_ids` is the chaining point for stacks that must reference pool
  IDs outside this module (do not parse `load_balancer_ids`-adjacent
  state by hand).

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"
zone_id    = "023e105f4ecef8ad9ca31a8372d0c354"

monitors = {
  "http" = {
    type           = "https"
    path           = "/healthz"
    expected_codes = "2xx"
  }
}

pools = {
  "eu" = {
    name = "example-eu"
    origins = [
      { address = "203.0.113.10", name = "one" },
      { address = "203.0.113.11", name = "two" },
    ]
    monitor = "http"
  }
}

load_balancers = {
  "api" = {
    name          = "api.example.com"
    default_pools = ["eu"]
    fallback_pool = "eu"
    proxied       = true
  }
}
```

## Import

| Resource | Import ID |
|---|---|
| `cloudflare_load_balancer_monitor` | `<account_id>/<monitor_id>` |
| `cloudflare_load_balancer_pool` | `<account_id>/<pool_id>` |
| `cloudflare_load_balancer` | `<zone_id>/<lb_id>` |

The generated docs page shows a three-part LB import ID
(`<zone>/<zone_id>/<lb_id>`); the provider code takes the two-part form
above. Verify against the installed provider version before relying on it.
