# stackit/load_balancer

Map-keyed module for STACKIT load balancers with listeners, target pools,
and targets.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `load_balancers` | `map(object)` | — | Map of load balancers keyed by an arbitrary unique ID. |

### `load_balancers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 1–63 characters; must not contain a comma (the import ID is comma-joined) — both validated. |
| `project_id` | `string` | — | STACKIT project UUID the load balancer is created in (validated). |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the load balancer. |
| `plan_id` | `string` | API default (`p10`) | One of `p10`, `p50`, `p250`, `p750` (validated). In-place update. |
| `external_address` | `string` | `null` | Public IP the load balancer is reachable on (e.g. from stackit/public_ip). Mutually exclusive with `options.private_network_only = true` — exactly one of the two is required (validated). Changing it replaces the load balancer. |
| `disable_security_group_assignment` | `bool` | API default (`false`) | Whether the load balancer's security group is not auto-assigned to targets. Immutable after create. |
| `options` | `object` | `null` | See the `options` object table. |
| `network` | `object` | — | The single network the load balancer attaches to; see the `network` object table. Exactly one network is supported upstream; changing it replaces the load balancer. |
| `listeners` | `map(object)` | — | 1–20 listeners (validated); see the `listeners` object table. |
| `target_pools` | `map(object)` | — | 1–20 target pools (validated); see the `target_pools` object table. |

### `options` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `private_network_only` | `bool` | `null` | Set `true` for a private-only load balancer; then `external_address` must be unset. |
| `acl` | `set(string)` | `null` | CIDR allowlist, IPv4 or IPv6 entries (validated). |
| `observability` | `object` | `null` | `{logs = {credentials_ref, push_url}, metrics = {credentials_ref, push_url}}` — log/metrics shipping to a credentials group. Immutable after create. |

### `network` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `network_id` | `string` | — | STACKIT network UUID (e.g. from stackit/network's `networks` output), validated as a UUID. |
| `role` | `string` | — | One of `ROLE_LISTENERS_AND_TARGETS`, `ROLE_LISTENERS`, `ROLE_TARGETS`, `ROLE_UNSPECIFIED` (validated). Required by the provider. |

### `listeners` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `port` | `number` | — | Listener port. |
| `protocol` | `string` | — | One of `PROTOCOL_TCP`, `PROTOCOL_UDP`, `PROTOCOL_TCP_PROXY`, `PROTOCOL_TLS_PASSTHROUGH`, `PROTOCOL_UNSPECIFIED` (validated). |
| `target_pool` | `string` | — | Name of a `target_pools` entry in the same load balancer (validated). |
| `display_name` | `string` | `null` | Human-readable name. |
| `tcp` | `object` | `null` | `{idle_timeout}` — TCP idle timeout in seconds as a duration string (e.g. `"90s"`), at most 3600 (validated). |
| `udp` | `object` | `null` | `{idle_timeout}` — UDP idle timeout in the same format, at most 120 (validated). |

### `target_pools` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Pool name; listeners reference it via `target_pool`. Must be unique within the load balancer (validated). |
| `target_port` | `number` | — | Port targets receive traffic on. |
| `targets` | `map(object)` | — | 1–1000 targets per pool (validated); entries are `{display_name, ip}` with a valid IPv4/IPv6 `ip` (validated). |
| `active_health_check` | `object` | `null` | `{healthy_threshold, interval, interval_jitter, timeout, unhealthy_threshold}`; durations as strings (e.g. `"5s"`). |
| `session_persistence` | `object` | `null` | `{use_source_ip_address}`. |

## Outputs

`load_balancers` — map of load balancer key => object:

| Attribute | Description |
|---|---|
| `private_address` | The load balancer's private VIP. Transient: it can change on replacement — do not hardcode it. |
| `security_group_id` | Security group UUID assigned to the load balancer's targets (auto-assigned unless `disable_security_group_assignment`). |
| `load_balancer_security_group_id` | Security group UUID of the load balancer itself; allow it in target-side security groups when targets live outside the load balancer's network (see stackit/security_group). |
| `version` | Load balancer version reported by the API. |
| `id` | `"{project_id},{region},{name}"` — the import ID. |

## Example

```hcl
module "load_balancer" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/load_balancer?ref=v1.3.0"

  load_balancers = {
    "public" = {
      project_id       = "12345678-1234-1234-1234-123456789012"
      name             = "example-public-lb"
      region           = "eu01"
      plan_id          = "p10"
      external_address = "198.51.100.10"
      network = {
        network_id = "87654321-4321-8765-4321-210987654321"
        role       = "ROLE_LISTENERS_AND_TARGETS"
      }
      listeners = {
        "https" = {
          port        = 443
          protocol    = "PROTOCOL_TCP"
          target_pool = "web"
          tcp = {
            idle_timeout = "90s"
          }
        }
      }
      target_pools = {
        "web" = {
          name        = "web"
          target_port = 8443
          targets = {
            "node-1" = { display_name = "example-node-1", ip = "10.1.0.10" }
            "node-2" = { display_name = "example-node-2", ip = "10.1.0.11" }
          }
          active_health_check = {
            healthy_threshold   = 2
            interval            = "5s"
            timeout             = "2s"
            unhealthy_threshold = 3
          }
        }
      }
    }
    "internal" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-internal-lb"
      region     = "eu01"
      options = {
        private_network_only = true
      }
      network = {
        network_id = "87654321-4321-8765-4321-210987654321"
      }
      listeners = {
        "tcp" = {
          port        = 8080
          protocol    = "PROTOCOL_TCP"
          target_pool = "app"
        }
      }
      target_pools = {
        "app" = {
          name        = "app"
          target_port = 8080
          targets = {
            "node-1" = { display_name = "example-node-1", ip = "10.1.0.10" }
          }
        }
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- Exactly one network per load balancer (provider limit); it is set at
  create and changing it replaces the load balancer.
- Public vs private: set `external_address` or
  `options.private_network_only = true` — exactly one of the two,
  validated at plan time (mirrors the provider rule).
- Replace/immutable attributes: `external_address`, `network`,
  `disable_security_group_assignment`, `region`,
  `options.private_network_only` and the `options.observability`
  blocks. `plan_id` and listener, target pool, target, ACL and session
  persistence edits update in place.
- Map-to-list ordering: the module converts the `listeners` and
  `target_pools` maps to the provider's lists in lexicographic key
  order. The provider plans list entries by index while the API applies
  changes by name, so add new entries with keys sorting after the
  existing ones to keep plans readable.
- Cross-network targets: when targets are outside the load balancer's
  network, allow the load balancer's security group
  (`load_balancer_security_group_id` output) in the target side's
  security groups — e.g. via the stackit/security_group module's rules.
- `private_address` is transient and can change when the load balancer
  is replaced; reference `external_address` (or DNS) rather than the
  private VIP.
- Upstream limits, validated at plan time: 1–20 listeners, 1–20 target
  pools, 1–1000 targets per pool.
- `server_name_indicators` (TLS passthrough SNI) is deprecated upstream
  and scheduled for removal after October 2026 — intentionally out of
  scope.
- Plan-time validations mirror the provider's plan-time validators
  (enum values, sizes, the external-address/private-network-only
  exclusivity) and the documented rules (timeout bounds, target IPs,
  pool-name references and uniqueness).
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against;
  listener/target-pool in-place updates were introduced in 0.91.0, so no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_loadbalancer` ← `{project_id},{region},{name}`
