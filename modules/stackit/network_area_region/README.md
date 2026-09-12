# stackit/network_area_region

Map-keyed module for the regional configuration of STACKIT network areas
(SNA): transfer network, IPv4 ranges, prefix bounds, and default
nameservers per region.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `network_area_regions` | `map(object)` | — | Map of area regional configurations keyed by an arbitrary unique ID. |

### `network_area_regions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `organization_id` | `string` | — | STACKIT organization UUID owning the area. Changing it replaces the region config. |
| `network_area_id` | `string` | — | Network area UUID (see `stackit/network_area` outputs). Changing it replaces the region config. |
| `region` | `string` | `null` | Region the area's IPv4 config applies to. If unset, the provider's configured region is used and written into state. Changing it replaces the region config. |
| `ipv4` | `object` | — | Regional IPv4 configuration, see below. Required (there is no meaningful region config without it). |

### `ipv4` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `transfer_network` | `string` | — | Transfer network as an IPv4 CIDR (e.g. `10.1.2.0/24`). Changing it replaces the region config. |
| `network_ranges` | `map(string)` | — | IPv4 network ranges keyed by an arbitrary unique ID, value the CIDR prefix (e.g. `"prod" = "10.0.0.0/16"`). 1–64 entries, prefixes unique within an entry. Updated in place. |
| `default_nameservers` | `list(string)` | `null` | Default name servers for networks drawing from the area: up to 3 IPv4 addresses (per the STACKIT API docs). In-place update. |
| `default_prefix_length` | `number` | provider default (`25`) | Default prefix length networks draw from the ranges (24–29). In-place update. |
| `max_prefix_length` | `number` | provider default (`29`) | Largest prefix length networks may request (24–29). In-place update. |
| `min_prefix_length` | `number` | provider default (`24`) | Smallest prefix length networks may request (8–29). In-place update. |

## Outputs

`network_area_regions` — map of area region key => object:

| Attribute | Description |
|---|---|
| `region` | The resolved effective region (provider default filled in upstream). |
| `network_range_ids` | Map of the input range keys => network range UUIDs. |
| `default_prefix_length` | Resolved default prefix length (defaults filled in upstream). |
| `min_prefix_length` | Resolved minimum prefix length. |
| `max_prefix_length` | Resolved maximum prefix length. |
| `id` | `"{organization_id},{network_area_id},{region}"` — the import ID. |

## Example

```hcl
network_area_regions = {
  "eu01" = {
    organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    network_area_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    region          = "eu01"
    ipv4 = {
      transfer_network = "10.1.2.0/24"
      network_ranges = {
        "prod" = "10.0.0.0/16"
        "npd"  = "10.1.0.0/16"
      }
      default_nameservers   = ["192.0.2.1"]
      default_prefix_length = 25
      min_prefix_length     = 24
      max_prefix_length     = 29
    }
  }
}
```

## Relationship chain

An organization holds network areas (see `stackit/network_area`), each
area holds one regional IPv4 configuration per region (this module).
Networks created with `routed = true` or an `ipv4_prefix_length` (see
`stackit/network`) draw their prefixes from the area's ranges in their
region — so the region config must exist before those networks are
created. The area resource itself carries only name and labels; this
module carries everything regional.

## Notes

- The resource is SNA-only and applies to classic (SNA) networks, not
  VPC networks.
- Range map keys are arbitrary unique identifiers and are not stored
  upstream — the provider identifies ranges by their prefix. Duplicate
  prefixes across keys are rejected at plan time so the
  `network_range_ids` output mapping stays well-defined.
- Ranges update in place, reconciled by prefix: prefixes removed from
  the map are deleted, prefixes added are created — one API delete and
  create per changed prefix, no rollback of the whole region config.
- Name servers: up to 3 IPv4 addresses. Note that leaving
  `default_nameservers` unset sends an empty list on create and update
  (the attribute is Optional but not Computed upstream) — after an
  import, set it explicitly or the next apply clears the name servers.
- Replacements: `organization_id`, `network_area_id`, `region` and
  `ipv4.transfer_network` replace the region config when changed.
  Everything else updates in place.
- Prefix-length ordering (`min <= default <= max`) is checked at plan
  time, but only for values set explicitly: the module cannot see the
  provider-applied defaults. For example, `min_prefix_length = 28`
  alone still inverts at apply, because the upstream default
  `default_prefix_length` of 25 counts as unset input-side and passes
  the check. Set all three bounds explicitly to rely on the check.
- An area region still referenced by networks or projects cannot be
  deleted upstream; detach them before destroying an entry.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  attribute in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_network_area_region` ← `{organization_id},{network_area_id},{region}`

The ID always needs the explicit region as its third part, even when
the configuration relies on the provider's default region.
