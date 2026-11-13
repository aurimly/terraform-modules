# azure/virtual-network-peering

Map-keyed module for Azure virtual network peerings. Each entry creates one
`azurerm_virtual_network_peering` — a single direction from the local virtual
network to the remote one. Azure peerings are one-directional, so working
bidirectional connectivity between two networks needs one entry per side (two
entries) in this module, in the subscription configured on the provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `virtual_network_peerings` | `map(object)` | — | Map of peering directions keyed by an arbitrary unique ID. |

Plan-time validation: `remote_virtual_network_id` is a full ARM resource ID,
(resource group, virtual network, name) triples are unique across entries
case-insensitively, `name`, `resource_group_name` and `virtual_network_name` are
non-empty, subnet-name lists hold non-empty names, subnet peering requires
`peer_complete_virtual_networks_enabled = false`, and `triggers` keys/values are
non-empty.

### `virtual_network_peerings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Peering name, unique within its virtual network case-insensitively. A common convention: `<local-vnet>-to-<remote-vnet>`. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group of the local virtual network — the peering lives there, and its location is inherited. Immutable — changing it forces replacement. |
| `virtual_network_name` | `string` | — | Local virtual network name (typically `dependency.vnet.outputs.virtual_network_names["hub"]` with the `azure/virtual-network` module). Immutable — changing it forces replacement. |
| `remote_virtual_network_id` | `string` | — | Full ARM resource ID of the remote virtual network — may be in another resource group or subscription within the tenant (typically `dependency.vnet.outputs.virtual_network_ids["spoke"]`). Immutable — changing it forces replacement. |
| `allow_virtual_network_access` | `bool` | `true` | Whether traffic from the local virtual network can reach the remote one. |
| `allow_forwarded_traffic` | `bool` | `false` | Whether forwarded traffic from VMs in the remote network is accepted. Needed when traffic hops through network virtual appliances or hubs. |
| `allow_gateway_transit` | `bool` | `false` | Whether the local network's gateways may be used by the remote network's link. At most one of the two directions in a pair may set this. Must be `false` for global (cross-region) peerings. |
| `use_remote_gateways` | `bool` | `false` | Whether the local network uses the remote network's gateways. Only one peering in a pair may set this; it cannot be set when the local network already has its own gateway. Must be `false` for global peerings. |
| `peer_complete_virtual_networks_enabled` | `bool` | `true` | Whether the complete address space is peered. Set `false` to peer selected subnets only via `local_subnet_names`/`remote_subnet_names` (validated). Immutable — changing it forces replacement. |
| `only_ipv6_peering_enabled` | `bool` | `false` | Whether only the IPv6 address space is peered. For selected-subnet peering; set `peer_complete_virtual_networks_enabled = false` alongside it. Immutable — changing it forces replacement. |
| `local_subnet_names` | `list(string)` | `[]` | Local subnet names to peer (requires `peer_complete_virtual_networks_enabled = false`, validated). |
| `remote_subnet_names` | `list(string)` | `[]` | Remote subnet names to peer (requires `peer_complete_virtual_networks_enabled = false`, validated). |
| `triggers` | `map(string)` | `{}` | Arbitrary key/value pairs whose change re-syncs remote address space — commonly a joined remote `address_space` value; see Example. |

## Outputs

| Name | Description |
|---|---|
| `peering_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/virtualNetworkPeerings/<name>`). |

## Example

```hcl
virtual_network_peerings = {
  "hub-to-spoke" = {
    name                      = "peer-hub-to-spoke"
    resource_group_name       = "rg-platform-prod"
    virtual_network_name      = dependency.vnet.outputs.virtual_network_names["hub"]
    remote_virtual_network_id = dependency.vnet.outputs.virtual_network_ids["spoke"]
    allow_forwarded_traffic   = true
    allow_gateway_transit     = true
  }
  "spoke-to-hub" = {
    name                      = "peer-spoke-to-hub"
    resource_group_name       = "rg-platform-prod"
    virtual_network_name      = dependency.vnet.outputs.virtual_network_names["spoke"]
    remote_virtual_network_id = dependency.vnet.outputs.virtual_network_ids["hub"]
    use_remote_gateways       = true
    triggers = {
      remote_address_space = "10.10.0.0/16,fd00::/8"
    }
  }
}
```

## Notes

- One entry is one direction. For full connectivity create both directions with
  matching traffic settings — each side's flags apply independently, and
  Azure's requirement that paired settings agree (e.g. gateway transit on at
  most one side) is documented here but not enforceable across entries by
  plan-time validation alone.
- The provider warns that peerings cannot be created, updated or deleted
  concurrently: it serializes CRUD on the same pair of virtual networks via
  internal locks within one tofu run, but manual portal/CLI work alongside an
  apply can still race. Azure-side changes to one direction of a pair should be
  sequenced, not parallel.
- Cross-tenant peering is out of scope — the azurerm provider only accepts
  remote networks in the same tenant. Cross-resource-group and
  cross-subscription (same tenant) peering works as-is, and cross-region
  (global) peering is generally available but forbids
  `allow_gateway_transit`/`use_remote_gateways` on both sides.
- Gateway semantics: `allow_gateway_transit` may be true on only one of the two
  directions; `use_remote_gateways` cannot be true if the local network already
  has its own gateway, and only one direction in a pair may set it. Spoke
  networks consume a hub's VPN/ExpressRoute gateway with
  `use_remote_gateways = true` on their direction plus `allow_gateway_transit =
  true` on the hub's direction.
- Peerings carry no tags — Azure does not support tagging on peering
  resources, and the provider exposes no `tags` attribute.
- Peering does not merge routing: reaching the remote network still requires
  the right routes — pair with `azure/route-table` +
  `azure/route-table-association` (UDRs to `VirtualAppliance` or through
  gateways), as BGP-learned routes only flow with gateway transit setups.
- `triggers` exist to force a re-sync of the remote network's address space —
  Azure learns remote prefixes at peering time and does not pick up later
  expansions automatically without it.
- The caller needs `Microsoft.Network/virtualNetworks/peer/action` on both
  virtual networks.

## Import

`tofu import 'azurerm_virtual_network_peering.peering["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/virtualNetworkPeerings/<name>"`
