# azure/network-security-group

Map-keyed module for Azure network security groups, with security rules as
separate `azurerm_network_security_rule` resources rather than inline
`security_rule` blocks — the provider warns the two shapes cannot be mixed
(inline and standalone rules overwrite each other), so this module commits
to the standalone shape.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `network_security_groups` | `map(object)` | — | Map of network security groups keyed by an arbitrary unique ID; each entry also carries its `security_rules` map. |

Plan-time validation: group and rule map keys are `.`-free, (name, resource
group) pairs are unique across entries case-insensitively, `name`,
`resource_group_name` and `location` are non-empty, rule priorities are
100–4096 and unique per direction within each group, direction/access/protocol
match the allowed enums case-sensitively, each side sets exactly one port
form (singular or plural) and exactly one of the address trio, port strings
stay within 0–65535 (ranges ordered), singular address prefixes are
non-empty with plural prefixes limited to CIDRs or `*`, descriptions are
≤ 140 chars, ASG ID lists start with `/` and hold at most 10 IDs, rule names
exclude `/`, `\`, `?`, `%` and are unique per group case-insensitively, and
tags respect the 50-entry / 512-char key / 256-char value limits.

### `network_security_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Network security group name. Unique within the resource group, case-insensitively. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the group lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `tags` | `map(string)` | `{}` | Tags on the network security group. The tag set is authoritative — see Notes. |
| `security_rules` | `map(object)` | `{}` | Security rules for the group, keyed by an arbitrary rule identifier — see the rule object below. Created as separate rule resources keyed `<group-key>.<rule-key>`. |

### `security_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Azure-side rule name — independent of the map key, which is only Terraform's handle. The name appears in import IDs and must be unique within the group, case-insensitively, without `/`, `\`, `?` or `%`. Force-new. |
| `priority` | `number` | — | Rule priority, 100–4096; lower numbers are evaluated first. Unique per direction within the group. |
| `direction` | `string` | — | `Inbound` or `Outbound` (case-sensitive). |
| `access` | `string` | — | `Allow` or `Deny` (case-sensitive). |
| `protocol` | `string` | — | `Tcp`, `Udp`, `Icmp`, `Esp`, `Ah` or `*` for any protocol (case-sensitive). |
| `description` | `string` | `null` | Rule description, at most 140 characters. |
| `source_port_range` | `string` | — | Source ports: `*`, a port 0–65535, or a range `from-to` (e.g. `1000-2000`). Mutually exclusive with `source_port_ranges` — exactly one per side. |
| `source_port_ranges` | `list(string)` | — | List of source port strings, same format as above. Mutually exclusive with `source_port_range`. |
| `destination_port_range` | `string` | — | Destination ports, same format as `source_port_range`. Mutually exclusive with `destination_port_ranges`. |
| `destination_port_ranges` | `list(string)` | — | List of destination port strings. Mutually exclusive with `destination_port_range`. |
| `source_address_prefix` | `string` | — | A service tag (`VirtualNetwork`, `AzureLoadBalancer`, `Internet`, `Sql.WestEurope`, `Storage.EastUS`, ...), the wildcard `*`, or a CIDR. Exactly one of the source trio (see below). |
| `source_address_prefixes` | `list(string)` | — | List of CIDRs (IPv4 or IPv6) or `*` — service tags are not accepted in the plural form. |
| `source_application_security_group_ids` | `list(string)` | — | Up to 10 full ARM IDs of application security groups as the source. |
| `destination_address_prefix` | `string` | — | Same semantics as `source_address_prefix`, for the destination side. |
| `destination_address_prefixes` | `list(string)` | — | Same semantics as `source_address_prefixes`, for the destination side. |
| `destination_application_security_group_ids` | `list(string)` | — | Same semantics as `source_application_security_group_ids`, for the destination side. |

Each rule must have **exactly one** source and **exactly one** destination:
one of `{source_, destination_}address_prefix`,
`{source_, destination_}address_prefixes` or
`{source_, destination_}application_security_group_ids` — the provider
enforces exactly-one-of across each side's trio, so prefixes and ASG IDs do
not compose. Ports follow the same rule per side: the singular string or the
plural list, never both.

## Outputs

| Name | Description |
|---|---|
| `network_security_group_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<name>`). |
| `network_security_group_names` | Map of key => network security group name. azurerm resources take `network_security_group_name` (a name string), not an ID — hand this to other Azure network modules. |
| `security_rule_ids` | Map of composed key `<group-key>.<rule-key>` => full ARM resource ID of the rule (`.../networkSecurityGroups/<nsg>/securityRules/<rule-name>`). |

## Example

```hcl
network_security_groups = {
  "workload" = {
    name                = "nsg-workload"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    security_rules = {
      "allow-https-in" = {
        name                       = "AllowHTTPSIn"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "VirtualNetwork"
      }
      "allow-all-out" = {
        name                       = "AllowAllOut"
        priority                   = 4090
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "Internet"
      }
    }
  }
}
```

## Notes

- Rules are separate `azurerm_network_security_rule` resources: inline
  `security_rule` blocks conflict with standalone rule resources, so this
  module never emits inline blocks. Removing a rule from the input map
  destroys exactly that rule. Rule resource addresses are composed as
  `<group-key>.<rule-key>` — hence neither key level may contain `.`.
- The rule's `name` (Azure-side identity, used in import IDs) is independent
  of the map key: keys are Terraform handles, names are what Azure sees.
  Names must be unique within each group, case-insensitively — the module
  rejects duplicates at plan time.
- Priorities must be unique per direction within each network security group
  (Azure enforces this; the module checks at plan time). Azure's own default
  rules (AllowVnetInBound, AllowVnetOutBound, ...) sit at priority 65000+ and
  are not managed or visible here — a group with no `security_rules` entries
  still allows intra-vnet traffic through those defaults.
- Ports are strings the provider passes through without bounds validation —
  hence the module-side 0–65535 checks. Use `*` for any port.
- Service tags are only accepted in the singular
  `{source_, destination_}address_prefix`; the plural lists take CIDRs or `*`
  only. Unknown service tags fail at apply with ARM's error — the module
  passes them through unchecked.
- Rule `name`, `resource_group_name` and `network_security_group_name` force
  replacement if changed; every other rule attribute updates in place. The
  group's `name`, `resource_group_name` and `location` force replacement.
- Tags are authoritative for the network security group's tag set; tags do
  not flow down to the rules (rules carry no tags in Azure).
- Attach groups to subnets (or NICs) with the dedicated association
  resources fed by this module's outputs, e.g.:

  ```hcl
  resource "azurerm_subnet_network_security_group_association" "workload" {
    subnet_id                 = dependency.subnet.outputs.subnet_ids["workload"]
    network_security_group_id = dependency.nsg.outputs.network_security_group_ids["workload"]
  }
  ```
- The caller needs `Microsoft.Network/networkSecurityGroups/write` (and
  delete) on the resource group; rules ride the same permission.

## Import

`tofu import 'azurerm_network_security_group.network_security_group["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<name>"`

`tofu import 'azurerm_network_security_rule.security_rule["<group-key>.<rule-key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<nsg>/securityRules/<rule-name>"`
