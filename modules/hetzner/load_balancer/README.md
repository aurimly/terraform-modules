# hetzner/load_balancer

Map-keyed module for Hetzner Cloud load balancers: the balancer, its
services (HTTP/HTTPS/TCP with health checks and sticky sessions), its
targets (server, label selector or IP) and optional private-network
attachments, all in one entry.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `load_balancers` | `map(object)` | — | Map of load balancers keyed by an arbitrary unique ID. Map keys at every level must not contain `__` (the module composes internal resource keys from them; validated). |

### `load_balancers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Load balancer name: 1–128 characters, no leading/trailing whitespace, unique per project (all validated). Changing it updates in place. |
| `load_balancer_type` | `string` | — | Load balancer type, e.g. `lb11`. In-place. |
| `location` | `string` | null | Location name (`fsn1`, `nbg1`, `hel1`, …). Exactly one of `location` or `network_zone` (validated). ForceNew. |
| `network_zone` | `string` | null | Network zone (`eu-central`, `us-east`). Exactly one of `location` or `network_zone` (validated). ForceNew. |
| `algorithm` | `string` | null | `round_robin` (API default) or `least_connections` (validated) — the only values the API defines. In-place. |
| `labels` | `map(string)` | `{}` | User-defined labels; keys optionally carry a `<prefix>/` prefix, values are at most 63 characters and may be empty (validated). |
| `delete_protection` | `bool` | null | Delete protection. |
| `networks` | `map(object)` | `{}` | Private-network attachments, keyed by an arbitrary ID — see below. |
| `services` | `map(object)` | `{}` | Services (listener + forwarding rules), keyed by an arbitrary ID — see below. |
| `targets` | `map(object)` | `{}` | Targets, keyed by an arbitrary ID — see below. |

### `load_balancers.networks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `network_id` | `number` | null | Network to attach. Exactly one of `network_id` or `subnet_id` per entry (validated — the provider rejects both). Without `subnet_id` the balancer attaches to the **last subnet ordered by `ip_range`**. `network_id`, `subnet_id` and `ip` are replace-only: changing them destroys and recreates the attachment. |
| `subnet_id` | `string` | null | `<network_id>-<subnet ip range>`, e.g. `4711-10.0.1.0/24` (format validated). Preferred over `network_id` alone. |
| `ip` | `string` | null | Private IP to assign to the balancer (IPv4/IPv6 validated). |
| `enable_public_interface` | `bool` | null | Whether the balancer's public interface is enabled (API default `true`). Balancer-level property — entries of one balancer that set it must agree with the default (unset counts as `true`; validated). Updates in place (unlike the other attachment attributes, which are replace-only). `false` makes the balancer private-only: without an attachment it is unreachable. |

### `load_balancers.services` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `protocol` | `string` | — | `http`, `https` or `tcp` (validated). ForceNew. |
| `listen_port` | `number` | protocol default | Port clients connect to; API defaults are 80 (`http`) and 443 (`https`); required for `tcp` (validated). 1–65535 (validated). Must be unique per balancer — the API enforces it and the module mirrors it counting the defaults (validated). ForceNew. |
| `destination_port` | `number` | null | Port on the targets; required for `tcp` (validated). 1–65535 (validated). In-place. |
| `proxyprotocol` | `bool` | null | Enable proxyprotocol via HAProxy for the service. In-place. |
| `http` | `object` | null | HTTP settings block — see below. Only valid when `protocol` is `http` or `https` (validated); for `https`, `certificates` must be non-empty (the API rejects certificate-less HTTPS; validated). |
| `health_check` | `object` | null | Health check block — see below. Omit entirely for API defaults (TCP check on the service port). |

### `services.http` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `sticky_sessions` | `bool` | null | Use sticky sessions. In-place. |
| `cookie_name` | `string` | null | Cookie name for sticky sessions. |
| `cookie_lifetime` | `number` | null | Cookie lifetime in seconds, 30–86400 (validated). |
| `certificates` | `list(number)` | `[]` | Certificate IDs terminating TLS for `https` services (IDs of certificates managed outside this module; positive-ID style — required non-empty for `https`, validated). |
| `redirect_http` | `bool` | null | Redirect requests from HTTP port 80 to this service; only valid for `protocol = "https"` (validated). Typically set on the port-443 service — the API accepts it with the default listen port (443). |
| `timeout_idle` | `number` | null | Idle connection timeout in seconds, 30–300 (validated). |

### `services.health_check` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `protocol` | `string` | — | `http`, `https` or `tcp` (validated — mirrors the provider validator; `https` health checks exist in the API even though older doc pages list only two). |
| `port` | `number` | — | Port to check, 1–65535 (validated). Required whenever a health check block is present (the provider schema requires it unconditionally, despite doc phrasing suggesting tcp-only). |
| `interval` | `number` | — | Interval in seconds, 3–60 (validated; API schema bounds). |
| `timeout` | `number` | — | Timeout in seconds, 1–60 (validated; API schema bounds). |
| `retries` | `number` | — | Unsuccessful retries before a target is marked unhealthy, 1–5 (validated; API schema bounds). |
| `http` | `object` | null | HTTP health check details — see below. Required when `protocol` is `http` or `https` (validated — mirrors the documented API contract; the provider schema alone would let it through and fail at apply). |

### `services.health_check.http` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `domain` | `string` | null | Host header to send. |
| `path` | `string` | null | Path to request. |
| `response` | `string` | null | Response substring to expect. |
| `tls` | `bool` | null | Perform the check over TLS. |
| `status_codes` | `list(string)` | `[]` | Status codes considered healthy, e.g. `["2xx", "3xx"]`. |

### `load_balancers.targets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `server`, `label_selector` or `ip` (validated); must agree with exactly one of the attributes below (validated). |
| `server_id` | `number` | null | Server ID to target — required for `type = "server"` (positive, validated). ForceNew. Feed it from `hetzner/server` outputs with `tonumber(...)`. |
| `label_selector` | `string` | null | Label selector expression — required for `type = "label_selector"`. Resolved by the API at runtime: targets come and go as server labels change without touching this resource. ForceNew. |
| `ip` | `string` | null | IP to target — required for `type = "ip"` (server or dedicated-server IPs). ForceNew. |
| `use_private_ip` | `bool` | null | Use the target's private IP; only valid for `server` and `label_selector` targets (conflicts with `type = "ip"`, validated). |

## Outputs

`load_balancers` — map of load balancer key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric load balancer ID — also the import ID. |
| `name` | Load balancer name. |
| `load_balancer_type` | Load balancer type. |
| `location` | Location name (null when created with `network_zone`). |
| `network_zone` | Network zone (null when created with `location`). |
| `ipv4` | Public IPv4 address. |
| `ipv6` | Public IPv6 address. |
| `algorithm` | Balancing algorithm in effect. |
| `labels` | User labels. |
| `delete_protection` | Whether delete protection is enabled. |
| `network_id` | ID of the first attached private network, or null. |
| `network_ip` | The balancer's private IP in that network, or null. |

`service_ids` — map of `<load balancer key>__<service key>` => service ID
`<load balancer ID>__<listen port>` (also the import ID).

`target_ids` — map of `<load balancer key>__<target key>` => the target's
internal provider ID (generated, e.g. `lb-srv-tgt-<server id>-<load balancer
id>`; hash-based for label selectors and IPs). Import takes the compound
form `<load balancer ID>__<type>__<identifier>` instead — this output is
for state and tooling reference, not `tofu import`.

Feed `id` to other modules as a string — use `tonumber(...)` where a
numeric value is required.

## Example

```hcl
module "load_balancer" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/load_balancer?ref=v0.1.0"

  load_balancers = {
    "edge" = {
      name               = "edge"
      load_balancer_type = "lb11"
      location           = "fsn1"

      services = {
        "https" = {
          protocol      = "https"
          proxyprotocol = true
          http = {
            certificates  = [4711]
            redirect_http = true
          }
          health_check = {
            protocol = "http"
            port     = 80
            interval = 15
            timeout  = 10
            retries  = 3
            http = {
              path         = "/healthz"
              status_codes = ["2xx", "3xx"]
            }
          }
        }
      }

      targets = {
        "webservers" = {
          type           = "label_selector"
          label_selector = "role=web"
        }
      }
    }

    "tcp-passthrough" = {
      name               = "tcp-passthrough"
      load_balancer_type = "lb11"
      network_zone       = "eu-central"

      networks = {
        "priv" = { subnet_id = "4711-10.0.1.0/24" }
      }

      services = {
        "postgres" = {
          protocol         = "tcp"
          listen_port      = 5432
          destination_port = 5432
          health_check = {
            protocol = "tcp"
            port     = 5432
            interval = 15
            timeout  = 10
            retries  = 3
          }
        }
      }

      targets = {
        "db" = {
          type           = "server"
          server_id      = tonumber(module.server.servers["db-1"].id)
          use_private_ip = true
        }
      }
    }
  }
}
```

## Notes

- Map-key renames destroy and recreate. Renaming a **service or target
  key** recreates only that service/target. Renaming a **load balancer
  key** (or changing `location`/`network_zone`) recreates the balancer,
  and because services/targets/attachments reference its ID, the whole
  set cascades — new balancer and compound service/target IDs, brief
  downtime.
- Replace surface: services — `protocol`, `listen_port` (and the
  balancer reference) are ForceNew, the rest updates in place; targets —
  `server_id`/`label_selector`/`ip` are ForceNew; network attachments —
  `network_id`/`subnet_id`/`ip` are replace-only, `enable_public_interface`
  updates in place; balancer — `location`/`network_zone`
  are ForceNew, everything else in place.
- Keys are arbitrary identifiers; the module only requires they not
  contain `__`, which it uses to compose internal resource keys and
  which also appears in the provider's import IDs.
- TLS termination is `protocol = "https"` with `certificates`. TLS
  passthrough has no dedicated API option — use `protocol = "tcp"` on
  port 443.
- Label-selector targets are resolved by the API at runtime; servers
  matching the selector join/leave the balancer without a Terraform
  change.
- `use_private_ip = true` requires the balancer and the target to share
  a private network (see `networks` and `hetzner/server` `network`).
- Plan-time validations mirror the provider's validators and the
  documented API contract — including two places where the module is
  stricter than the provider schema on purpose (`health_check.port`
  required whenever a health check is set; `health_check.http` required
  for http/https health checks) because the relaxed provider schema
  would otherwise fail at apply. Numeric bounds (name length, health
  check interval/timeout/retries, cookie lifetime) follow the API
  schema; report anything the API accepts here that this module
  rejects.
- Services, targets and attachments are separate provider resources
  keyed `"<load balancer key>__<entry key>"`; composite IDs are exposed
  via `service_ids`/`target_ids`.
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

- `hcloud_load_balancer` ← numeric load balancer ID.
- `hcloud_load_balancer_service` ← `<load balancer ID>__<listen port>`.
- `hcloud_load_balancer_target` ← `<load balancer ID>__<type>__<identifier>`
  (a label selector containing `__` still imports — the provider splits
  at most three parts).
- `hcloud_load_balancer_network` ← `<load balancer ID>-<network ID>`.
