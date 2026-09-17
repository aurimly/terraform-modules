# stackit/vpn_connection

Map-keyed module for STACKIT VPN IPsec connections on a VPN gateway.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `connections` | `map(object)` | — | Map of connections keyed by an arbitrary unique ID. |

### `connections` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID (validated). Changing it replaces the connection. |
| `gateway_id` | `string` | — | UUID of the parent VPN gateway — comes from stackit/vpn_gateway's `gateways` output (validated). Changing it replaces the connection. |
| `display_name` | `string` | — | User-friendly name. Must be 1-63 characters, alnum start/end, hyphens inside (validated). Updates in place. |
| `tunnel1` | `object` | — | IPsec tunnel 1 configuration; see the `tunnel` object table (both tunnels follow the same shape). Updated in place. |
| `tunnel2` | `object` | — | IPsec tunnel 2 configuration; same shape as `tunnel1`. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used. Changing it replaces the connection. |
| `enabled` | `bool` | `true` | Whether the connection is enabled. Unset means `true` (provider default). |
| `labels` | `map(string)` | `null` | Labels (key-value). |
| `local_subnets` | `list(string)` | `null` | Local IPv4 CIDRs routed through the connection, 1-100 entries. **Mandatory for POLICY_BASED gateways**; optional for route-based/BGP (defaults to `0.0.0.0/0`). |
| `remote_subnets` | `list(string)` | `null` | Remote IPv4 CIDRs accessible via the connection, 1-100 entries. **Mandatory for POLICY_BASED gateways**; optional for route-based/BGP (defaults to `0.0.0.0/0`). |
| `static_routes` | `list(string)` | `null` | Static IPv4 CIDR routes. **Mandatory for ROUTE_BASED gateways**. |

### `tunnel` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `remote_address` | `string` | — | Remote tunnel endpoint IPv4 address (validated). |
| `pre_shared_key` | `string` | `null` | Pre-shared key, minimum 20 characters (validated). Sensitive, but **stored in state** — prefer `pre_shared_key_wo`. Conflicts with `pre_shared_key_wo` and `pre_shared_key_wo_version` (validated). |
| `pre_shared_key_wo` | `string` | `null` | Write-only pre-shared key, minimum 20 characters — never stored in state and never returned by the API. Requires `pre_shared_key_wo_version` (validated). Changing it alone does NOT trigger an update. |
| `pre_shared_key_wo_version` | `number` | `null` | Rotation counter; requires `pre_shared_key_wo`, conflicts with `pre_shared_key` (validated). Bump it in the same change as the new key to trigger rotation. |
| `bgp` | `object` | `null` | BGP peering: `remote_asn` (private range 64512-4294967294, validated). |
| `peering` | `object` | `null` | Tunnel interface addresses: `local_address`, `remote_address` (both required, validated IPv4). |
| `phase1` | `object` | — | IKE phase 1; see the `phase` object table. |
| `phase2` | `object` | — | IKE phase 2; adds `dpd_action` and `start_action` to the `phase` object table. |

### `phase` object (phase1; phase2 adds the last two rows)

All entries apply to both tunnels.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `encryption_algorithms` | `list(string)` | — | Subset of `aes256`, `aes128gcm16`, `aes256gcm16` (validated). |
| `integrity_algorithms` | `list(string)` | — | Subset of `sha1`, `sha2_256`, `sha2_384`, `sha2_512` (validated). |
| `dh_groups` | `list(string)` | `null` | Subset of `modp1024`, `modp2048`, `ecp256`, `ecp384`, `modp2048s256` (validated). |
| `rekey_time` | `number` | 14400 (phase1) / 3600 (phase2) | Re-key interval in seconds; 900-28800 for phase1, 900-3600 for phase2 (validated). |
| `dpd_action` | `string` | `restart` | phase2 only: `clear` or `restart` (validated). |
| `start_action` | `string` | `start` | phase2 only: `none` or `start` (validated). |

## Outputs

`connections` — map of connection key => object:

| Attribute | Description |
|---|---|
| `connection_id` | Connection UUID. |
| `id` | `"{project_id},{region},{gateway_id},{connection_id}"` — the import ID. |

No pre-shared key value is exposed here — the API never returns it.

## Example

```hcl
module "vpn_connection" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/vpn_connection?ref=v2.3.0"

  connections = {
    "edge-tunnel-a" = {
      project_id   = "12345678-1234-1234-1234-123456789012"
      gateway_id   = "87654321-4321-4321-4321-210987654321"
      display_name = "example-tunnel-a"
      tunnel1 = {
        remote_address            = "203.0.113.25"
        pre_shared_key_wo         = "a-very-secret-key-goes-here"
        pre_shared_key_wo_version = 1
        phase1 = {
          encryption_algorithms = ["aes256gcm16"]
          integrity_algorithms  = ["sha2_256"]
          dh_groups             = ["modp2048"]
        }
        phase2 = {
          encryption_algorithms = ["aes256gcm16"]
          integrity_algorithms  = ["sha2_256"]
          dh_groups             = ["modp2048"]
        }
      }
      tunnel2 = {
        remote_address            = "203.0.113.26"
        pre_shared_key_wo         = "a-very-secret-key-goes-here"
        pre_shared_key_wo_version = 1
        phase1 = {
          encryption_algorithms = ["aes256gcm16"]
          integrity_algorithms  = ["sha2_256"]
          dh_groups             = ["modp2048"]
        }
        phase2 = {
          encryption_algorithms = ["aes256gcm16"]
          integrity_algorithms  = ["sha2_256"]
          dh_groups             = ["modp2048"]
        }
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names — multiple resources
  can share a name, so the key disambiguates them.
- **Renaming a map key destroys and recreates the connection — tunnel outage.**
- **Write-only arguments require OpenTofu/Terraform ≥ 1.11.** Plain
  `pre_shared_key` is stored in state (sensitive but persisted) — prefer
  `pre_shared_key_wo`.
- **Changing `pre_shared_key_wo` alone does NOT trigger an update** — it is
  write-only and never stored in state; bump `pre_shared_key_wo_version`
  in the same change to rotate the key.
- Routing-type mandates depend on the **parent gateway's** routing_type,
  which this module cannot see at plan time — they are documented here,
  not plan-enforced:
  - `POLICY_BASED` gateway → `local_subnets` + `remote_subnets` mandatory.
  - `ROUTE_BASED` gateway → `static_routes` mandatory.
  - BGP peering → tunnel `bgp.remote_asn` + `peering` addresses, and a
    `BGP_ROUTE_BASED` gateway (see stackit/vpn_gateway).
- `enabled` defaults to `true` when unset.
- Plan-time validations here mirror the provider's plan-time validators
  (UUIDs, display_name format, PSK length/consistency, IP/CIDR formats,
  phase enums, rekey ranges, list sizes) as forward-checking; no behavior
  requires anything beyond what the provider already enforces.
- Provider authentication is configured at the consumer's unit level.

## Related modules

- stackit/vpn_gateway — creates the parent gateway; wire `gateway_id`
  from its `gateways` output.
- stackit/network_area_route — for SNA routing toward VPN.

## Import

`stackit_vpn_connection` ← `{project_id},{region},{gateway_id},{connection_id}`
