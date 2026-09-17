# stackit/vpn_gateway

Map-keyed module for STACKIT VPN gateways (IPsec, two tunnels).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `gateways` | `map(object)` | — | Map of gateways keyed by an arbitrary unique ID. |

### `gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the gateway is created in (validated). Changing it replaces the gateway. |
| `display_name` | `string` | — | User-friendly name. Must be 1-63 characters, alnum start/end, hyphens inside (validated). Updates in place. |
| `plan_id` | `string` | — | Service plan identifier (e.g. `p500`), **not** a plan name — no plans data source exists upstream; see the [STACKIT "List available service plans" docs](https://docs.stackit.cloud/products/network/connectivity-hybrid-multi-cloud/vpn/getting-started/gateway-create/#list-available-service-plans). Updates in place. |
| `routing_type` | `string` | — | One of `POLICY_BASED`, `ROUTE_BASED`, `BGP_ROUTE_BASED` (validated). Changing it replaces the gateway. |
| `availability_zones` | `object` | — | Zones for the two tunnel endpoints: `tunnel1` and `tunnel2` (both required, validated non-empty). |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used. Changing it replaces the gateway. |
| `labels` | `map(string)` | `null` | Labels (key-value). Updates in place. |
| `bgp` | `object` | `null` | BGP configuration; see the `bgp` object table. Mandatory when `routing_type` is `BGP_ROUTE_BASED` (validated). |
| `network_config` | `object` | `null` | Network configuration; see the `network_config` object table. |

### `bgp` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `local_asn` | `number` | — | Local ASN (private range 64512-4294967294, validated). |
| `override_advertised_routes` | `list(string)` | `null` | IPv4 CIDRs to advertise via BGP, at most 100 entries (validated). If omitted, SNA network ranges are advertised — cross-link stackit/network_area / network_area_route. |

### `network_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `predefined_network_prefix` | `string` | `null` | IPv4 CIDR allocated for the gateway, prefix length /28 or larger (validated). **Changing it replaces the gateway** (destroy/recreate — tunnel outage). |
| `routing_table_id` | `string` | `null` | Custom SNA routing table UUID. If omitted, a default routing table is assigned. |

## Outputs

`gateways` — map of gateway key => object:

| Attribute | Description |
|---|---|
| `gateway_id` | Gateway UUID. |
| `id` | `"{project_id},{region},{gateway_id}"` — the import ID. |

## Example

```hcl
module "vpn_gateway" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/vpn_gateway?ref=v2.3.0"

  gateways = {
    "edge-vpn" = {
      project_id   = "12345678-1234-1234-1234-123456789012"
      display_name = "example-edge-vpn"
      plan_id      = "p500"
      routing_type = "BGP_ROUTE_BASED"
      availability_zones = {
        tunnel1 = "eu01-m"
        tunnel2 = "eu01-k"
      }
      region = "eu01"
      bgp = {
        local_asn = 64512
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names — multiple resources
  can share a name, so the key disambiguates them.
- **Renaming a map key destroys and recreates the gateway — tunnel outage.**
  The same applies to changing `project_id`, `region` or `routing_type`.
- `bgp` is mandatory with `BGP_ROUTE_BASED` and only meaningful with it —
  it is ignored by the API for other routing types (not rejected here).
- `routing_table_id` references SNA routing tables — see
  stackit/network_area and stackit/network_area_route for the
  corresponding routing infrastructure.
- Tunnel status is available consumer-side via the upstream
  `stackit_vpn_gateway_status` data source.
- Plan-time validations here mirror the provider's plan-time validators
  (UUIDs, display_name format, routing_type enum, ASN range, CIDR format,
  list sizes, BGP-vs-routing-type cross-check) as forward-checking; no
  behavior requires anything beyond what the provider already enforces.
- **`tofu validate` caveat (upstream provider bug)**: the provider's
  vpn_gateway `ValidateConfig` cannot decode unknown values — running
  `tofu validate` on any configuration that uses `for_each` (map-keyed
  or otherwise) fails with `Value Conversion Error ... Target Type:
  *gateway.AvailabilityZonesModel / *gateway.BGPGatewayConfigModel`
  (verified against provider v0.115.0; also present on the provider's
  main branch). This affects the resource itself, not this module's
  implementation — the same failure occurs with a hand-written
  `for_each` config. It is triggered at `validate`/`plan` time only;
  `tofu apply` with concrete values is unaffected. Consumers wanting
  static checks can validate a `for_each`-free variant of the same
  resource instead.
- Provider authentication is configured at the consumer's unit level.

## Related modules

- stackit/vpn_connection — the IPsec connections on a gateway created here
  (wire its `gateway_id` from this module's `gateways` output).
- stackit/network_area / stackit/network_area_route — for SNA routing.

## Import

`stackit_vpn_gateway` ← `{project_id},{region},{gateway_id}`
