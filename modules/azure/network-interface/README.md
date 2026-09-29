# azure/network-interface

Map-keyed module for Azure network interfaces. Each entry creates one
`azurerm_network_interface` with its IP configurations as inline blocks, in
the named resource group, in the subscription configured on the provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `network_interfaces` | `map(object)` | — | Map of network interfaces keyed by an arbitrary unique ID. |

Plan-time validation: `name`, `resource_group_name` and `location` are
non-empty, (name, resource group) pairs are unique across entries
case-insensitively, every entry carries a non-empty `ip_configurations` map,
entries with two or more configurations designate exactly one as `primary`,
allocations are `Dynamic`/`Static` with `private_ip_address` set exactly for
Static, private IPs are valid literals matching their version, at most one
IPv6 configuration per NIC, `subnet_id` and `public_ip_address_id` are full
ARM resource IDs, `dns_servers` entries are IPv4 literals, configuration
keys are non-empty, and tags respect the 50-entry / 512-char key / 256-char
value limits.

### `network_interfaces` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Network interface name. Validated loosely (non-empty) on purpose: Azure enforces its own naming rules at apply. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the NIC lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region for the NIC — usually the region of its virtual network. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `dns_servers` | `list(string)` | `[]` | Custom DNS server IPv4 addresses for this NIC (IPv4-only is a module choice, mirroring `azure/virtual-network`'s `dns_servers`). Configuring DNS on the NIC overrides the virtual network's DNS servers for it. |
| `internal_dns_name_label` | `string` | `null` | Internal DNS name label used for the NIC's internal FQDN. Updated in place. |
| `accelerated_networking_enabled` | `bool` | `false` | Single-root I/O virtualization (SR-IOV) for the NIC — VM-size dependent: ARM rejects unsupported sizes at apply, and toggling it on an attached NIC may require the VM deallocated. Updated in place. |
| `ip_forwarding_enabled` | `bool` | `false` | IP forwarding for NICs acting as appliances or routers. Updated in place. |
| `tags` | `map(string)` | `{}` | Tags on the NIC. The tag set is authoritative — tags do not flow to attached public IPs or the attached VM. |
| `ip_configurations` | `map(object)` | — | IP configurations for the NIC, keyed by an arbitrary identifier — the map key doubles as the configuration block's `name`. Required and non-empty: the provider requires at least one configuration. |

### `ip_configurations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `subnet_id` | `string` | — | Full ARM resource ID of the subnet to attach (typically `dependency.subnet.outputs.subnet_ids["workload"]` with the `azure/subnet` module). This module always attaches the NIC to a subnet — see Notes. Updated in place (same-vnet subnet moves only). |
| `private_ip_address_allocation` | `string` | — | `Dynamic` or `Static` (case-sensitive). |
| `private_ip_address` | `string` | `null` | Static private IP, required exactly when `private_ip_address_allocation` is `Static` (validated both ways). ARM validates it sits within the subnet's range at apply. |
| `private_ip_address_version` | `string` | `IPv4` | `IPv4` or `IPv6` (case-sensitive). At most one IPv6 configuration per NIC (validated); the subnet needs IPv6 prefixes for it. |
| `public_ip_address_id` | `string` | `null` | Full ARM resource ID of a public IP to associate (typically `dependency.pip.outputs.public_ip_ids["ingress"]` with the `azure/public-ip` module). |
| `primary` | `bool` | `false` | Marks the primary configuration. Entries with two or more configurations must set exactly one `primary = true` (validated, mirroring the provider); a single-configuration NIC does not need the flag. |

## Outputs

| Name | Description |
|---|---|
| `network_interface_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/networkInterfaces/<name>`). |
| `network_interface_names` | Map of key => network interface name. |
| `network_interface_private_ips` | Map of key => list of private IPs across the NIC's IP configurations — a NIC can carry several; consumers wanting "the" IP take the primary's. |

## Example

```hcl
network_interfaces = {
  "workload" = {
    name                = "nic-workload-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    ip_configurations = {
      "primary" = {
        subnet_id                     = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-platform-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform-prod/subnets/snet-workload"
        private_ip_address_allocation = "Dynamic"
        primary                       = true
      }
      "storage" = {
        subnet_id                     = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-platform-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform-prod/subnets/snet-workload"
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.1.10"
        private_ip_address_version    = "IPv4"
        primary                       = false
      }
    }
    accelerated_networking_enabled = true
    tags = {
      env = "prod"
    }
  }
}
```

## Notes

- IP configurations are inline blocks fed by the nested `ip_configurations`
  map. The standalone `azurerm_network_interface_ip_configuration` resource
  was removed from the provider in 4.0 — IP configurations are part of the
  NIC's own payload with no separate ARM resource or import ID, so they are
  managed inline here and nothing else can manage them on these NICs.
- The `ip_configurations` map key doubles as the configuration's `name` —
  pick keys you would accept as a name (letters, digits, hyphens,
  underscores). Azure enforces the name charset at apply.
- Provider primary rule, mirrored at plan time: NICs with two or more IP
  configurations need exactly one designated `primary = true`; a
  single-configuration NIC does not need the flag.
- Static allocation requires `private_ip_address` within the subnet's range
  — ARM validates at apply; the module checks the literal format only.
- Public IP association: wire `public_ip_ids` from `azure/public-ip` into
  `public_ip_address_id`. Standard/StandardV2 public IPs are Static-only, an
  IP attaches to one configuration only, and destroying an associated IP
  needs disassociation first (see azure/public-ip's Notes for the
  create_before_destroy guidance):

  ```hcl
  dependency "pip" {
    config_path = "../public-ip"
  }

  # inside ip_configurations:
  public_ip_address_id = dependency.pip.outputs.public_ip_ids["ingress"]
  ```
- NSG association is not managed here: use
  `azurerm_network_interface_security_group_association` fed by
  `network_interface_ids` and `azure/network-security-group`'s
  `network_security_group_ids`:

  ```hcl
  resource "azurerm_network_interface_security_group_association" "workload" {
    network_interface_id      = dependency.nic.outputs.network_interface_ids["workload"]
    network_security_group_id = dependency.nsg.outputs.network_security_group_ids["workload"]
  }
  ```
- `name`, `resource_group_name` and `location` force replacement if changed;
  everything else — DNS servers, DNS label, accelerated networking, IP
  forwarding, IP configurations, tags — updates in place. Toggling
  accelerated networking may need the attached VM deallocated first.
- `dns_servers` IPv4-only is a module choice (mirroring
  `azure/virtual-network`), not an Azure restriction. NIC-level DNS
  configuration overrides the virtual network's DNS servers for this NIC.
- This module always attaches the NIC to a subnet: `subnet_id` is required
  here while the provider makes it Optional (required only for IPv4
  configurations) — a deliberate strictness choice.
- IPv6 configurations need IPv6 prefixes on the target subnet; at most one
  IPv6 configuration per NIC (validated).
- Wiring chain: `azure/subnet`'s `subnet_ids` → `subnet_id`;
  `azure/public-ip`'s `public_ip_ids` → `public_ip_address_id`;
  `network_interface_ids` → `azure/virtual-machine`'s
  `network_interface_ids`.
- The caller needs `Microsoft.Network/networkInterfaces/write` (and delete)
  on the resource group; the identity attaching the NIC to a VM additionally
  needs `Microsoft.Network/networkInterfaces/join/action` on the NIC.
- Not exposed, deliberately: `edge_zone` (extended zones;
  `azure/virtual-network` exposes the vnet-level attribute),
  `auxiliary_mode`/`auxiliary_sku` (SR-IOV offload shapes), gateway load
  balancer frontend IP configurations, and the NIC-level
  `network_security_group_id` argument (unused in favor of the association
  resource, as with `azure/subnet`).

## Import

`tofu import 'azurerm_network_interface.network_interface["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/networkInterfaces/<name>"`
