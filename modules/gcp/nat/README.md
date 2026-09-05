# gcp/nat

Map-keyed module for Google Cloud Routers and Cloud NAT gateways.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `routers` | `map(object)` | `{}` | Map of Cloud Routers to create, keyed by an arbitrary unique ID. Omit to reference already-existing routers by name or self link. |
| `nats` | `map(object)` | — | Map of Cloud NAT gateways keyed by an arbitrary unique ID; `nats.router` is either a key of `routers` or the name (or self link) of an existing router in the same region. |

### `routers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Router name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `network` | `string` | — | VPC network name (same project) or self link. Immutable; changing forces replacement. |
| `region` | `string` | — | GCP region the router lives in. Shape-validated, not a region list. Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the router lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `bgp` | `object` | — | Presence configures Cloud Routing on the router; omit for a NAT-only router. See the `bgp` object table. |

### `bgp` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `asn` | `number` | — | Private autonomous system number, 64512–65534 (2-byte) or 4200000000–4294967294 (4-byte). Validated client-side. |
| `advertise_mode` | `string` | `DEFAULT` | One of `DEFAULT`, `CUSTOM` (case-sensitive). |
| `advertised_groups` | `list(string)` | — | Currently only `ALL_SUBNETS`; `CUSTOM` `advertise_mode` only (validated). |
| `keepalive_interval` | `number` | — | BGP keepalive interval override; 20–60 seconds (provider default 20). Validated client-side. |
| `advertised_ip_ranges` | `list(object)` | — | `{range, description}` objects to advertise; `CUSTOM` `advertise_mode` only (validated). |

### `nats` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | NAT gateway name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `region` | `string` | — | GCP region. Must match the referenced router's region (API-enforced). Shape-validated. |
| `router` | `string` | — | A `routers` map key (lookup wins) or an existing router name/self link. |
| `source_subnetwork_ip_ranges_to_nat` | `string` | — | One of `ALL_SUBNETWORKS_ALL_IP_RANGES`, `ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES`, `LIST_OF_SUBNETWORKS` (case-sensitive, validated). |
| `project_id` | `string` | — | Project the NAT lives in; defaults to the provider-level project. Format validated. |
| `nat_ip_allocate_option` | `string` | `AUTO_ONLY` | One of `AUTO_ONLY`, `MANUAL_ONLY` (case-sensitive, validated). |
| `nat_ips` | `list(string)` | — | Reserved address self links; required iff `MANUAL_ONLY` (validated). Pair with `gcp/static_ip` below. |
| `subnetworks` | `list(object)` | `[]` | Only with `LIST_OF_SUBNETWORKS`; see the sub-table. Non-empty iff `LIST_OF_SUBNETWORKS` (validated). |
| `log_config` | `object` | — | Presence enables NAT logging; `{enable = true (default), filter = "ALL"/"ERRORS_ONLY"/"TRANSLATIONS_ONLY"}` (validated). |
| `min_ports_per_vm` | `number` | — | Lower port limit; power of two ≥ 32 (provider defaults: 64 static, 32 dynamic). Validated client-side. |
| `max_ports_per_vm` | `number` | — | Upper port limit; power of two; requires `enable_dynamic_port_allocation = true` (validated). |
| `enable_dynamic_port_allocation` | `bool` | — | Enables dynamic port allocation; mutually exclusive with endpoint-independent mapping (validated). |
| `enable_endpoint_independent_mapping` | `bool` | — | Preserves the same external port mapping for different destinations. |
| `udp_idle_timeout_sec` | `number` | — | UDP idle timeout; provider default 30. Must be > 0 when set. |
| `icmp_idle_timeout_sec` | `number` | — | ICMP idle timeout; provider default 30. Must be > 0 when set. |
| `tcp_established_idle_timeout_sec` | `number` | — | Established TCP idle timeout; provider default 1200 (20 min). Must be > 0 when set. |
| `tcp_transitory_idle_timeout_sec` | `number` | — | Transitory TCP idle timeout; provider default 30. Must be > 0 when set. |

`subnetworks` entry: `{name = subnetwork self link, source_ip_ranges_to_nat = ["ALL_IP_RANGES" | "PRIMARY_IP_RANGE" | "LIST_OF_SECONDARY_IP_RANGES"], secondary_ip_range_names = [...]}` — `secondary_ip_range_names` only with `LIST_OF_SECONDARY_IP_RANGES` (validated).

## Outputs

`nat_names` — map of NAT key => gateway name.
`nat_ids` — map of NAT key => gateway ID (`{{project}}/{{region}}/{{router}}/{{name}}`).
`router_names` — map of router key => created router name.
`router_self_links` — map of router key => created router self link.

## Example

```hcl
routers = {
  "prod" = {
    name    = "example-router"
    network = "example-vpc"
    region  = "us-central1"
    bgp = {
      asn = 64512
    }
  }
}

nats = {
  "prod" = {
    name                               = "example-nat"
    region                             = "us-central1"
    router                             = "prod"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"
    log_config = {}
  }
  "egress-tenant" = {
    name                               = "example-tenant-nat"
    region                             = "us-central1"
    router                             = "existing-us-central1"
    nat_ip_allocate_option             = "MANUAL_ONLY"
    nat_ips                            = ["projects/example-project-1234/regions/us-central1/addresses/example-nat-ip"]
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetworks = [
      { name = "projects/example-project-1234/regions/us-central1/subnetworks/example-app", source_ip_ranges_to_nat = ["ALL_IP_RANGES"] },
    ]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — the key
  disambiguates entries; `nats.router` keys are an intentional exception: a
  value that matches a `routers` key resolves to the created router,
  and anything else must be the name (or self link) of an existing router in
  the same region.
- The created-router case needs no sentinel: define the router in `routers`;
  the NAT entries referencing it are then ordered by the router's own
  dependency. NAT entries live in one
  map and may share one created router (a per-subnet NAT gateway fleet on a
  single BGP-disabled router is a common shape).
- The NAT region must equal the referenced router's region; the API rejects
  mismatches at apply. Typos in `router` surface the same way — the NAT name
  doesn't prove the reference resolves.
- Only one NAT with `ALL_SUBNETWORKS_ALL_IP_RANGES` or
  `ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES` may exist per network and region
  (API-enforced); model per-subnet NATs with `LIST_OF_SUBNETWORKS`.
- `MANUAL_ONLY` pairs with `gcp/static_ip` regional `EXTERNAL` addresses:
  pass the reserved addresses' self links as `nat_ips`, and remember to free
  them (or switch the NAT to `AUTO_ONLY`) before deleting the address —
  addresses in use by a NAT cannot be deleted until the gateway is updated
  away from them.
- NAT logging is off unless `log_config` is provided; its inner defaults
  (`enable = true`, `filter = "ALL"`) mirror the provider's.
- BGP `keepalive_interval` is a router property, not a NAT one — it lives on
  the `routers.bgp` block here.
- Pair with `gcp/vpc` (`network` names/self links), `gcp/subnet`
  (`subnetworks.name` self links), and `gcp/static_ip` (`MANUAL_ONLY`).

- Not yet in scope (future additions): NAT `rules` (mapping rules), `type` (PRIVATE NAT), `drain_nat_ips`, `endpoint_types`, and the NAT64 range attributes; routers: `encrypted_interconnect_router`, BGP MD5 authentication, `ncc_gateway`.

## Import

`google_compute_router` ←
`projects/{project}/regions/{region}/routers/{name}` (also
`{project}/{region}/{name}` and the bare `{name}` within the provider's
default region).

`google_compute_router_nat` ←
`projects/{project}/regions/{region}/routers/{router}/{name}` (also
`{project}/{region}/{router}/{name}`, `{region}/{router}/{name}`, and
`{router}/{name}`).
