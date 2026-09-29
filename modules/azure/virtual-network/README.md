# azure/virtual-network

Map-keyed module for Azure virtual networks. Each entry creates one
`azurerm_virtual_network` in the named resource group, in the subscription
configured on the provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `virtual_networks` | `map(object)` | — | Map of virtual networks keyed by an arbitrary unique ID. |

Plan-time validation: `name`, `resource_group_name` and `location` are
non-empty, (name, resource group) pairs are unique across entries
case-insensitively, every `address_space` entry is a valid IPv4 or IPv6 CIDR,
`dns_servers` entries are IPv4 literals, `bgp_community` carries Microsoft's
ASN 12076, `flow_timeout_in_minutes` is 4–30, `private_endpoint_vnet_policies`
is `Disabled`/`Basic`, `encryption_enforcement` is `AllowUnencrypted`,
the DDoS pair is all-or-nothing with a full ARM plan ID, and tags respect the
50-entry / 512-char key / 256-char value limits.

### `virtual_networks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Virtual network name. Validated loosely (non-empty) on purpose: Azure enforces its own naming rules at apply, so a strict charset regex here would over-reject. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the network lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region for the network. Azure does not require it to match the resource group's location, but keeping them aligned avoids surprises. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `address_space` | `list(string)` | — | Address space as IPv4 and/or IPv6 CIDRs (e.g. `10.0.0.0/16`, `fd00::/8`). Required because the alternative (`ip_address_pool` from Network Manager IPAM pools) is out of scope for this module — see Notes. Updated in place. |
| `dns_servers` | `list(string)` | `[]` | Custom DNS server IPv4 addresses handed to clients in this network. IPv4-only is a module choice, not an Azure restriction. Removing all custom servers requires an explicit `[]` — see Notes. |
| `bgp_community` | `string` | `null` | BGP community sent through ExpressRoute/hybrid networking, `<asn>:<community>` with the as-number fixed to 12076 (Microsoft's ASN). |
| `edge_zone` | `string` | `null` | Edge zone (extended zone) the network lives in, e.g. `LosAngeles`. Immutable — changing it forces replacement. |
| `flow_timeout_in_minutes` | `number` | `null` | Flow timeout for the network's flows, 4–30 minutes (Azure default is 4 when unset). |
| `private_endpoint_vnet_policies` | `string` | `Disabled` | Private endpoint policy level for the virtual network: `Disabled` or `Basic` (case-sensitive). |
| `ddos_protection_plan_id` | `string` | `null` | Full ARM resource ID of a `Microsoft.Network/ddosProtectionPlans` instance to attach. Must be set together with `enable_ddos_protection_plan` (validated). |
| `enable_ddos_protection_plan` | `bool` | `null` | Enables the attached DDoS protection plan; must be set together with `ddos_protection_plan_id` (validated). `false` with a plan ID attached is valid and passes through. |
| `encryption_enforcement` | `string` | `null` | Virtual network encryption enforcement — `AllowUnencrypted` is the only value generally available; VMs in the network support encryption when the feature is enabled on the subscription. |
| `tags` | `map(string)` | `{}` | Tags on the virtual network. The tag set is authoritative — see Notes. Tags do not flow down to subnets or NSGs. |

## Outputs

| Name | Description |
|---|---|
| `virtual_network_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<name>`). |
| `virtual_network_names` | Map of key => virtual network name. azurerm resources take `virtual_network_name` (a name string), not an ID — hand this to other Azure network modules, e.g. `azure/subnet`. |
| `virtual_network_guids` | Map of key => the GUID Azure assigned to the virtual network. |

## Example

```hcl
virtual_networks = {
  "platform-prod" = {
    name                = "vnet-platform-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    address_space = [
      "10.0.0.0/16",
      "fd00::/8",
    ]
    dns_servers = [
      "10.0.0.4",
      "10.0.0.5",
    ]
    flow_timeout_in_minutes = 15
    tags = {
      env = "prod"
    }
  }
  "platform-npd" = {
    name                           = "vnet-platform-npd"
    resource_group_name            = "rg-platform-npd"
    location                       = "West Europe"
    address_space                  = ["10.1.0.0/16"]
    private_endpoint_vnet_policies = "Basic"
    ddos_protection_plan_id        = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-platform-npd/providers/Microsoft.Network/ddosProtectionPlans/ddos-example"
    enable_ddos_protection_plan    = true
  }
}
```

## Notes

- Inline `subnet` blocks are deliberately not exposed: an
  `azurerm_virtual_network` carrying inline subnets conflicts with standalone
  `azurerm_subnet` resources — the provider overwrites subnets managed
  outside the inline blocks. Create subnets with `azure/subnet` keyed to
  this module's `virtual_network_names` output instead.
- `dns_servers` is managed inline here only. The separate
  `azurerm_virtual_network_dns_servers` resource must not be pointed at a
  network this module manages. Removing custom servers requires setting
  `dns_servers` to an explicit `[]` — Azure treats an omitted list as "no
  change" and keeps the servers.
- `name`, `resource_group_name`, `location` and `edge_zone` force replacement
  if changed; `address_space`, `dns_servers`, `bgp_community`,
  `flow_timeout_in_minutes`, `private_endpoint_vnet_policies`, the DDoS pair
  and tags update in place.
- `bgp_community`'s as-number must be 12076 (Microsoft's ASN) — the community
  value itself is yours to choose.
- Virtual network encryption supports only `AllowUnencrypted` enforcement in
  general availability; `DropUnencrypted` stays feature-gated.
- `ip_address_pool` (Network Manager IPAM pool allocations) is out of scope,
  which is why `address_space` is required: the provider accepts exactly one
  of `address_space` or an IPAM pool, so a config without `address_space`
  would have nothing to satisfy it.
- Tags are authoritative for the virtual network's tag set: the provider
  PUTs the full configured map, so tags added in the portal or CLI are
  removed on the next apply with tag changes. Tags do not inherit down to
  subnets or NSGs.
- `name` is validated loosely on purpose: Azure enforces its naming rules at
  apply, and resource group names may contain characters a conservative
  virtual-network regex would reject on the resource-group half of the ID.
- The caller needs `Microsoft.Network/virtualNetworks/write` (and delete) on
  the resource group; attaching a DDoS protection plan additionally needs
  `Microsoft.Network/ddosProtectionPlans/join/action` on the plan.

## Import

`tofu import 'azurerm_virtual_network.virtual_network["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<name>"`
