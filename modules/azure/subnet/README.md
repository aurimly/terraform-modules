# azure/subnet

Map-keyed module for Azure subnets. Each entry creates one `azurerm_subnet`
inside the named virtual network, in the subscription configured on the
provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subnets` | `map(object)` | — | Map of subnets keyed by an arbitrary unique ID. |

Plan-time validation: `name`, `resource_group_name` and `virtual_network_name`
are non-empty, (name, virtual network, resource group) triples are unique
across entries case-insensitively, every `address_prefixes` entry is a valid
IPv4 or IPv6 CIDR, `private_endpoint_network_policies` is one of the four
allowed values, service endpoint services are non-empty with ARM-format
`network_identifier`s, and delegation names/actions are non-empty.

### `subnets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Subnet name. Unique within the virtual network, case-insensitively. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the virtual network lives in — the subnet's own group must be the vnet's group (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `virtual_network_name` | `string` | — | Name of the owning virtual network (typically `dependency.vnet.outputs.virtual_network_names["platform"]` with the `azure/virtual-network` module). Immutable — changing it forces replacement. |
| `address_prefixes` | `list(string)` | — | Address prefixes as IPv4 and/or IPv6 CIDRs within the vnet's address space. Required because the alternative (`ip_address_pool` from Network Manager IPAM pools) is out of scope for this module — see Notes. Updated in place. |
| `default_outbound_access_enabled` | `bool` | `true` | Default outbound internet access for the subnet. Disabling it breaks implicit outbound connectivity — pair with explicit NAT or a firewall path. Updated in place. |
| `private_endpoint_network_policies` | `string` | `Disabled` | Network policies applied to private endpoints in this subnet: `Disabled`, `Enabled`, `NetworkSecurityGroupEnabled` or `RouteTableEnabled` (case-sensitive). |
| `private_link_service_network_policies_enabled` | `bool` | `true` | Whether network policies apply to Private Link service traffic sourced from this subnet. |
| `service_endpoint_policy_ids` | `list(string)` | `[]` | Full ARM resource IDs of service endpoint policy definitions to attach. |
| `delegations` | `map(object)` | `{}` | Delegations for the subnet, keyed by an arbitrary identifier — the map key doubles as the delegation block's `name`. |
| `service_endpoints` | `map(object)` | `{}` | Service endpoints to enable on the subnet, keyed by an arbitrary identifier. |

### `delegations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service_delegation_name` | `string` | — | Service the subnet is delegated to, e.g. `Microsoft.ContainerInstance/containerGroups`. The wrapping delegation block's `name` comes from the map key. |
| `actions` | `list(string)` | `[]` | Allowed actions for the delegation, e.g. `Microsoft.Network/virtualNetworks/subnets/action`. |

### `service_endpoints` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `service` | `string` | — | Service to enable, e.g. `Microsoft.Storage` or `Microsoft.Sql`. |
| `network_identifier` | `string` | `null` | Full ARM resource ID of a Virtual Network Rule service endpoint policy (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/serviceEndpointPolicies/<name>`) restricting the endpoint's reach. |

## Outputs

| Name | Description |
|---|---|
| `subnet_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<name>`). |
| `subnet_names` | Map of key => subnet name. |
| `subnet_address_prefixes` | Map of key => list of configured address prefixes — handy for wiring NSG rules or firewall sources in the consumer. |

## Example

```hcl
subnets = {
  "workload" = {
    name                 = "snet-workload"
    resource_group_name  = "rg-platform-prod"
    virtual_network_name = "vnet-platform-prod"
    address_prefixes = [
      "10.0.1.0/24",
    ]
  }
  "aci" = {
    name                 = "snet-aci"
    resource_group_name  = "rg-platform-prod"
    virtual_network_name = "vnet-platform-prod"
    address_prefixes = [
      "10.0.2.0/24",
    ]
    delegations = {
      "container-instances" = {
        service_delegation_name = "Microsoft.ContainerInstance/containerGroups"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action",
        ]
      }
    }
  }
  "storage" = {
    name                 = "snet-storage"
    resource_group_name  = "rg-platform-prod"
    virtual_network_name = "vnet-platform-prod"
    address_prefixes = [
      "10.0.3.0/24",
    ]
    service_endpoints = {
      "storage" = {
        service = "Microsoft.Storage"
      }
    }
  }
}
```

## Notes

- The owning virtual network must not declare inline `subnet` blocks — the
  provider overwrites subnets managed outside the inline blocks. Use
  `azure/virtual-network` (which does not expose inline subnets) for the
  parent network and this module for its subnets.
- NSG and route table associations are not managed here: `azurerm_subnet`
  only carries the Azure-Policy-gated write-only
  `network_security_group_id_wo` / `route_table_id_wo` arguments, and the
  provider recommends the dedicated association resources. Attach security
  groups with `azurerm_subnet_network_security_group_association` fed by
  this module's `subnet_ids` output, e.g.:

  ```hcl
  resource "azurerm_subnet_network_security_group_association" "workload" {
    subnet_id                 = dependency.subnet.outputs.subnet_ids["workload"]
    network_security_group_id = dependency.nsg.outputs.network_security_group_ids["workload"]
  }
  ```
- `name`, `resource_group_name` and `virtual_network_name` force replacement
  if changed; `address_prefixes`, the policy flags,
  `default_outbound_access_enabled`, delegations, service endpoints and
  policy IDs update in place.
- `ip_address_pool` (Network Manager IPAM pool allocations) is out of scope,
  which is why `address_prefixes` is required: the provider accepts exactly
  one of `address_prefixes` or an IPAM pool, so a config without
  `address_prefixes` would have nothing to satisfy it.
- `delegations` map keys double as the delegation block's `name` — pick keys
  you would accept as a name (letters, digits, hyphens, underscores).
- `private_endpoint_network_policies` governs NSG/route-table enforcement on
  traffic to private endpoints in the subnet; it must be `Enabled` (or the
  finer-grained variants) before an NSG can be evaluated against private
  endpoint traffic. `private_link_service_network_policies_enabled` is the
  equivalent switch for Private Link service-sourced traffic.
- There is no `tags` attribute: `azurerm_subnet` has none — Azure models
  subnet tags differently, so there is nothing to manage.
- The caller needs `Microsoft.Network/virtualNetworks/subnets/write` (and
  delete) on the virtual network's resource group.

## Import

`tofu import 'azurerm_subnet.subnet["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<name>"`
