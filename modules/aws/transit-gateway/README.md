# aws/transit-gateway

Map-keyed module for AWS Transit Gateway: gateways, route tables, VPC
attachments (with accepters), peering attachments (with peer-side
accepters), static routes, and route table associations and
propagations. VPN attachments are implicit to VPN connections and are
referenced by id.

> **Provider floor** — developed against the `aws` provider v6.x:
> `security_group_referencing_support` (gateway and VPC attachment) and
> `encryption_support` are v6-era attributes; pin v6 or newer on the
> consumer side.

## Destroy semantics (read before using)

- Removing a gateway key tears down routes, then
  associations/propagations, then attachments, then route tables, then
  the gateway (reference ordering). The API rejects gateway deletion
  while associations exist; the ordering handles it. Toggling
  `replace_existing_association` can strand associations — remove the
  association entries before flipping it.
- VPC attachment `subnet_ids` removal shrinks the attachment in place.
  Changing `vpc_id` or the transit gateway forces replacement — a new
  attachment that needs re-accepting when cross-account (set `accept`
  on the new entry or accept consumer-side).
- Peering: deleting the requester-side attachment ends the peering; the
  accepter resource deletion only detaches the accepter-side
  tags/state. Cross-region peers keep their own side.
- VPN attachments are implicit to their `aws_vpn_connection` (no
  managed resource exists — nothing in this module owns them). Deleting
  the VPN connection in `aws/site-to-site-vpn` removes the attachment
  implicitly; TGW-side routes/associations referencing that attachment
  id must be removed first or the connection delete blocks. That
  cross-module ordering is the consumer's.
- Cost flag: a Transit Gateway bills hourly (roughly $36.50/month per
  gateway) plus per-attachment hourly charges and processed GB —
  tearing down unused gateways and attachments matters.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `gateways` | `map(object)` | `{}` | Map of Transit Gateways keyed by an arbitrary unique ID. |
| `route_tables` | `map(object)` | `{}` | Map of route tables keyed by an arbitrary unique ID; each references its gateway by `gateway_key` or `gateway_id`. |
| `vpc_attachments` | `map(object)` | `{}` | Map of VPC attachments keyed by an arbitrary unique ID; each references its gateway by `gateway_key` or `transit_gateway_id`. |
| `peerings` | `map(object)` | `{}` | Map of peering attachment requests keyed by an arbitrary unique ID. |
| `peering_accepters` | `map(object)` | `{}` | Map of peer-side accepters keyed by an arbitrary unique ID; the attachment id is the requester's. |
| `routes` | `map(object)` | `{}` | Map of static routes keyed by an arbitrary unique ID. |
| `associations` | `map(object)` | `{}` | Map of route table associations keyed by an arbitrary unique ID. |
| `propagations` | `map(object)` | `{}` | Map of route table propagations keyed by an arbitrary unique ID. |

### `gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Becomes the `Name` tag. |
| `description` | `string` | — | Free-form description. |
| `amazon_side_asn` | `number` | `64512` | Private ASN: 64512–65534 or 4200000000–4294967294 (validated); must differ from the VPN peers' ASNs. |
| `auto_accept_shared_attachments` | `string` | `disable` | Lowercase `enable`/`disable` (validated). |
| `default_route_table_association` | `string` | `enable` | Lowercase `enable`/`disable` (validated). Set `disable` when every attachment gets an explicit association — see the default-RT gotcha in Notes. |
| `default_route_table_propagation` | `string` | `enable` | Lowercase `enable`/`disable` (validated). |
| `dns_support` | `string` | `enable` | Lowercase `enable`/`disable` (validated). |
| `vpn_ecmp_support` | `string` | `enable` | Lowercase `enable`/`disable` (validated). |
| `multicast_support` | `string` | `disable` | Lowercase `enable`/`disable` (validated); settable only at creation — the modify API does not cover it. |
| `security_group_referencing_support` | `string` | `disable` | Lowercase `enable`/`disable` (validated); v6-era attribute. |
| `encryption_support` | `string` | `disable` | Lowercase `enable`/`disable` (validated); VPC Encryption Control. Once set to `enable`, switching back to `disable` requires passing `disable` explicitly. |
| `transit_gateway_cidr_blocks` | `set(string)` | — | CIDR blocks for the gateway (/24+ IPv4, /64+ IPv6 at the API, validated shape). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `route_tables` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `gateway_key` | `string` | — | A `gateways` map key. Exactly one of this or `gateway_id` (validated). |
| `gateway_id` | `string` | — | Transit Gateway ID (`tgw-...`) pass-through for RAM-shared gateways. Exactly one of this or `gateway_key` (validated). |
| `name` | `string` | — | The route table has no name attribute — this becomes the `Name` tag. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `vpc_attachments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Becomes the `Name` tag. |
| `gateway_key` | `string` | — | A `gateways` map key. Exactly one of this or `transit_gateway_id` (validated). |
| `transit_gateway_id` | `string` | — | Transit Gateway ID (`tgw-...`) pass-through for RAM-shared gateways. Exactly one of this or `gateway_key` (validated). |
| `vpc_id` | `string` | — | VPC to attach (validated `vpc-...`); pair with the `aws/vpc` module. |
| `vpc_owner_id` | `string` | — | Account ID owning the VPC, for cross-account attachments. |
| `subnet_ids` | `set(string)` | — | At least one subnet (validated, API minimum); use at least two across AZs for redundancy. Pair with the `aws/subnet` module. |
| `dns_support` | `string` | `enable` | Lowercase `enable`/`disable` (validated). |
| `ipv6_support` | `string` | `disable` | Lowercase `enable`/`disable` (validated). |
| `appliance_mode_support` | `string` | `disable` | Lowercase `enable`/`disable` (validated); pins flows to one AZ for the flow lifetime (middlebox deployments). |
| `security_group_referencing_support` | `string` | — | Lowercase `enable`/`disable` (validated); v6-era attribute. |
| `transit_gateway_default_route_table_association` | `bool` | `true` | Manage the default-RT association from the attachment. **Cannot be configured with RAM-shared gateways** — the accepter side is the only knob there. |
| `transit_gateway_default_route_table_propagation` | `bool` | `true` | Same as above, for propagation. |
| `accept` | `bool` | `false` | Also create the `aws_ec2_transit_gateway_vpc_attachment_accepter` for this attachment (same-account auto-accept or the accepter side of a cross-account attachment). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `peerings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Becomes the `Name` tag. |
| `gateway_key` | `string` | — | A `gateways` map key. Exactly one of this or `transit_gateway_id` (validated). |
| `transit_gateway_id` | `string` | — | Transit Gateway ID pass-through for RAM-shared gateways. Exactly one of this or `gateway_key` (validated). |
| `peer_transit_gateway_id` | `string` | — | Peer gateway ID (`tgw-...`, validated). |
| `peer_region` | `string` | — | Peer gateway's region (validated shape); required even for same-region cross-account peers. |
| `peer_account_id` | `string` | — | Peer account ID (validated 12-digit); defaults to the provider account. |
| `options` | `object` | — | `{dynamic_routing}` — lowercase `enable`/`disable` (validated); enables auto-accepting transit gateway routes on the peering. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `peering_accepters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | `Name` tag; optional. |
| `transit_gateway_attachment_id` | `string` | — | The requester-side peering attachment ID (`tgw-attach-...`, validated) — pass-through by nature: the peering lives in the requester's account/plan, so there is no in-module edge. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` when `name` is set. |

### `routes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `route_table_key` | `string` | — | A `route_tables` map key. Exactly one of this or `route_table_id` (validated). |
| `route_table_id` | `string` | — | Route table ID (`tgw-rt-...`) pass-through. Exactly one of this or `route_table_key` (validated). |
| `destination_cidr_block` | `string` | — | IPv4 or IPv6 CIDR (validated); most specific prefix wins. |
| `attachment_key` | `string` | — | A `vpc_attachments` map key. Exactly one of this or `transit_gateway_attachment_id` (validated), unless `blackhole`. |
| `transit_gateway_attachment_id` | `string` | — | Attachment ID pass-through — VPC, VPN (implicit to the `aws_vpn_connection` in `aws/site-to-site-vpn`), or DX attachment. |
| `blackhole` | `bool` | `false` | Drop matching traffic; conflicts with an attachment target (validated), and a route needs one of the two (validated). |

### `associations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `route_table_key` | `string` | — | A `route_tables` map key. Exactly one of this or `route_table_id` (validated). |
| `route_table_id` | `string` | — | Route table ID pass-through. |
| `attachment_key` | `string` | — | A `vpc_attachments` map key. Exactly one of this or `transit_gateway_attachment_id` (validated). |
| `transit_gateway_attachment_id` | `string` | — | Attachment ID pass-through (VPC, VPN, or shared attachment). |
| `replace_existing_association` | `bool` | `false` | Remove the attachment's current route table association first. Intended for RAM-shared gateways — see the default-RT gotcha in Notes. |

### `propagations` object

Same shape as `associations` without `replace_existing_association`:
`route_table_key`/`route_table_id` (validated) and
`attachment_key`/`transit_gateway_attachment_id` (validated).

## Outputs

`gateway_ids`, `gateway_arns`, `gateway_owner_ids`,
`gateway_default_association_route_table_ids`,
`gateway_default_propagation_route_table_ids`, `gateway_cidr_blocks` —
maps of gateway key => ID / ARN / owner account / computed default
route table IDs / CIDR blocks.

`route_table_ids`, `route_table_arns` — maps of route table key =>
route table ID / ARN.

`vpc_attachment_ids`, `vpc_attachment_arns` — maps of VPC attachment
key => attachment ID / ARN.

`peering_attachment_ids`, `peering_attachment_states` — maps of peering
key => peering attachment ID / state.

`route_ids` — map of route key => route ID
(`tgw-rt-..._destination`).

`association_ids`, `propagation_ids` — maps of association/propagation
key => resource ID, keyed by the entries' own map keys.

## Example

```hcl
gateways = {
  "core" = {
    name            = "example-core"
    description     = "example hub gateway"
    amazon_side_asn = 64512

    default_route_table_association = "disable"
    default_route_table_propagation = "disable"

    tags = {
      Environment = "example"
    }
  },
}

route_tables = {
  "prod" = {
    gateway_key = "core"
    name        = "example-prod"
  },
  "shared" = {
    gateway_key = "core"
    name        = "example-shared"
  },
}

vpc_attachments = {
  "prod-a" = {
    name       = "example-prod-a"
    gateway_key = "core"
    vpc_id     = dependency.network.outputs.vpc_ids["prod-a"]
    subnet_ids = dependency.network.outputs.private_subnet_ids["prod-a"]

    transit_gateway_default_route_table_association = false
    transit_gateway_default_route_table_propagation = false
  },
  "prod-b" = {
    name       = "example-prod-b"
    gateway_key = "core"
    vpc_id     = dependency.network.outputs.vpc_ids["prod-b"]
    subnet_ids = dependency.network.outputs.private_subnet_ids["prod-b"]

    transit_gateway_default_route_table_association = false
    transit_gateway_default_route_table_propagation = false

    accept = true
  },
  "shared" = {
    name       = "example-shared"
    gateway_key = "core"
    vpc_id     = dependency.network.outputs.vpc_ids["shared"]
    subnet_ids = dependency.network.outputs.private_subnet_ids["shared"]

    transit_gateway_default_route_table_association = false
    transit_gateway_default_route_table_propagation = false
  },
}

associations = {
  "prod-a" = {
    route_table_key = "prod"
    attachment_key  = "prod-a"
  },
  "prod-b" = {
    route_table_key = "prod"
    attachment_key  = "prod-b"
  },
  "shared" = {
    route_table_key = "shared"
    attachment_key  = "shared"
  },
}

propagations = {
  "prod-from-shared" = {
    route_table_key = "prod"
    attachment_key  = "shared"
  },
}

routes = {
  "blackhole-lease" = {
    route_table_key       = "prod"
    destination_cidr_block = "0.0.0.0/0"
    blackhole             = true
  },
  "to-vpn" = {
    route_table_key               = "shared"
    destination_cidr_block        = "192.168.0.0/16"
    transit_gateway_attachment_id = "tgw-attach-0123456789abcdef0"
  },
}

peerings = {
  "hub" = {
    name                    = "example-to-hub"
    gateway_key             = "core"
    peer_transit_gateway_id = "tgw-0fedcba9876543210"
    peer_region             = "us-east-1"
    peer_account_id         = "123456789012"

    options = {
      dynamic_routing = "enable"
    }
  },
}

peering_accepters = {
  "hub" = {
    name                          = "example-hub-accept"
    transit_gateway_attachment_id = "tgw-attach-0123456789abcdef0"
  },
}
```

## Notes

- Keys are arbitrary unique identifiers; every map iterates by its own
  keys — no composite keys anywhere in this module.
- **Default-route-table gotcha (silent, not an error)**: with the
  gateway's `default_route_table_association = "enable"` (the provider
  default), declaring an explicit association for an attachment
  silently steals the default-RT association — no plan-time or
  apply-time error flags it, and the attachment's traffic quietly
  follows the wrong route table. Declare explicit associations only
  for gateways with default association disabled (as in the example),
  or set `replace_existing_association` deliberately and know which
  table should win. This module deliberately does not reject the
  mixed configuration — existing configs must keep applying.
- VPN attachments: there is no per-attachment managed resource in the
  AWS provider — a VPN attachment is implicit to its
  `aws_vpn_connection` (pair with the `aws/site-to-site-vpn` module).
  Its attachment id is referenced in routes/associations here as a
  pass-through `transit_gateway_attachment_id`; a
  `connection_transit_gateway_attachment_ids` output on
  `aws/site-to-site-vpn` is the natural follow-up.
- Transit Gateway sharing via RAM is consumer-side: share the gateway
  from the owner account, then reference it here by `gateway_id`/
  `transit_gateway_id` (resource sharing does not carry
  `default_route_table_association`/`_propagation` on the attachment
  side — configure those on the accepter).
- Out of scope v1 (future MINORs): Connect/Connect peers, multicast
  domains, policy tables, prefix list references, metering policies,
  and the dedicated default-route-table association/propagation
  replacement resources.
- Accepters: the VPC attachment accepter is created from the
  attachment entry's `accept = true` (the attachment must be in this
  module); consumer-side-only attachments are accepted with a
  consumer-side `aws_ec2_transit_gateway_vpc_attachment_accepter`
  resource instead.

## Import

`aws_ec2_transit_gateway` ← gateway ID (`tgw-...`).
`aws_ec2_transit_gateway_route_table` ← route table ID (`tgw-rt-...`).
`aws_ec2_transit_gateway_vpc_attachment` ← attachment ID
(`tgw-attach-...`).
`aws_ec2_transit_gateway_vpc_attachment_accepter` ← attachment ID.
`aws_ec2_transit_gateway_peering_attachment` ← attachment ID.
`aws_ec2_transit_gateway_peering_attachment_accepter` ← attachment ID.
`aws_ec2_transit_gateway_route` ← `route-table-id_destination`
(underscore, e.g. `tgw-rt-0123456789abcdef0_0.0.0.0/0`).
`aws_ec2_transit_gateway_route_table_association` ←
`route-table-id_attachment-id` (underscore).
`aws_ec2_transit_gateway_route_table_propagation` ←
`route-table-id_attachment-id` (underscore).
