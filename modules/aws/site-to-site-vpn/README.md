# aws/site-to-site-vpn

Map-keyed module for AWS Site-to-Site VPN: customer gateways, virtual
private gateways (VGW), VPN connections with VGW or Transit Gateway
attachments, and static routes.

Typical use: pair with `gcp/ha-vpn` to connect an AWS VPC to a GCP VPC
over two IPsec tunnels with dynamic (BGP) routing, or use
`static_routes_only` for policy-based setups without BGP.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `vpn_gateways` | `map(object)` | `{}` | Map of Virtual Private Gateways to create and attach to a VPC, keyed by an arbitrary unique ID. Omit when connections use an existing VGW id or a `transit_gateway_id`. |
| `customer_gateways` | `map(object)` | — | Map of customer gateways keyed by an arbitrary unique ID; each represents the remote side (for GCP: the HA VPN gateway). |
| `connections` | `map(object)` | — | Map of Site-to-Site VPN connections keyed by an arbitrary unique ID; each creates one `aws_vpn_connection` with two tunnels. |

### `vpn_gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name tag; at most 255 characters. Validated client-side. |
| `vpc_id` | `string` | — | VPC to attach the VGW to (typically `dependency.vpc.outputs.vpc_ids["main"]` with the `aws/vpc` module). Validated. |
| `amazon_side_asn` | `number` | `64512` | ASN of the Amazon side of the gateway (the BGP ASN the GCP Cloud Router peers with). Private ranges only, 64512–65534 or 4200000000–4294967294 (validated). Must differ from the GCP router's ASN. Immutable; changing forces replacement. |
| `availability_zone` | `string` | — | AZ for the VGW. Shape-validated. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `customer_gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name tag; at most 255 characters. Validated client-side. |
| `bgp_asn` | `number` | — | The remote side's ASN — for GCP, the Cloud Router's `bgp.asn` (default 64512). 1–4294967295 (validated); mapped to `bgp_asn`/`bgp_asn_extended` internally. |
| `ip_address` | `string` | — | The remote gateway's outside IPv4 address — one of the GCP HA VPN gateway's interface addresses (`vpn_gateway_addresses` output of `gcp/ha-vpn`). Validated. |
| `device_name` | `string` | — | Name for the customer gateway device. |
| `certificate_arn` | `string` | — | ARN of a private-certificate-based IKEv2 endpoint; omit for static public-key. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `connections` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `customer_gateway` | `string` | — | A `customer_gateways` map key (lookup wins) or an existing customer gateway id (`cgw-...`). |
| `vpn_gateway` | `string` | — | A `vpn_gateways` map key (lookup wins) or an existing VGW id (`vgw-...`). Exactly one of this or `transit_gateway_id` (validated). |
| `transit_gateway_id` | `string` | — | Transit Gateway id (`tgw-...`) to attach the connection to. Exactly one of this or `vpn_gateway` (validated). |
| `static_routes_only` | `bool` | `false` | `true` for policy-based routing without BGP; then `static_routes` are required for reachability. |
| `static_routes` | `list(string)` | `[]` | Destination CIDRs added as `aws_vpn_connection_route` entries on the VGW (VGW attachments only; validated). |
| `enable_acceleration` | `bool` | — | Enable acceleration (Transit Gateway attachments only). |
| `tunnel_inside_ip_version` | `string` | `ipv4` | `ipv4` or `ipv6` (validated); `ipv6` requires a Transit Gateway attachment (validated). |
| `local_ipv4_network_cidr` | `string` | `0.0.0.0/0` | GCP-side CIDR in the IKE negotiation; set to the GPC subnets' aggregate to restrict selectors. |
| `remote_ipv4_network_cidr` | `string` | `0.0.0.0/0` | AWS-side CIDR; set to the VPC's aggregate to restrict selectors. |
| `tunnel1` | `object` | — | Options for tunnel 1; see the tunnel table. |
| `tunnel2` | `object` | — | Options for tunnel 2; see the tunnel table. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### tunnel1/tunnel2 object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `inside_cidr` | `string` | — | The tunnel's inside `/30` from `169.254.0.0/16` (validated). Set explicitly to mirror on the GCP side; omit to let AWS auto-assign and read the outputs. |
| `pre_shared_key` | `string` | — | 8–64 alphanumeric/`.`/`_` chars, not starting with `0` (validated). Must equal the matching GCP tunnel's `shared_secret`. Omit to let AWS generate one and read `tunnel1/tunnel2_preshared_keys` outputs. Stored in state as plain text (provider note). |
| `ike_versions` | `list(string)` | — | `ikev1` and/or `ikev2` (validated). GCP supports both; `ikev2` recommended. |
| `dpd_timeout_action` | `string` | `clear` | `clear`, `none` or `restart`; `restart` suits GCP failover. |
| `dpd_timeout_seconds` | `number` | `30` | ≥ 30 (validated). |
| `phase1_dh_group_numbers` | `list(number)` | — | Permitted DH groups for IKE phase 1. |
| `phase1_encryption_algorithms` | `list(string)` | — | e.g. `AES256`, `AES128-GCM-16`. |
| `phase1_integrity_algorithms` | `list(string)` | — | e.g. `SHA2-256`. |
| `phase1_lifetime_seconds` | `number` | `28800` | 900–28800 (validated). |
| `phase2_dh_group_numbers` | `list(number)` | — | Permitted DH groups for IKE phase 2. |
| `phase2_encryption_algorithms` | `list(string)` | — | As phase 1. |
| `phase2_integrity_algorithms` | `list(string)` | — | As phase 1. |
| `phase2_lifetime_seconds` | `number` | `3600` | 900–3600 (validated). |
| `rekey_fuzz_percentage` | `number` | `100` | 0–100. |
| `rekey_margin_time_seconds` | `number` | `540` | Margin before phase 2 expiry. |
| `replay_window_size` | `number` | `1024` | 64–2048 packets. |
| `startup_action` | `string` | `add` | `add` (peer initiates) or `start` (AWS initiates). |

## Outputs

`vpn_gateway_ids` — map of VGW key => VGW ID (`vgw-...`).
`vpn_gateway_arns` — map of VGW key => VGW ARN.
`customer_gateway_ids` — map of customer gateway key => ID (`cgw-...`).
`connection_ids` — map of connection key => VPN connection ID (`vpn-...`).
`connection_arns` — map of connection key => VPN connection ARN.
`tunnel1_addresses` — map of connection key => tunnel 1 outside IP; feeds the GCP side's `external_gateways.interfaces` (interface id 0).
`tunnel2_addresses` — map of connection key => tunnel 2 outside IP; interface id 1 on the GCP side.
`tunnel1_cgw_inside_addresses` — map of connection key => tunnel 1 inside address on the customer (GCP) side; the host part of the GCP `bgp_sessions.ip_range` /30.
`tunnel2_cgw_inside_addresses` — same for tunnel 2.
`tunnel1_bgp_asns` — map of connection key => tunnel 1 BGP ASN on the AWS side; the GCP `bgp_sessions.peer_asn`.
`tunnel2_bgp_asns` — same for tunnel 2.

## Example

AWS side of a GCP↔AWS HA VPN (the GCP half is the `gcp/ha-vpn` example):

```hcl
vpn_gateways = {
  "main" = {
    name            = "example-vgw"
    vpc_id          = "vpc-0123456789abcdef0"
    amazon_side_asn = 64512
  }
}

customer_gateways = {
  "gcp" = {
    name       = "example-gcp-peer"
    bgp_asn    = 64512
    ip_address = "203.0.113.20"
  }
}

connections = {
  "main" = {
    customer_gateway   = "gcp"
    vpn_gateway        = "main"
    static_routes_only = false
    tunnel1 = {
      inside_cidr    = "169.254.0.0/30"
      pre_shared_key = "example-psk-tunnel0"
    }
    tunnel2 = {
      inside_cidr    = "169.254.1.0/30"
      pre_shared_key = "example-psk-tunnel1"
    }
  }
}
```

Static-routing variant:

```hcl
connections = {
  "main" = {
    customer_gateway   = "gcp"
    vpn_gateway        = "main"
    static_routes_only = true
    static_routes      = ["10.0.0.0/16"]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
  `connections.customer_gateway` and `connections.vpn_gateway` are
  intentional exceptions: a value matching a key of the corresponding map
  resolves to the created resource, and anything else must be an existing
  resource id (`cgw-...` / `vgw-...`).
- **Cross-cloud ordering**: this module's outputs feed the GCP side
  (`tunnelN_addresses` → GCP `external_gateways` interfaces,
  `tunnelN_cgw_inside_addresses` → GCP `bgp_sessions.ip_range` hosts,
  `tunnelN_bgp_asns` → GCP `bgp_sessions.peer_asn`). Set
  `inside_cidr`s explicitly on both sides to keep the /30s in code
  (GCP takes one host, AWS the other — conventionally GCP `.2`, AWS `.1`).
- **ASN pairing**: `amazon_side_asn` (VGW) or the Transit Gateway's ASN
  must differ from the GCP router's `bgp.asn`; the customer gateway's
  `bgp_asn` equals the GCP router's ASN.
- **Secrets**: `pre_shared_key`s are stored in state as plain text
  (provider note). Omit them to let AWS generate, then wire
  `tunnel1/tunnel2_preshared_keys` outputs into the GCP side — or set the
  same PSKs on both sides in code.
- **BGP route propagation (VGW)**: enabling VGW route propagation on a
  route table is not yet exposed by the AWS provider; for VGW + BGP,
  propagate with the console/CLI or add static routes consumer-side. With
  a Transit Gateway, BGP routes install into the TGW route table
  automatically; VPC↔TGW attachments and TGW static routes are
  consumer-side.
- Transit Gateway attachments appear in the TGW console as VPN
  attachments; the attachment id is on the connection but not output here
  (add on demand).
- Static routes (`static_routes`) apply to VGW attachments only; Transit
  Gateway static routes live in TGW route tables, not the connection.
- Pair with `aws/vpc`, `aws/subnet`, and `gcp/ha-vpn` (the remote side).

- Not yet in scope (future additions): tunnel `log_options` (CloudWatch),
  IPv6 inside CIDRs, `preshared_key_storage` (Secrets Manager), private
  S2S VPN over Direct Connect (`outside_ip_address_type`,
  `transport_transit_gateway_attachment_id`), `vpn_concentrator_id`,
  `tunnel_bandwidth`, and `aws_vpn_gateway_attachment` for re-attaching an
  existing VGW.

## Import

`aws_vpn_gateway` — VGW id only: `vgw-xxxxx`.

`aws_customer_gateway` — customer gateway id only: `cgw-xxxxx`.

`aws_vpn_connection` — connection id only: `vpn-xxxxx`.

`aws_vpn_connection_route` —
`{destination-cidr-block}_{vpn-connection-id}` (e.g.
`10.0.0.0/16_vpn-xxxxx`).
