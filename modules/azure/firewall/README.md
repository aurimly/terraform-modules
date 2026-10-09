# azure/firewall

> **Provider floor** — developed against the `azurerm` provider v5.x
> (v5.9.0 at build time); nothing is pinned in-module — pin the provider
> version at the consumer's root Terragrunt level.

Map-keyed module for Azure Firewalls. Each entry creates one `azurerm_firewall`
in the named resource group — as a virtual-network firewall (`AZFW_VNet`, with
`ip_configurations` referencing the dedicated `AzureFirewallSubnet`) or as a
secure-hub firewall (`AZFW_Hub`, referencing a Virtual Hub). Optional
companion resources are in-module: public IPs for the IP configurations,
firewall policies, and the policies' rule collection groups. Outside companion
resources bind by full ARM resource ID anywhere a map key is accepted.

## Destroy semantics (read before using)

- Removing a policy key destroys the policy and, through policy rules, the
  firewall's policy-based protection. A firewall takes its threat
  intelligence, DNS and private-range settings from an attached policy —
  detaching a policy reverts those to the firewall-side classic settings.
- Removing a public IP referenced by an IP configuration can fail at apply:
  the IP destroy runs before the firewall drops the reference. Remove the
  IP configuration first (keep the IP), apply, then remove the IP entry.
- Renaming the firewall or a policy (`name`) replaces the resource.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `firewalls` | `map(object)` | — | Map of firewalls keyed by an arbitrary unique ID. |
| `public_ips` | `map(object)` | `{}` | In-module public IPs for firewall IP configurations, keyed by an arbitrary ID. |
| `firewall_policies` | `map(object)` | `{}` | Firewall policies keyed by an arbitrary ID; referenced by `firewall_policy_key`. |
| `firewall_policy_rule_collection_groups` | `map(object)` | `{}` | Rule collection groups attached to `firewall_policies` entries; output keys compose `<policy_key>.<group_key>`. |

Map keys must not contain `.` at any level — keys compose into resource and
output identifiers (`<policy_key>.<group_key>`).

Plan-time validation: names, resource groups and locations non-empty and
firewall names unique per resource group case-insensitively (the Azure name
format validated); `sku_name`/`sku_tier` within the documented values;
VNet firewalls with exactly one subnet-backed ip_configuration and hub
firewalls with a Virtual Hub only; IP-configuration subnet IDs ending in
`/subnets/AzureFirewallSubnet` (management in
`/subnets/AzureFirewallManagementSubnet`); every IP configuration (and the
management configuration, mandatory there) carrying exactly one public IP by
`public_ip_key` or ARM ID with a distinct management name; policy-attachment
pass-throughs exclusive; DNS-proxy with servers, bare-IPv4 server entries;
private ranges as CIDRs or `IANAPrivateRanges`; group/collection/rule
priorities in range and unique per group; group names unique per policy;
NAT collections restricted to `Dnat` with at most one destination port and
exactly one translation target; and tags within Azure's limits.

### `firewalls` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Firewall name. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the firewall lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `sku_name` | `string` | `AZFW_VNet` | `AZFW_VNet` (virtual-network firewall) or `AZFW_Hub` (secure hub). Immutable — changing it forces replacement. |
| `sku_tier` | `string` | `Standard` | `Basic`, `Standard` or `Premium`. Tier upgrades apply in place; the API pairs tiers with the firewall's throughput needs, so check the tier matrix for Basic/Standard/Premium limits (full hub firewalls support all tiers). |
| `firewall_policy_key` | `string` | `null` | Key into `firewall_policies` for an in-module policy — set either this or `firewall_policy_id`. |
| `firewall_policy_id` | `string` | `null` | Full ARM resource ID of an external policy, e.g. one from another module invocation sharing a central policy. |
| `threat_intel_mode` | `string` | `Alert` | Classic threat intelligence: `Alert`, `Deny` or `Off`. Governed by an attached policy when there is one — leave at the default for policy-based firewalls (see Notes). |
| `dns_servers` | `list(string)` | `[]` | Custom DNS servers (bare IPv4). Governed by a policy `dns` block when a policy is attached. |
| `dns_proxy_enabled` | `bool` | `null` | Azure Firewall DNS proxy. Requires `dns_servers` (validated); governed by the policy `dns` block when a policy is attached. Note the reverse direction too: with `dns_servers` set, Azure reports the proxy as enabled even when this flag is left unset. |
| `private_ip_ranges` | `list(string)` | `null` | SNAT private ranges — CIDRs or `IANAPrivateRanges`. Governed by a policy's `private_ip_ranges` when a policy is attached. |
| `zones` | `list(string)` | `[]` | Availability zones `1`/`2`/`3`. Immutable — changing it forces replacement. |
| `ip_configurations` | `map(object)` | `{}` | VNet Firewall IP configurations (see below) — VNet firewalls need at least one entry with exactly one subnet, hub firewalls none (validated). |
| `management_ip_configuration` | `object` | `null` | Forced-tunnelling management block (see below). Immutable — adding, removing or changing its subnet forces replacement. |
| `virtual_hub` | `object` | `null` | Hub firewall wiring: `virtual_hub_id` plus `public_ip_count` (default 1) for the hub-created public IPs. `AZFW_Hub` requires it (validated) — hub firewalls also require an attached policy (validated). |
| `tags` | `map(string)` | `{}` | Tags. |

`ip_configurations` entries:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | IP configuration name, unique within the firewall (the management configuration's name must differ, validated). Immutable — changing it forces replacement. |
| `subnet_id` | `string` | `null` | Full ARM resource ID of the firewall subnet — the name (last segment) must be `AzureFirewallSubnet`, /26 or larger (validated). Exactly one configuration carries the subnet (validated); further configurations reuse it. Immutable — changing it forces replacement. |
| `public_ip_key` | `string` | `null` | Key into `public_ips` — sets the configuration's public IP from the in-module pool. Exactly one of this or `public_ip_address_id` (validated). |
| `public_ip_address_id` | `string` | `null` | Full ARM resource ID of an existing Standard public IP — typically `dependency.pip.outputs.public_ip_ids["egress-1"]` with the `azure/public-ip` module. |

`management_ip_configuration` entries (when set) add:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Management configuration name, distinct from every IP-configuration name (validated). |
| `subnet_id` | `string` | — | Full ARM resource ID of the dedicated management subnet, named `AzureFirewallManagementSubnet` (validated, /26 or larger). |
| `public_ip_key` / `public_ip_address_id` | `string` | `null` | Exactly one, as for IP configurations (validated) — a management configuration always requires a public IP. |

### `public_ips` object

Trimmed from the `azure/public-ip` module to what firewall IPs allow.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Public IP name. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the IP lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `availability_zone` | `string` | `null` | Zone pinning `1`/`2`/`3`. Immutable — changing it forces replacement. |
| `tags` | `map(string)` | `{}` | Tags. |

Trimmed from the `azure/public-ip` module because Azure Firewall only accepts
Standard/Static/IPv4 public IPs: those three attributes are pinned in-module
(`allocation_method` = `Static`, `sku` = `Standard`, `ip_version` = `IPv4`)
and not exposed. FQDN labels are likewise dropped — firewall IP addresses are
bare addresses; use `azure/public-ip` when you need a labelled IP.

### `firewall_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy name. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the policy lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `sku` | `string` | `Standard` | `Standard`, `Premium` or `Basic`. Immutable — changing it forces replacement. |
| `base_policy_id` | `string` | `null` | Full ARM ID of a parent policy to inherit rule collections and settings from. |
| `dns` | `object` | `null` | Policy-level DNS: `proxy_enabled` (default `false`) and `servers` (bare IPv4 addresses). |
| `threat_intelligence_mode` | `string` | `Alert` | `Alert`, `Deny` or `Off`. |
| `threat_intelligence_allowlist` | `object` | `null` | Allowlist additions to threat intelligence: `ip_addresses` (IPv4/CIDRs) and/or `fqdns` — at least one (validated). |
| `private_ip_ranges` | `list(string)` | `null` | SNAT private ranges — CIDRs or `IANAPrivateRanges`. |
| `auto_learn_private_ranges_enabled` | `bool` | `null` | Switch from listed ranges to automatic SNAT private-range learning; conflicts with `private_ip_ranges` (validated). |
| `sql_redirect_allowed` | `bool` | `null` | Permit SQL redirection bypass (Premium context). |
| `tags` | `map(string)` | `{}` | Tags. |

Deliberately not exposed (pass-through candidates for a later minor):
`insights`/`intrusion_detection` (IDPS), `tls_certificate`/`identity`
(TLS inspection/managed identity), and `explicit_proxy` (Premium proxy on policy).

### `firewall_policy_rule_collection_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `firewall_policy_key` | `string` | — | Key into `firewall_policies` the group attaches to (validated). |
| `name` | `string` | — | Group name, unique within the referenced policy (validated). |
| `priority` | `number` | — | Group priority, 100–65000 (validated), unique per policy across groups. |
| `application_rule_collections` | `map(object)` | `{}` | Application (L7) collections, see below. |
| `network_rule_collections` | `map(object)` | `{}` | Network (L3/L4) collections, see below. |
| `nat_rule_collections` | `map(object)` | `{}` | NAT (DNAT) collections, see below. |

All three collection types share the frame:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Collection name, unique within the group across all types (validated). |
| `priority` | `number` | — | Collection priority, 100–65000, unique across all three types in the group (validated). |
| `action` | `string` | — | `Allow` or `Deny` for application/network collections (validated); collections of `Dnat` type only for NAT (validated). |
| `rules` | `map(object)` | — | The rules, keyed by an arbitrary ID — names must be unique within the collection (validated). |

Application rules shape: `name`, `description`, `protocols` (map of
`{ type = "Http" | "Https" | "Mssql" }` with `port` 0–64000; validated),
`source_addresses`, `source_ip_groups` and the destination shapes
`destination_addresses`, `destination_fqdns`, `destination_fqdn_tags`,
`destination_urls` (HTTPS URLs - conflicts with `destination_fqdns`,
validated; requires `terminate_tls = true`, validated — Premium feature, the
API does not verify the SKU at plan time), `web_categories`, `terminate_tls`
and `http_headers` (`{ name, value }` entries).

Network rules shape: `name`, `description`, `protocols` (non-empty list of
`Any`/`TCP`/`UDP`/`ICMP`; validated), `source_addresses`, `source_ip_groups`,
`destination_ports`, `destination_addresses`, `destination_ip_groups`,
`destination_fqdns`.

NAT rules shape: `name`, `description`, `protocols` (non-empty list of
`TCP`/`UDP`; validated), `source_addresses`, `source_ip_groups`,
`destination_address` (the firewall's public IP; ports), `destination_ports`
(at most one port or port range 1–64000, validated), `translated_address` or
`translated_fqdn` (exactly one, validated), `translated_port`
(0–64000, required).

Note: the Azure provider registry docs list application protocol types as
`Http`/`Https` only, but `Mssql` is accepted by the API and provider (added in
azurerm 3.27) — kept as a documented type here.

## Outputs

| Name | Description |
|---|---|
| `firewall_ids` | Map of firewall key => full ARM resource ID (`/.../azureFirewalls/<name>`). |
| `firewall_names` | Map of firewall key => firewall name. |
| `firewall_private_ip_addresses` | Map of firewall key => list of private IPs across its ip_configurations (empty for hub firewalls). |
| `firewall_hub_private_ip_addresses` | Map of firewall key => hub address details (`private_ip_address` plus `public_ip_addresses`) or `null` for VNet firewalls. |
| `firewall_policy_ids` | Map of policy key => full ARM resource ID (`/.../firewallPolicies/<name>`). |
| `firewall_policy_names` | Map of policy key => policy name. |
| `rule_collection_group_ids` | Map of `<policy_key>.<group_key>` => full ARM resource ID (`<policyID>/ruleCollectionGroups/<name>`). |
| `public_ip_ids` | Map of public_ips key => ARM ID — pass to other resources (in-module IPs only). |
| `public_ip_addresses` | Map of public_ips key => assigned address (`null` until assigned). |

## Example

```hcl
firewalls = {
  "egress" = {
    name                = "fw-platform-prod"
    resource_group_name = "rg-network-prod"
    location            = "westeurope"
    sku_name            = "AZFW_VNet"
    sku_tier            = "Premium"
    firewall_policy_key = "egress"

    zones = [
      "1",
      "2",
      "3",
    ]
    ip_configurations = {
      "primary" = {
        name          = "pip-fw-primary"
        subnet_id     = dependency.subnet.outputs.subnet_ids["azure-firewall"]
        public_ip_key = "egress"
      }
    }
  }
}

public_ips = {
  "egress" = {
    name                = "pip-fw-egress-prod"
    resource_group_name = "rg-network-prod"
    location            = "westeurope"
    availability_zone   = "1"
  }
}

firewall_policies = {
  "egress" = {
    name                = "fwp-egress-prod"
    resource_group_name = "rg-network-prod"
    location            = "westeurope"
  }
}

firewall_policy_rule_collection_groups = {
  "egress-base" = {
    firewall_policy_key = "egress"
    name                = "rgp-egress"
    priority            = 100

    application_rule_collections = {
      "allow-microsoft" = {
        name     = "arc-allow-microsoft"
        priority = 100
        action   = "Allow"

        rules = {
          "update-endpoints" = {
            name = "ar-allow-updates"

            protocols = {
              "update-https" = {
                type = "Https"
                port = 443
              }
            }

            source_addresses      = ["192.168.1.0/24"]
            destination_fqdn_tags = ["WindowsUpdate"]
          }
        }
      }
    }

    network_rule_collections = {
      "allow-internal" = {
        name     = "nrc-allow-internal"
        priority = 100
        action   = "Allow"

        rules = {
          "internal-dns" = {
            name                = "nr-allow-dns"
            protocols           = ["UDP"]
            destination_ports   = ["53"]
            source_addresses    = ["192.168.1.0/24"]
            destination_addresses = ["10.0.0.10"]
          }
        }
      }
    }
  }
}
```

## Notes

- **Subnet prerequisites.** The `AzureFirewallSubnet` must be /26 or larger in
  the firewall's virtual network, created before via `azure/subnet` — the
  subnet name is validated by the ID suffix. Forced tunnelling additionally
  requires `AzureFirewallManagementSubnet` in the same virtual network.
- **Policy vs classic settings.** When a firewall attaches a policy, Azure
  governs threat intelligence, DNS (proxy and servers), and SNAT private
  ranges through the policy — Azure lets the same values send the
  firewall-side classic attributes (`threat_intel_mode`, `dns_servers`,
  `dns_proxy_enabled`, `private_ip_ranges`) alongside, but for policy-owned
  configurations the policy is authoritative. Leave them at default when
  attaching `firewall_policy_key`/`firewall_policy_id`.
- **`sku_tier` updates in place** (`Basic` ↔ `Standard` ↔ `Premium` per the
  tier matrix); `sku_name`, `name`, resource group, location, `zones`,
  IP-configuration subnets and the management configuration changes force
  replacement.
- **Basic tier works on both shapes** — `AZFW_VNet` and `AZFW_Hub` (per the
  Azure CLI docs) — no in-module tier/SKU-name cross-check.
- **Public IP requirements.** Azure Firewall requires Standard SKU, Static,
  IPv4 public IPs on every IP configuration; the in-module `public_ips` pins
  that (this module). Externally supplied IDs (`public_ip_address_id`) are the
  consumer's responsibility — the API rejects mismatched SKUs at apply.
- **Removing an IP configuration can fail** — see Destroy semantics; the
  two-step removal (configuration first, then the IP) is the supported way.
- The caller needs `Microsoft.Network/azureFirewalls/write`,
  `Microsoft.Network/firewallPolicies/write`,
  `Microsoft.Network/publicIPAddresses/write` plus join permission to place
  the firewall in the subnet.

## Import

```shell
tofu import 'azurerm_firewall.firewall["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/azureFirewalls/<name>"
tofu import 'azurerm_firewall_policy.policy["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/firewallPolicies/<name>"
tofu import 'azurerm_firewall_policy_rule_collection_group.rule_collection_group["<policy_key>.<group_key>"]' "<policyID>/ruleCollectionGroups/<name>"
tofu import 'azurerm_public_ip.pip["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/publicIPAddresses/<name>"
```
