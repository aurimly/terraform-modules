# azure/public-ip

Map-keyed module for Azure public IP addresses. Each entry creates one
`azurerm_public_ip` in the named resource group, in the subscription
configured on the provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `public_ips` | `map(object)` | — | Map of public IPs keyed by an arbitrary unique ID. |

Plan-time validation: `name`, `resource_group_name` and `location` are
non-empty, (name, resource group) pairs are unique across entries
case-insensitively, `allocation_method` is `Static`/`Dynamic`,
`sku` is `Basic`/`Standard`/`StandardV2`, `sku_tier` is `Regional`/`Global`,
Global tier requires the Standard SKU, Standard/StandardV2 require the Static
allocation method, `ip_version` is `IPv4`/`IPv6`, `idle_timeout_in_minutes`
is 4–30, `availability_zone` is `1`/`2`/`3`, `ddos_protection_mode` is one of
the three allowed values, the DDoS plan ID is a full ARM resource ID settable
only in `Enabled` mode, and tags respect the 50-entry / 512-char key /
256-char value limits.

### `public_ips` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Public IP name. Validated loosely (non-empty) on purpose: Azure enforces its own naming rules at apply. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the IP lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region for the IP. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `allocation_method` | `string` | — | `Static` or `Dynamic` (case-sensitive). Standard and StandardV2 SKUs accept only `Static` (validated); `Dynamic` is a Basic-SKU setting and new Basic IPs are blocked by the provider — see Notes. Updated in place. |
| `sku` | `string` | `Standard` | `Basic`, `Standard` or `StandardV2` (case-sensitive). Standard is the default and the only workable SKU for new addresses — see Notes. Immutable — changing it forces replacement. |
| `sku_tier` | `string` | `Regional` | `Regional` or `Global` (case-sensitive). `Global` requires `sku = "Standard"` (validated) and is for cross-region load balancer frontends. Immutable — changing it forces replacement. |
| `ip_version` | `string` | `IPv4` | `IPv4` or `IPv6` (case-sensitive). Immutable — changing it forces replacement. |
| `idle_timeout_in_minutes` | `number` | `null` | TCP idle timeout for the IP, 4–30 minutes (validated; the provider bound-checks the same range and defaults to 4 when unset). Updated in place. |
| `domain_name_label` | `string` | `null` | Label for the DNS record Azure creates — the FQDN becomes `<label>.<region>.cloudapp.azure.com`. The provider validates the label charset at plan time. Updated in place. |
| `availability_zone` | `string` | `null` | Availability zone to pin the IP to: `1`, `2` or `3` (case-sensitive); unset means no zone pinning. Mapped to the provider's `zones` set. Immutable — changing it forces replacement. Must match the zone of the NIC or VM it attaches to (ARM validates at apply) — see Notes. |
| `ddos_protection_mode` | `string` | `VirtualNetworkInherited` | DDoS protection mode: `Disabled`, `Enabled` or `VirtualNetworkInherited` (case-sensitive). The default mirrors the provider so IPs in virtual networks carrying a DDoS plan inherit its protection — see Notes. Updated in place. |
| `ddos_protection_plan_id` | `string` | `null` | Full ARM resource ID of a `Microsoft.Network/ddosProtectionPlans` instance. Only settable when `ddos_protection_mode` is `Enabled` (validated, mirroring the provider). Updated in place. |
| `tags` | `map(string)` | `{}` | Tags on the public IP. The tag set is authoritative — see Notes. |

## Outputs

| Name | Description |
|---|---|
| `public_ip_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/publicIPAddresses/<name>`). |
| `public_ip_addresses` | Map of key => assigned IP address, `null` for addresses not yet associated — a Dynamic address only exists once the IP is attached. |
| `public_ip_fqdns` | Map of key => FQDN (`<label>.<region>.cloudapp.azure.com`), `null` without a `domain_name_label`. |

## Example

```hcl
public_ips = {
  "ingress" = {
    name                = "pip-ingress-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    allocation_method   = "Static"
    sku                 = "Standard"
    availability_zone   = "1"
    domain_name_label   = "ingress-example"
    tags = {
      env = "prod"
    }
  }
  "egress-ipv6" = {
    name                = "pip-egress-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    allocation_method   = "Static"
    ip_version          = "IPv6"
  }
}
```

## Notes

- `name`, `resource_group_name`, `location`, `sku`, `sku_tier`,
  `ip_version` and `availability_zone` force replacement if changed;
  `allocation_method`, `idle_timeout_in_minutes`, `domain_name_label`, the
  DDoS fields and tags update in place.
- Standard and StandardV2 SKUs accept only `allocation_method = "Static"`
  (validated); `Dynamic` is a Basic-SKU setting. Creation of new Basic SKU
  public IPs is blocked by the provider since March 31, 2025 (Basic retires
  September 30, 2025) — the provider fail-fasts a new Basic IP at plan time,
  so `Standard` (or `StandardV2`) + `Static` is the workable shape for new
  addresses. The `Basic` enum value is kept to mirror the provider and keep
  tag-update paths open for imported legacy IPs.
- `sku_tier = "Global"` requires `sku = "Standard"` specifically — a
  separate rule from the Static check, which also covers StandardV2. Global
  addresses front cross-region load balancers; almost everything else wants
  the Regional default.
- `ddos_protection_plan_id` can only be attached when
  `ddos_protection_mode = "Enabled"` — the provider enforces this at create
  and update and the module mirrors it at plan time. The default mode is
  `VirtualNetworkInherited` (the provider default), so IPs in virtual
  networks carrying a DDoS plan inherit its protection like
  provider-defaulted IPs; set `Disabled` explicitly to opt out. What azurerm
  4.0 removed was the 3.x `ddos_protection_plan { id, enable }` block and
  `enable_ddos_protection_plan` argument — the plan ID survives as this
  top-level attribute.
- Dynamic allocation assigns the address only once the IP is associated, so
  `public_ip_addresses` reads `null` until then. Associate by wiring
  `public_ip_ids` into `azure/network-interface`'s
  `ip_configurations.*.public_ip_address_id`, e.g.:

  ```hcl
  dependency "pip" {
    config_path = "../public-ip"
  }

  # inside the network-interface module's ip_configurations:
  public_ip_address_id = dependency.pip.outputs.public_ip_ids["ingress"]
  ```
- A public IP attaches to one resource at a time — one NIC IP configuration
  or one load balancer frontend. Because disassociation must happen before
  destruction, set lifecycle `create_before_destroy = true` on
  consumer-side replacement flows; otherwise destroying an associated IP can
  fail. This module sets no lifecycle blocks itself.
- `availability_zone` maps to the provider's `zones` set; leaving it unset
  means no zone pinning — note that Standard IPs without a zone are not
  zone-redundant by default. The zone must match the zone of the NIC or VM
  the IP attaches to (ARM validates at apply).
- `domain_name_label` forms `<label>.<region>.cloudapp.azure.com`; the
  provider validates the label charset at plan time. Without a label,
  `public_ip_fqdns` reads `null`.
- Tags are authoritative for the IP's tag set: the provider PUTs the full
  configured map, so tags added in the portal or CLI are removed on the next
  apply with tag changes.
- `name` is validated loosely on purpose: Azure enforces its naming rules at
  apply, and resource group names may contain characters a conservative
  regex would reject on the resource-group half of the ID.
- The caller needs `Microsoft.Network/publicIPAddresses/write` (and delete)
  on the resource group; the identity associating the IP (NIC, load
  balancer, ...) additionally needs
  `Microsoft.Network/publicIPAddresses/join/action` on the IP.
- Not exposed, deliberately: `ip_tags` (ARM-gated key set, effectively
  RoutingPreference only), `reverse_fqdn` (PTR niche),
  `public_ip_prefix_id` (prefix allocation niche),
  `domain_name_label_scope` (label reuse-scope control), `edge_zone`
  (extended zones) — pass-through candidates for a later minor release.

## Import

`tofu import 'azurerm_public_ip.public_ip["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/publicIPAddresses/<name>"`
