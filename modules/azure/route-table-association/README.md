# azure/route-table-association

Map-keyed module for attaching route tables to subnets. Each entry creates one
`azurerm_subnet_route_table_association` wiring a subnet's egress to a route
table, in the subscription configured on the provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subnet_route_table_associations` | `map(object)` | — | Map of associations keyed by an arbitrary unique ID. |

Plan-time validation: `subnet_id` and `route_table_id` are full ARM resource
IDs, and `subnet_id`s are unique across entries case-insensitively — a subnet
carries at most one route table association.

### `subnet_route_table_associations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `subnet_id` | `string` | — | Full ARM resource ID of the subnet (typically `dependency.subnet.outputs.subnet_ids["workload"]` with the `azure/subnet` module). Immutable — changing it forces replacement. |
| `route_table_id` | `string` | — | Full ARM resource ID of the route table (typically `dependency.routetable.outputs.route_table_ids["hub-egress"]` with the `azure/route-table` module). Immutable — changing it forces replacement. |

## Outputs

| Name | Description |
|---|---|
| `association_ids` | Map of key => association resource ID — the subnet's full ARM resource ID. |

## Example

```hcl
subnet_route_table_associations = {
  "workload" = {
    subnet_id      = dependency.subnet.outputs.subnet_ids["workload"]
    route_table_id = dependency.routetable.outputs.route_table_ids["hub-egress"]
  }
}
```

## Notes

- Azure allows exactly one route table association per subnet; a second entry
  for the same subnet fails at apply. The plan-time `subnet_id` uniqueness
  validation rejects that earlier — at plan, not at apply.
- With an association, the subnet's egress follows the table's user-defined
  routes; without one, the subnet uses Azure's default system routes only.
  The table's `bgp_route_propagation_enabled` setting decides whether learned
  BGP routes also enter — see `azure/route-table`.
- The association attaches to a route table managed elsewhere — table and route
  creation are not part of this module; feed the `azure/route-table` module's
  `route_table_ids` output in.
- Use this resource only with subnets managed as standalone `azurerm_subnet`
  resources — an inline subnet inside `azurerm_virtual_network` carries its own
  `route_table_id`, and both mechanisms on one subnet conflict. `azure/subnet`
  creates standalone subnets, so consumers of that module are fine.
- Changing `subnet_id` or `route_table_id` replaces the association resource.
- The caller needs subnet write permission
  (`Microsoft.Network/virtualNetworks/subnets/write` and delete); attaching the
  table can additionally require
  `Microsoft.Network/routeTables/join/action` on the route table.
- The association resource carries no tags.

## Import

`tofu import 'azurerm_subnet_route_table_association.association["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<name>"`
