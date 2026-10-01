# azure/nat-gateway-association

Map-keyed module for attaching NAT gateways to subnets. Each entry creates one
`azurerm_subnet_nat_gateway_association` wiring a subnet's egress through a
NAT gateway, in the subscription configured on the provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subnet_nat_gateway_associations` | `map(object)` | — | Map of associations keyed by an arbitrary unique ID. |

Plan-time validation: `subnet_id` and `nat_gateway_id` are full ARM resource
IDs, and `subnet_id`s are unique across entries case-insensitively — a subnet
carries at most one NAT gateway association.

### `subnet_nat_gateway_associations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `subnet_id` | `string` | — | Full ARM resource ID of the subnet (typically `dependency.subnet.outputs.subnet_ids["workload"]` with the `azure/subnet` module). Immutable — changing it forces replacement. |
| `nat_gateway_id` | `string` | — | Full ARM resource ID of the NAT gateway (typically `dependency.nat.outputs.nat_gateway_ids["egress"]` with the `azure/nat-gateway` module). Immutable — changing it forces replacement. |

## Outputs

| Name | Description |
|---|---|
| `association_ids` | Map of key => association resource ID — the subnet's full ARM resource ID. |

## Example

```hcl
subnet_nat_gateway_associations = {
  "workload" = {
    subnet_id      = dependency.subnet.outputs.subnet_ids["workload"]
    nat_gateway_id = dependency.nat.outputs.nat_gateway_ids["egress"]
  }
}
```

## Notes

- Azure allows exactly one NAT gateway association per subnet; a second entry
  for the same subnet fails at apply. The plan-time `subnet_id` uniqueness
  validation rejects that earlier (it accepts configs the API would refuse).
- Letting a subnet re-route via a NAT gateway matters for egress control:
  without an association, the subnet's hosted services use their own IP
  configuration for outbound traffic — pair with the subnet's
  `default_outbound_access_enabled = false` scenario in `azure/subnet`.
- The association attaches to a NAT gateway managed elsewhere — gateway
  creation is not part of this module; feed the `azure/nat-gateway` module's
  `nat_gateway_ids` output in.
- Changing `subnet_id` or `nat_gateway_id` replaces the association resource.
- The caller needs subnet write permission
  (`Microsoft.Network/virtualNetworks/subnets/write` and delete) — the subnet
  is the resource the association attaches to.
- The association resource carries no tags.

## Import

`tofu import 'azurerm_subnet_nat_gateway_association.association["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<name>"`
