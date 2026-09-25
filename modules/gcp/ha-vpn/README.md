# gcp/ha-vpn

Map-keyed module for Google Cloud HA VPN: HA VPN gateways, peer (external)
VPN gateways, VPN tunnels, and BGP sessions on Cloud Routers.

Typical use: pair with `aws/site-to-site-vpn` to connect a GCP VPC to an
AWS VPC over two IPsec tunnels with dynamic (BGP) routing. Static routing
is also possible (omit `bgp_sessions` and create `google_compute_route`
resources with `next_hop_vpn_tunnel` consumer-side).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `routers` | `map(object)` | `{}` | Map of Cloud Routers to create, keyed by an arbitrary unique ID; `bgp` is required (the module's purpose is BGP over VPN). Omit to reference already-existing routers by name in `tunnels.router`. |
| `gateways` | `map(object)` | `{}` | Map of HA VPN gateways keyed by an arbitrary unique ID. Each gateway gets two interfaces (0 and 1). |
| `external_gateways` | `map(object)` | `{}` | Map of peer (external) VPN gateways keyed by an arbitrary unique ID; the remote side's outside addresses (for AWS: the connection's two tunnel outside IPs, `TWO_IPS_REDUNDANCY`). Omit to reference existing external gateways by self link in `tunnels`. |
| `tunnels` | `map(object)` | — | Map of VPN tunnels keyed by an arbitrary unique ID; one entry per tunnel (two per HA setup: `vpn_gateway_interface` 0 and 1). |
| `bgp_sessions` | `map(object)` | `{}` | Map of BGP sessions (router interface + BGP peer) keyed by an arbitrary unique ID; each is attached to the router of the tunnel it references. Omit for static routing. |

### `routers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Router name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `network` | `string` | — | VPC network name (same project) or self link; the network the `gateways` entries attach to. Immutable. |
| `region` | `string` | — | GCP region the router and gateway live in. Shape-validated, not a region list. Immutable. |
| `project_id` | `string` | — | Project the router lives in; defaults to the provider-level project. Format validated. |
| `bgp` | `object` | `{asn = 64512}` | BGP config; see the `bgp` object table. |

### `bgp` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `asn` | `number` | `64512` | The GCP side's private autonomous system number, 64512–65534 (2-byte) or 4200000000–4294967294 (4-byte). Must differ from the peer side's ASN (the AWS VGW/TGW `amazon_side_asn`). Validated client-side. |
| `advertise_mode` | `string` | `DEFAULT` | One of `DEFAULT`, `CUSTOM` (case-sensitive). |
| `advertised_groups` | `list(string)` | — | Currently only `ALL_SUBNETS`; `CUSTOM` `advertise_mode` only (validated). |
| `keepalive_interval` | `number` | — | BGP keepalive override; 20–60 seconds (provider default 20). Validated client-side. |
| `advertised_ip_ranges` | `list(object)` | — | `{range, description}` objects; `CUSTOM` `advertise_mode` only (validated). |

### `gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Gateway name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `network` | `string` | — | VPC network name (same project) or self link. Immutable. |
| `region` | `string` | — | GCP region. Shape-validated. Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `stack_type` | `string` | `IPV4_ONLY` | One of `IPV4_ONLY`, `IPV4_IPV6`, `IPV6_ONLY` (case-sensitive, validated). |
| `labels` | `map(string)` | — | Resource labels. |

### `external_gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Gateway name; 1–63 lowercase RFC1035 characters. Validated client-side. |
| `redundancy_type` | `string` | — | One of `SINGLE_IP_INTERNALLY_REDUNDANT`, `TWO_IPS_REDUNDANCY`, `FOUR_IPS_REDUNDANCY` (case-sensitive, validated). Interface IDs are validated against the type. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `interfaces` | `list(object)` | `[]` | `{id, ip_address}` entries — the peer's outside addresses. For an AWS connection: interface 0 = `tunnel1_addresses[conn]`, interface 1 = `tunnel2_addresses[conn]` from the `aws/site-to-site-vpn` module. |

### `tunnels` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Tunnel name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `region` | `string` | — | GCP region; must match the referenced gateway's region (API-enforced). Shape-validated. |
| `gateway` | `string` | — | A `gateways` map key (lookup wins) or an existing HA VPN gateway self link. |
| `router` | `string` | — | A `routers` map key (lookup wins) or an existing router name/self link. Required; the router carries the BGP config. |
| `vpn_gateway_interface` | `number` | — | Which gateway interface (0 or 1) this tunnel terminates on; both values must be used across the two tunnels of an HA setup. |
| `peer_external_gateway` | `string` | — | An `external_gateways` map key (lookup wins) or an existing external VPN gateway self link. Exactly one of this or `peer_ip` (validated). |
| `peer_external_gateway_interface` | `number` | — | Interface of the external gateway this tunnel terminates on; required with `peer_external_gateway` (validated). AWS tunnel 1 outside address is interface 0, tunnel 2 is interface 1 under `TWO_IPS_REDUNDANCY`. |
| `peer_ip` | `string` | — | The peer's outside IPv4 address; legacy single-IP peers. Exactly one of this or `peer_external_gateway` (validated). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `labels` | `map(string)` | — | Resource labels. |
| `shared_secret` | `string` | — | IKE pre-shared key for the tunnel; must equal the peer side's PSK (AWS `tunnel1/tunnel2.pre_shared_key`). Exactly one of this or `shared_secret_wo` (validated). 8–64 chars, no whitespace. |
| `shared_secret_wo` | `string` | — | Write-only variant, never stored in state (provider ≥ 6.28, Terraform ≥ 1.11). Pair with `shared_secret_wo_version`. |
| `shared_secret_wo_version` | `number` | — | Increment to rotate `shared_secret_wo` (validated pairwise). |
| `ike_version` | `number` | `2` | 1 or 2 (validated). Keep in sync with the AWS tunnel's `ike_versions`. |
| `local_traffic_selector` | `list(string)` | — | GCP-side traffic selectors (CIDRs). Route-based tunnels normally leave this unset (`0.0.0.0/0` implied). |
| `remote_traffic_selector` | `list(string)` | — | Peer-side traffic selectors (CIDRs). Same note. |

### `bgp_sessions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `tunnel` | `string` | — | A `tunnels` map key; the interface is linked to this tunnel and the session rides the tunnel's router. |
| `name` | `string` | — | Name for the created `google_compute_router_interface` and `google_compute_router_peer` (same value, both RFC1035; validated). |
| `peer_asn` | `number` | — | The peer side's ASN; for AWS the `amazon_side_asn` of the VGW or Transit Gateway (default 64512). Must differ from the GCP router's `bgp.asn`. |
| `ip_range` | `string` | — | The GCP router interface's link-local address, `/30`, e.g. `169.254.0.2/30`; must equal the AWS tunnel's inside CIDR with this side's host. For AWS pairing use `tunnelN_cgw_inside_addresses` output + `/30`. Validated client-side. |
| `peer_ip_address` | `string` | — | The AWS tunnel's inside address on the AWS side (`tunnelN_vgw_inside_addresses` output); validated to be one of the two hosts of `ip_range`. |
| `advertised_route_priority` | `number` | — | Route priority advertised to this peer; 0–65535 (provider default 100). Validated client-side. |
| `md5_authentication_key` | `object` | — | `{name, key}` BGP MD5 auth; key is 1–80 printable chars. Must match the AWS side's BGP auth when used. |

## Outputs

`router_names` — map of router key => created Cloud Router name.
`router_self_links` — map of router key => created Cloud Router self link.
`gateway_names` — map of gateway key => HA VPN gateway name.
`gateway_self_links` — map of gateway key => HA VPN gateway self link.
`vpn_gateway_addresses` — map of gateway key => list of the gateway's two public interface addresses; these are what the AWS customer gateway references.
`external_gateway_names` — map of external gateway key => external VPN gateway name.
`external_gateway_self_links` — map of external gateway key => external VPN gateway self link.
`tunnel_names` — map of tunnel key => VPN tunnel name.
`tunnel_self_links` — map of tunnel key => VPN tunnel self link.
`tunnel_statuses` — map of tunnel key => API-reported detailed status; converges to `tunnel-established` once the AWS side's matching tunnel is up with the same PSK.

## Example

GCP side of a GCP↔AWS HA VPN, fed by `aws/site-to-site-vpn` outputs
(`dependency.aws_vpn` in Terragrunt):

```hcl
routers = {
  "prod" = {
    name    = "example-vpn-router"
    network = "example-vpc"
    region  = "us-central1"
    bgp = {
      asn = 64512
    }
  }
}

gateways = {
  "prod" = {
    name    = "example-ha-vpn"
    network = "example-vpc"
    region  = "us-central1"
  }
}

external_gateways = {
  "aws" = {
    name            = "example-aws-peer"
    redundancy_type = "TWO_IPS_REDUNDANCY"
    interfaces = [
      { id = 0, ip_address = dependency.aws_vpn.outputs.tunnel1_addresses["main"] },
      { id = 1, ip_address = dependency.aws_vpn.outputs.tunnel2_addresses["main"] },
    ]
  }
}

tunnels = {
  "tunnel0" = {
    name                            = "example-vpn-tunnel-0"
    region                          = "us-central1"
    gateway                         = "prod"
    router                          = "prod"
    vpn_gateway_interface           = 0
    peer_external_gateway           = "aws"
    peer_external_gateway_interface = 0
    shared_secret_wo                = "example-psk-tunnel0"
    shared_secret_wo_version        = 1
  }
  "tunnel1" = {
    name                            = "example-vpn-tunnel-1"
    region                          = "us-central1"
    gateway                         = "prod"
    router                          = "prod"
    vpn_gateway_interface           = 1
    peer_external_gateway           = "aws"
    peer_external_gateway_interface = 1
    shared_secret_wo                = "example-psk-tunnel1"
    shared_secret_wo_version        = 1
  }
}

bgp_sessions = {
  "tunnel0" = {
    name            = "example-bgp-0"
    tunnel          = "tunnel0"
    ip_range        = "169.254.0.2/30"
    peer_asn        = 64512
    peer_ip_address = "169.254.0.1"
  }
  "tunnel1" = {
    name            = "example-bgp-1"
    tunnel          = "tunnel1"
    ip_range        = "169.254.1.2/30"
    peer_asn        = 64512
    peer_ip_address = "169.254.1.1"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — the key
  disambiguates entries. `tunnels.gateway`, `tunnels.router`,
  `tunnels.peer_external_gateway` and `bgp_sessions.tunnel` are intentional
  exceptions: a value matching a key of the corresponding map resolves to
  the created resource, and anything else must be the name (or self link)
  of an existing resource.
- **Cross-cloud ordering**: AWS must exist first — its connection produces
  the two tunnel outside addresses (GCP `external_gateways.interfaces`)
  and, when AWS auto-assigns inside /30s, the BGP addresses
  (`tunnelN_cgw_inside_addresses` → `ip_range`,
  `tunnelN_vgw_inside_addresses` → `peer_ip_address`). To keep everything
  in code, set `tunnel1/tunnel2.inside_cidr` on the AWS side and mirror the
  /30 hosts here, as in the example (GCP `.2`, AWS `.1`).
- **ASN pairing**: GCP router `bgp.asn` and the AWS side's
  `amazon_side_asn` must differ (AWS default 64512). The AWS customer
  gateway's `bgp_asn` equals the GCP router's `bgp.asn`.
- **Secrets**: `shared_secret` is stored in state as plain text (provider
  warning); prefer `shared_secret_wo` where the toolchain supports it. If
  you omit the AWS side's `pre_shared_key`s, AWS generates PSKs — read them
  from the `aws/site-to-site-vpn` module outputs and feed them here instead.
- Routes learned via BGP are installed on the Cloud Router's network
  automatically; advertise the GCP subnets with `advertise_mode = CUSTOM`
  + `advertised_groups = ["ALL_SUBNETS"]` (router level) for AWS to learn
  them. Static GCP-side routes to the tunnels are consumer-side
  (`google_compute_route` with `next_hop_vpn_tunnel`).
- Both tunnels of an HA pair should carry `bgp_sessions` entries; with one
  session only, failover degrades to one live path.
- VPC `mtu` above 1460 needs care across IPsec; keep the GCP VPC at 1460
  unless the AWS side is tuned to match.
- Pair with `gcp/vpc` (`network`), `gcp/subnet` (advertised ranges), and
  `aws/site-to-site-vpn` (the remote side).

- Not yet in scope (future additions): per-peer `advertise_mode` /
  `advertised_ip_ranges` / `custom_learned_ip_ranges` on BGP peers, BFD,
  IKE `cipher_suite` overrides, IPv6 (`stack_type` beyond `IPV4_ONLY`
  defaults), `peer_gcp_gateway` (GCP↔GCP HA VPN), and
  `redundant_interface` router interfaces.

## Import

`google_compute_router` ←
`projects/{project}/regions/{region}/routers/{name}` (also
`{project}/{region}/{name}`, `{region}/{name}`, `{name}`).

`google_compute_ha_vpn_gateway` ←
`projects/{project}/regions/{region}/vpnGateways/{name}` (also
`{project}/{region}/{name}`, `{region}/{name}`, `{name}`).

`google_compute_external_vpn_gateway` ←
`projects/{project}/global/externalVpnGateways/{name}` (also
`{project}/{name}`, `{name}`).

`google_compute_vpn_tunnel` ←
`projects/{project}/regions/{region}/vpnTunnels/{name}` (also
`{project}/{region}/{name}`, `{region}/{name}`, `{name}`).

`google_compute_router_interface` ←
`{project}/{region}/{router}/{name}` (also `{region}/{router}/{name}`).

`google_compute_router_peer` ←
`projects/{project}/regions/{region}/routers/{router}/{name}` (also
`{project}/{region}/{router}/{name}`, `{region}/{router}/{name}`,
`{router}/{name}`).
