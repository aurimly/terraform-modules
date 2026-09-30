# azure/dns-zone

Map-keyed module for Azure DNS zones: public and private zones in one input,
with optional SOA tuning and private-zone virtual network links. Each entry
creates one zone in the named resource group — pair with the `azure/dns-records`
module for the record sets.

Zone names must be unique **within their resource group** — the same zone name
in a different resource group is a different zone, and the module accepts both.

## Destroy semantics (read before using)

- Removing a zone key deletes the zone along with **every record set in it**
  (Azure deletes the full zone; there is no record migration on zone removal).
  Domains relying on the zone stop resolving.
- Flipping `private` on an existing key moves the entry between the two zone
  resources: the public/private zone is destroyed (with all records) and a new
  zone created. Split such renames across two keys instead.
- Removing a `virtual_network_links` entry only detaches that VNet; the zone
  remains intact.
- Changing `soa_record` on a **private** zone forces zone replacement per the
  provider — treat private-zone SOA values as immutable; on public zones SOA
  changes update in place.
- `tofu destroy` on a private zone with links destroys the zone and links
  together (links drop automatically with the zone).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | — | Map of DNS zones keyed by an arbitrary unique ID. |

Plan-time validation: `name` is a valid DNS zone shape (lowercase labels, alphabetic
TLD) lowered already, `name`/`resource_group_name` non-empty, the `name`+`resource_group_name`
pair is unique across entries case-insensitively, map keys (zone and link levels)
contain no `.`, `virtual_network_links` appear only on private zones, each link
takes a non-empty name plus a full ARM virtual network ID, `soa_record` timings are
non-negative and `soa_record.email` is non-empty, and tags respect the 50-entry /
512-char key / 256-char value limits.

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Zone name, e.g. `example.com` or `privatelink.postgres.database.azure.com`. Unique per resource group (validated among module entries). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the zone lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `private` | `bool` | `false` | Private DNS zone (`privateDnsZones`) instead of public (`dnsZones`). Private zones need at least one `virtual_network_links` entry to be resolvable from a VNet. Flipping it destroys and recreates the zone — see Destroy semantics. |
| `soa_record` | `object` | `null` | Optional single SOA block, one per zone (provider shape). `null` keeps the Azure-assigned SOA (already present on every zone). Only `email` is written when values are left out — see the object table. `null` ↔ set toggles are a full SOA replacement. |
| `virtual_network_links` | `map(object)` | `{}` | VNet links for private zones only (validated): one auto-registration/resolution link per VNet. The tag map is per-link. |
| `tags` | `map(string)` | `{}` | Tags on the zone. The tag set is authoritative — see Notes. |

### `soa_record` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `email` | `string` | — | Zone operator mailbox in hostmaster form, e.g. `hostmaster.example.com` (the leftmost label is the `@`). Required when the block is present. |
| `expire_time` | `number` | `null` | Seconds a resolver may use the zone above its refresh. Azure default 2419200 (28 days). Leave out to keep the default. |
| `minimum_ttl` | `number` | `null` | Negative-cache TTL: public zone default 300, private default 10. Leave out to keep the zone-kind default. |
| `refresh_time` | `number` | `null` | Secondary refresh interval, Azure default 3600. |
| `retry_time` | `number` | `null` | Secondary retry interval, Azure default 300. |
| `ttl` | `number` | `null` | TTL of the SOA record itself, Azure default 3600. |

### `virtual_network_links` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Resource name of the link (used in its ARM ID). |
| `virtual_network_id` | `string` | — | Full ARM VNet resource ID to link (typically `dependency.vnet.outputs.virtual_network_ids["platform"]`). |
| `registration_enabled` | `bool` | `false` | Auto-register VNet VM records into the zone. `true` also writes A records owned by the linked compute — beware of tag-outsized churn. |
| `tags` | `map(string)` | `{}` | Tags on the link. |

## Outputs

| Name | Description |
|---|---|
| `zone_ids` | Map of zone key => full ARM zone resource ID (both kinds). Private-zone `record_set` wiring takes this as `private_dns_zone_id`. |
| `zone_names` | Map of zone key => zone name (what public `azure/dns-records` entries take as `zone_name`). |
| `zone_name_servers` | Map of zone key => list of assigned name servers for **public** zones only — the registrar NS delegation target. Private zones have none; keys are absent from the map. |
| `virtual_network_link_ids` | Map of `<zone_key>.<link_key>` => full ARM link resource ID. |

## Example

```hcl
zones = {
  "public" = {
    name                = "example.com"
    resource_group_name = "rg-dns-prod"
    soa_record = {
      email       = "hostmaster.example.com"
      minimum_ttl = 60
    }
    tags = {
      env = "prod"
    }
  }
  "private-endpoints" = {
    name                = "privatelink.postgres.database.azure.com"
    resource_group_name = "rg-dns-prod"
    private             = true
    virtual_network_links = {
      "hub" = {
        name                 = "link-hub-vnet"
        virtual_network_id   = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-hub"
        registration_enabled = false
      }
      "spoke" = {
        name               = "link-spoke-vnet"
        virtual_network_id = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
      }
    }
  }
}
```

## Notes

- Pair with `azure/dns-records` — feed `zone_names` for public record sets
  (`zone_name` + same `resource_group_name`) and `zone_ids` for private record
  sets (`private_dns_zone_id`).
- **Private-zone SOA is immutable** in practice: a `soa_record` change on a
  private zone forces zone replacement (provider-documented), with all records
  and links re-created with it. Do not tune SOA on live private zones casually.
- A zone always has an Azure-managed apex SOA and NS: `soa_record` here only
  tunes the existing SOA, and apex NS record sets are system-managed — the
  record module cannot create them. A zone without any `soa_record` block
  stays on defaults.
- `privatelink.*` names are just names: private DNS zones for private
  endpoints follow the prefix pattern, but the module handles any domain.
  wiring into Azure Private Link zones (service-created zone groups) is out
  of scope — consumers or the Private Link integration own those.
- No domain registration exists for Azure DNS: creating the zone only makes
  it resolvable through Azure; its registrar (custom DNS vendors or another
  provider) still points at the registrar first.
- Zone names are case-insensitive: Azure lowercases them, and the module
  expects lowercase input.
- Tags are authoritative for the zone's tag set: the provider PUTs the full
  configured map, so portal/CLI tags are removed on the next apply with tag
  changes.
- The caller needs `Microsoft.Network/dnsZones/write` (public) or
  `Microsoft.Network/privateDnsZones/*` (private) on the resource group, and
  at least `Microsoft.Network/virtualNetworks/join/action` (or Private DNS
  Zone Contributor plus Network Contributor on the VNets) for links.
- Not exposed, deliberately (pass-through candidates for a later minor
  release): `soa_record.serial_number` and `soa_record.tags` (public zone)
  and `resolution_policy` on virtual network links (`Default` /
  `NxDomainRedirect`).

## Import

```
tofu import 'azurerm_dns_zone.zone["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/dnsZones/<name>"
tofu import 'azurerm_private_dns_zone.zone["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<name>"
tofu import 'azurerm_private_dns_zone_virtual_network_link.link["<zone_key>.<link_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<zone>/virtualNetworkLinks/<link>"
```
