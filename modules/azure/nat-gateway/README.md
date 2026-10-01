# azure/nat-gateway

Map-keyed module for Azure NAT gateways. Each entry creates one
`azurerm_nat_gateway` plus the associations that attach public IPs and public
IP prefixes to it, referencing IPs managed elsewhere (typically the
`azure/public-ip` module).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `nat_gateways` | `map(object)` | — | Map of NAT gateways keyed by an arbitrary unique ID. Map keys must not contain `.` — they are composed into association output keys. |

Plan-time validation: `name`, `resource_group_name` and `location` non-empty,
`sku_name` limited to the two supported SKUs, `zones` empty for StandardV2 and
at most a single zone `1`/`2`/`3` for Standard, `idle_timeout_in_minutes`
between 4 and 120, IP/prefix references are full ARM resource IDs, and tags
within Azure's limits.

### `nat_gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | NAT gateway name. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the gateway is created in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region, e.g. `westeurope`. Immutable — changing it forces replacement. |
| `sku_name` | `string` | `Standard` | `Standard` (zonal-capable) or `StandardV2` (zone-redundant by design, no `zones` allowed). Immutable — changing it forces replacement. |
| `idle_timeout_in_minutes` | `number` | `4` | Idle TCP connection timeout, 4–120 minutes. |
| `zones` | `list(string)` | `[]` | At most one element, `1`/`2`/`3`, for Standard only; omitted for StandardV2. Immutable — changing it forces replacement. |
| `public_ip_address_ids` | `list(string)` | `[]` | Public IP resource IDs to associate, e.g. `dependency.pip.outputs.public_ip_ids["egress-*"]` with the `azure/public-ip` module. |
| `public_ip_prefix_ids` | `list(string)` | `[]` | Public IP prefix resource IDs to associate. |
| `tags` | `map(string)` | `{}` | Tags. |

## Outputs

| Name | Description |
|---|---|
| `nat_gateway_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/natGateways/<name>`). |
| `nat_gateway_names` | Map of key => NAT gateway name. |
| `nat_gateway_resource_guids` | Map of key => Azure resource GUID. |
| `public_ip_association_ids` | Map of `<gateway_key>.pip<index>` => Terraform association ID (`<natGatewayID>|<publicIPAddressID>`). |
| `public_ip_prefix_association_ids` | Map of `<gateway_key>.prefix<index>` => Terraform association ID (`<natGatewayID>|<publicIPPrefixID>`). |

## Example

```hcl
nat_gateways = {
  "egress" = {
    name                = "ng-egress-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    sku_name            = "Standard"
    zones = [
      "1",
    ]
    public_ip_address_ids = [
      dependency.public_ip.outputs.public_ip_ids["egress-1"],
      dependency.public_ip.outputs.public_ip_ids["egress-2"],
    ]
  }
}
```

## Notes

- **Gateway vs SKU matching.** A `Standard` gateway requires `Standard` public
  IPs/prefixes; a `StandardV2` gateway requires `StandardV2`. IPv6 addresses
  require a StandardV2 gateway. The API rejects mismatched combinations — this
  module passes the IDs through and the error surfaces at apply.
- **Density: up to 16 addresses.** A gateway attaches IPs and prefixes in
  any combination totaling at most 16 addresses: `Standard` up to 16 IPv4
  addresses (IPv6 is not supported), `StandardV2` up to 16 IPv4 plus 16
  IPv6 simultaneously. A prefix counts by its size — /28 is 16 addresses,
  /29 is 8, /30 is 4, /31 is 2. Prefix sizes and IP versions cannot be
  derived from ARM resource IDs, so this module's plan-time validation
  only rejects the unambiguous bounds (17+ address resources on
  `Standard`, 33+ on `StandardV2`) and the API enforces the combined cap
  at apply. Each address adds 64,512 SNAT ports to the inventory.
- **A gateway with no IPs is valid but useless.** Azure lets you create a bare
  NAT gateway; it provides no outbound address until associated — attach
  `public_ip_address_ids` or `public_ip_prefix_ids` in practice.
- **Subnet association lives elsewhere.** `azurerm_subnet_nat_gateway_association`
  wires a subnet's outbound traffic to the gateway. It is deliberately not
  managed here (the `azure/subnet` module does not expose the association
  either); feed this module's `nat_gateway_ids` output into the association
  resource in the consumer:

  ```hcl
  resource "azurerm_subnet_nat_gateway_association" "workload" {
    nat_gateway_id = dependency.nat.outputs.nat_gateway_ids["egress"]
    subnet_id      = dependency.subnet.outputs.subnet_ids["workload"]
  }
  ```

- IP and prefix associations are separate resources keyed
  `<gateway_key>.pip<index>` / `<gateway_key>.prefix<index>` — the index refers
  to the entry's position in its `public_ip_address_ids`/`public_ip_prefix_ids`
  list, so keep list ordering stable across runs.
- `azurerm_nat_gateway_public_ip_association` and prefix association accept
  IP/prefix references from any resource group or subscription — the gateway
  itself is scoped to location and resource group at creation time.
- The caller needs `Microsoft.Network/natGateways/write` and delete.

## Import

```shell
tofu import 'azurerm_nat_gateway.nat_gateway["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/natGateways/<name>"
tofu import 'azurerm_nat_gateway_public_ip_association.public_ip["<key>.pip<index>"]' "<natGatewayID>|<publicIPAddressID>"
tofu import 'azurerm_nat_gateway_public_ip_prefix_association.public_ip_prefix["<key>.prefix<index>"]' "<natGatewayID>|<publicIPPrefixID>"
```
