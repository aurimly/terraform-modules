# stackit/network

Map-keyed module for STACKIT networks with IPv4/IPv6 prefixes, gateways,
nameservers, and DHCP.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `networks` | `map(object)` | — | Map of networks keyed by an arbitrary unique ID. |

### `networks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Network name; validated against the STACKIT GenericName rule (1–63 characters, starts/ends with a letter or digit; spaces, `/`, `.`, `_`, `-` allowed in between). |
| `project_id` | `string` | — | STACKIT project UUID the network is created in. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the network. |
| `routed` | `bool` | API default applies | Routed networks are accessible from other networks. Immutable: changing it replaces the network. Routed networks take their prefix from the network area. |
| `dhcp` | `bool` | provider default (`true`) | Whether the network has DHCP enabled. In-place update. |
| `labels` | `map(string)` | `{}` | Labels attached to the network. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. |
| `ipv4_prefix` | `string` | `null` | IPv4 prefix as a CIDR (e.g. `10.1.0.0/24`). Mutually exclusive with `ipv4_prefix_length`. Changing it replaces the network. |
| `ipv4_prefix_length` | `number` | `null` | IPv4 prefix length (8–29) taken from the network area's prefix pool. Mutually exclusive with `ipv4_prefix` and with `ipv4_gateway`. Changing it replaces the network. |
| `ipv4_gateway` | `string` | `null` | IPv4 gateway address. Defaults to the first IP of the prefix. Mutually exclusive with `no_ipv4_gateway` and with `ipv4_prefix_length`. |
| `no_ipv4_gateway` | `bool` | `null` | Set `true` to create the network without an IPv4 gateway. Mutually exclusive with `ipv4_gateway`. |
| `ipv4_nameservers` | `list(string)` | `null` | IPv4 nameservers, at most 3. See the tri-state behavior in the notes. |
| `ipv6_*` | — | — | `ipv6_prefix`, `ipv6_prefix_length` (56–128), `ipv6_gateway`, `no_ipv6_gateway`, `ipv6_nameservers` mirror their IPv4 counterparts, with one difference: changing `ipv6_prefix_length` is an in-place update (the IPv4 sibling replaces the network). |

## Outputs

`networks` — map of network key => object:

| Attribute | Description |
|---|---|
| `network_id` | Network UUID. |
| `ipv4_prefixes` | Resolved IPv4 prefixes of the network. |
| `ipv6_prefixes` | Resolved IPv6 prefixes of the network. |
| `public_ip` | The network's public IP, if any. |
| `id` | `"{project_id},{region},{network_id}"` — the import ID. |

## Example

```hcl
networks = {
  "app" = {
    project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name       = "app-network"
    region     = "eu01"
    routed     = true
  }
  "db" = {
    project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name              = "db-network"
    region            = "eu01"
    ipv4_prefix       = "10.1.0.0/24"
    ipv4_nameservers  = ["1.2.3.4", "5.6.7.8"]
    labels = {
      "env" = "prod"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not network names.
- Nameservers are tri-state: unset (`null`) → the network area's default
  nameservers are applied on create and left unchanged on update; `[]` →
  no nameservers at all; an explicit list → exactly those entries
  (validated: at most 3, valid addresses per family).
- Gateway behavior: unset `ipv4_gateway` defaults to the first IP of the
  prefix; `no_ipv4_gateway = true` creates the network without one. The
  same "configured" trigger applies to explicit `no_ipv4_gateway = false`
  and `ipv4_nameservers = []` as to any other IPv4 attribute — such
  entries still require `ipv4_prefix` or `ipv4_prefix_length`.
- The prefix/prefix_length/gateway/no_gateway combinations follow the
  provider's conflict rules, plus the API's prefix-length bounds
  (IPv4 8–29, IPv6 56–128) which the provider does not check itself.
- Replacements: `routed`, `region`, `ipv4_prefix`, `ipv4_prefix_length`,
  `ipv6_prefix` replace the network when changed. `dhcp`, `name`,
  `labels`, `ipv6_prefix_length`, nameservers and gateways are in-place
  updates.
- Names are not unique per project upstream, so duplicate names across
  entries are allowed; no uniqueness check is enforced.
- Network areas are covered by `modules/stackit/network_area`; area
  region/route resources and the VPC-rework attributes (`vpc_id`,
  `ipv4_vpc_network_range_id`, `ipv6_vpc_network_range_id`,
  `routing_table_id`, provider >= 0.110.0) are intentionally out of
  scope — candidates for separate future modules.
- A network still in use cannot be deleted upstream; detach dependent
  resources before destroying an entry.
- Plan-time validations mirror the provider conflict rules and the IaaS
  API spec; CIDR/IP checks use Terraform's IP functions so they match
  the provider's parser exactly.
- The provider floor `>= 0.114.0` is aligned across all stackit modules to
  the latest provider release the modules are tested against; the network
  `dhcp` attribute was introduced in 0.81.0 and the `region` attribute
  exists since 0.57.0, so no behavior in this module requires anything
  newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_network` ← `{project_id},{region},{network_id}`

After import there may be a conflict to resolve manually — the attributes
`ipv4_prefix`, `ipv4_prefix_length` and `ipv4_gateway` cannot be
configured together in the post-import plan; keep exactly one identifying
form.
