# stackit/network_area_route

Map-keyed module for static routes inside STACKIT network areas
(SNA). Each entry creates one route: a destination CIDR and a next
hop (IPv4 address, or the pseudo next hops `blackhole`/`internet`).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `routes` | `map(object)` | — | Map of routes keyed by an arbitrary unique ID. |

### `routes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `organization_id` | `string` | — | STACKIT organization UUID owning the area. Changing it replaces the route. |
| `network_area_id` | `string` | — | Network area UUID (see `stackit/network_area` outputs). Changing it replaces the route. |
| `region` | `string` | `null` | Region the route applies to. If unset, the provider's configured region is used and written into state. Changing it replaces the route. |
| `destination` | `object` | — | Route destination, see below. Changing it updates the route in place. |
| `next_hop` | `object` | — | Next hop, see below. Changing it updates the route in place. |
| `labels` | `map(string)` | `{}` | IaaS labels. In-place update. |

### `destination` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `"cidrv4"`. The STACKIT API supports IPv4 destinations only currently. |
| `value` | `string` | — | Destination as an IPv4 CIDR (e.g. `10.0.0.0/8`). |

### `next_hop` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | One of `blackhole`, `internet`, `ipv4`. The STACKIT API supports only these types currently. |
| `value` | `string` | `null` | IPv4 address of the next hop. Required for `ipv4`, unset for `blackhole` and `internet`. |

## Outputs

`routes` — map of route key => object:

| Attribute | Description |
|---|---|
| `network_area_route_id` | Route UUID. |
| `region` | The resolved effective region (provider default filled in upstream). |
| `id` | `"{organization_id},{network_area_id},{region},{network_area_route_id}"` — the import ID. |

## Example

```hcl
routes = {
  "default-out" = {
    organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    network_area_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    region          = "eu01"
    destination = {
      type  = "cidrv4"
      value = "0.0.0.0/0"
    }
    next_hop = {
      type  = "internet"
    }
  }
  "hub-branch" = {
    organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    network_area_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    region          = "eu01"
    destination = {
      type  = "cidrv4"
      value = "172.16.0.0/12"
    }
    next_hop = {
      type  = "ipv4"
      value = "192.0.2.1"
    }
  }
}
```

## Relationship chain

Routes live inside a network area (see `stackit/network_area`) and are
regional, like the area's IPv4 configuration (see
`stackit/network_area_region`). The area's regional configuration must
exist in the route's region before routes can be created.

## Notes

- The resource is SNA-only and applies to classic (SNA) networks, not
  VPC networks.
- Provider notes say only `cidrv4` destinations and `ipv4`/`blackhole`/
  `internet` next hops are supported currently — the module enforces
  both at plan time.
- The import ID includes the effective region as its third part. When
  the route relies on the provider's default region, use the resolved
  value from the `region` output.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_network_area_route` ← `{organization_id},{network_area_id},{region},{network_area_route_id}`
