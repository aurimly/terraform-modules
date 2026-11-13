# azure/route-table

Map-keyed module for Azure route tables and their user-defined routes (UDRs).
Each entry creates one `azurerm_route_table` plus one `azurerm_route` per entry
of its nested `routes` map, in the resource group named by `resource_group_name`,
in the subscription configured on the provider. Routes are separate resources,
not inline blocks — the provider's inline `route` blocks conflict with
`azurerm_route` resources (each overwrites the other's routes), so this module
only ever creates the standalone kind.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `route_tables` | `map(object)` | — | Map of route tables keyed by an arbitrary unique ID; routes live inside each entry. |

Plan-time validation: map keys are dot-free (route resource addresses are
composed as `<table-key>.<route-key>`), `name`, `resource_group_name` and
`location` are non-empty, (name, resource group) pairs are unique across entries
case-insensitively, route names are unique per table and free of `/`, `\`, `?`,
`%`, `next_hop_type` is one of the five documented values,
`next_hop_in_ip_address` is set only on `VirtualAppliance` routes and is a valid
IP address, `address_prefix` is a CIDR or a service tag, and tags respect the
50-entry / 512-char key / 256-char value limits.

### `route_tables` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Route table name. Validated loosely (non-empty) on purpose: Azure enforces its own naming rules at apply. Immutable — changing it forces replacement, and because a route's `route_table_name` is force-new, the route resources inside are recreated too (tags/BGP updates do not touch routes). |
| `resource_group_name` | `string` | — | Resource group the table lives in. Routes are always created in the same resource group as their table — `azurerm_route` takes the table's group, so a cross-group route is impossible by construction. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region for the table. Immutable — changing it forces replacement. |
| `bgp_route_propagation_enabled` | `bool` | `true` | Whether routes learned via BGP (ExpressRoute, VPN) propagate into this table. Set `false` for tables used for forced tunneling or firewall steering — you almost never want learned routes competing with UDRs there. |
| `routes` | `map(object)` | `{}` | User-defined routes, keyed by an arbitrary ID within the table. |
| `tags` | `map(string)` | `{}` | Tags on the route table. The tag set is authoritative — see Notes. Tags do not flow down to routes. |

### `routes` object (per route table)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Route name, unique within its table case-insensitively. Independent of the map key. Immutable — changing it forces replacement (the route's `route_table_name` and its own name are both force-new, so a renamed table or route recreates the route resource). |
| `address_prefix` | `string` | — | Destination: an IPv4/IPv6 CIDR (e.g. `10.1.0.0/16`, `fd00::/8`) or an Azure service tag (e.g. `ApiManagement`, `Storage.WestEurope`). Updated in place. |
| `next_hop_type` | `string` | — | One of `VirtualNetworkGateway`, `VnetLocal`, `Internet`, `VirtualAppliance`, `None` (case-sensitive). Updated in place. |
| `next_hop_in_ip_address` | `string` | `null` | IP of the appliance packets are forwarded to — only allowed (and validated) when `next_hop_type` is `VirtualAppliance`. Updated in place. |

## Outputs

| Name | Description |
|---|---|
| `route_table_ids` | Map of table key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/routeTables/<name>`). |
| `route_table_names` | Map of table key => route table name. azurerm resources take `route_table_name` (a name string), not an ID — hand this to other Azure network modules. |
| `route_ids` | Map of `<table-key>.<route-key>` => full ARM route resource ID (`.../routeTables/<table-name>/routes/<route-name>`). |
| `route_names` | Map of `<table-key>.<route-key>` => route name. |

## Example

```hcl
route_tables = {
  "hub-egress" = {
    name                          = "rt-hub-egress"
    resource_group_name           = "rg-platform-prod"
    location                      = "westeurope"
    bgp_route_propagation_enabled = false
    routes = {
      "firewall" = {
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.10.1.4"
      }
      "spoke-summary" = {
        address_prefix = "10.20.0.0/16"
        next_hop_type  = "VirtualAppliance"
        next_hop_in_ip_address = "10.10.1.4"
      }
    }
    tags = {
      env = "prod"
    }
  }
  "spoke-internet" = {
    name                = "rt-spoke-internet"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    routes = {
      "all" = {
        address_prefix = "0.0.0.0/0"
        next_hop_type  = "Internet"
      }
    }
  }
}
```

## Notes

- Inline `route` blocks are deliberately not exposed: the provider explicitly
  warns that a route table with in-line routes must not be combined with
  `azurerm_route` resources — the configurations conflict and overwrite each
  other. Everything here is the standalone kind, which also means routes can be
  added and removed without touching the table resource.
- Routes are always created in their table's resource group — the module derives
  `resource_group_name` and `route_table_name` from the table, so there is no
  per-route resource group input to get wrong.
- Azure's default system routes (`0.0.0.0/0` → Internet, VNet prefix →
  `VnetLocal`, etc.) stay in place underneath UDRs; the VNet's own prefix is
  always routed locally regardless of what you define.
- `bgp_route_propagation_enabled` defaults to `true` (Azure's default). Setting
  `false` stops learned BGP routes from entering the table — standard for
  forced-tunneling and firewall steering tables, unusual otherwise.
- Removing every route from a table is just removing the entries from `routes` —
  a table with zero routes is valid (contrast with the provider's inline-route
  note about explicitly emptying `route = []`; that subtlety does not exist
  here because routes are separate resources).
- Tags are authoritative for the route table's tag set: the provider PUTs the
  full configured map, so tags added in the portal or CLI are removed on the
  next apply with tag changes. Route resources carry no tags.
- `name` is validated loosely on purpose: Azure enforces its naming rules at
  apply, and resource group names may contain characters a conservative
  route-table regex would reject on the resource-group half of the ID.
- The caller needs `Microsoft.Network/routeTables/write` (and delete) on the
  resource group; routes additionally need
  `Microsoft.Network/routeTables/routes/write` (and delete).

## Import

```text
tofu import 'azurerm_route_table.route_table["<table-key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/routeTables/<table-name>"
tofu import 'azurerm_route.route["<table-key>.<route-key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/routeTables/<table-name>/routes/<route-name>"
```
