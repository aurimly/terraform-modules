# equinix/fabric_routing_protocol

Map-keyed module for Equinix Fabric routing protocols on existing
connections. Two inputs — `direct_protocols` (type `DIRECT`) and
`bgp_protocols` (type `BGP`) — each entry creates one
`equinix_fabric_routing_protocol` against a `connection_uuid` you supply
(typically a `fabric_connection` output).

## Ordering contract

The API requires a DIRECT routing protocol on a connection before the BGP
protocol (the provider's own examples use `depends_on` for this). The module
orders every `bgp_protocols` entry after every `direct_protocols` entry with
a static `depends_on`. This over-serializes when you have direct protocols
on different connections than the BGP entries — the cost is some lost
parallelism, never correctness. BGP-only connections (e.g. cloud routers
that already have a direct protocol managed elsewhere) see no cost.

The same static edge reverses destroy order: BGP entries are destroyed
before DIRECT entries, which is the direction the API wants.

## Secrets in state

`bgp_auth_key` is a BGP MD5 password. It is not marked sensitive at the
variable level (per-attribute sensitivity is not expressible inside a map
input), so it appears in plain text in Terraform state and may appear in
plan output. Plan for state security (encrypted backend, minimal access), or
leave the key unset and manage authentication out-of-band.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `direct_protocols` | `map(object)` | — | DIRECT routing protocols keyed by an arbitrary unique identifier. |
| `bgp_protocols` | `map(object)` | — | BGP routing protocols keyed by an arbitrary unique identifier. Created after all `direct_protocols` entries. |

### `direct_protocols/<key>` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `connection_uuid` | `string` | yes | UUID of the Fabric connection. Unknown uuids are rejected by the API at apply. |
| `name` | `string` | yes | Up to 24 chars (letters, digits, `-`, `_`). Validated at plan. |
| `description` | `string` | no | Customer-provided description. |
| `direct_ipv4` | `object` | one of | `{ equinix_iface_ip = string }`. |
| `direct_ipv6` | `object` | one of | `{ equinix_iface_ip = string }`. |

At least one of `direct_ipv4` / `direct_ipv6` (validated).

### `bgp_protocols/<key>` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `connection_uuid` | `string` | yes | UUID of the Fabric connection. |
| `name` | `string` | yes | Up to 24 chars (letters, digits, `-`, `_`). Validated at plan. |
| `description` | `string` | no | Customer-provided description. |
| `customer_asn` | `number` | yes | Your ASN (validated ≥ 1). |
| `bgp_auth_key` | `string` | no | BGP MD5 password. Persisted in plain text in state (see Secrets in state). |
| `as_override_enabled` | `bool` | `null` | Optional+Computed upstream; omitted means the provider default applies. |
| `bfd` | `object` | no | `{ enabled = bool, interval = optional(string) }`. `interval` is a string upstream (provider default `100`). |
| `bgp_ipv4` | `object` | one of | `{ customer_peer_ip, enabled, inbound_med, outbound_med, outbound_as_prepend_count }`. |
| `bgp_ipv6` | `object` | one of | Same shape as `bgp_ipv4`. |

At least one of `bgp_ipv4` / `bgp_ipv6` (validated).

`outbound_as_prepend_count` is a **string** in the provider schema with
allowed values `"0"`, `"1"`, `"3"`, `"5"` — pass strings, not numbers
(validated).

## Outputs

| Name | Description |
|---|---|
| `direct_protocols` | Map of key → `{ uuid, state, equinix_asn, href }`. `uuid` is the import ID. |
| `bgp_protocols` | Map of key → `{ uuid, state, equinix_asn, href }`. `equinix_asn` is the Equinix-side peer ASN BGP consumers need. |

## Provider

This module only declares `required_providers` (`equinix/equinix`, floor
`>= 5.0.0`), never a `provider {}` block. Configure the provider (auth token
or `client_id`/`client_secret`) at the consumer's Terragrunt unit and pin the
exact version at the root.

## Safe destroy

Deleting a routing protocol changes how the connection routes — plan
accordingly. Renaming a map key or changing `connection_uuid` destroys and
recreates the protocol. Treat keys as stable identifiers.

## Example

```hcl
direct_protocols = {
  "dc-peer" = {
    connection_uuid = "12345678-1234-1234-1234-123456789012"
    name            = "example-direct"
    direct_ipv4 = {
      equinix_iface_ip = "192.168.0.1/30"
    }
    direct_ipv6 = {
      equinix_iface_ip = "2001:db8::1/126"
    }
  },
}

bgp_protocols = {
  "dc-bgp" = {
    connection_uuid = "12345678-1234-1234-1234-123456789012"
    name            = "example-bgp"
    customer_asn    = 65001
    bgp_auth_key    = "example-auth-key"
    bfd = {
      enabled  = true
      interval = "100"
    }
    bgp_ipv4 = {
      customer_peer_ip          = "192.168.0.2"
      enabled                   = true
      outbound_as_prepend_count = "3"
    }
  },
}
```

Wire `connection_uuid` from a `fabric_connection` unit:

```hcl
dependency "connection" {
  config_path = "../connection"
}

locals {
  connection_uuid = dependency.connection.outputs.connections["example-fcr-sp"].uuid
}
```

## Import

- `equinix_fabric_routing_protocol` ← `<connection-uuid>/<routing-protocol-uuid>`, e.g.

```hcl
import {
  to = module.routing_protocols.equinix_fabric_routing_protocol.bgp["dc-bgp"]
  id = "12345678-1234-1234-1234-123456789012/87654321-4321-4321-4321-210987654321"
}
```

## Related modules

- `equinix/fabric_connection` — the connections these protocols attach to.
- `equinix/fabric_route_aggregation` — aggregate prefixes behind BGP sessions.
