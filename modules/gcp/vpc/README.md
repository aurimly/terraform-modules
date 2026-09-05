# gcp/vpc

Map-keyed module for Google Cloud VPC networks.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `networks` | `map(object)` | — | Map of VPC networks keyed by an arbitrary unique ID. |

### `networks` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Network name; 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the network lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. Immutable; changing forces replacement. |
| `auto_create_subnetworks` | `bool` | `false` | Auto mode when `true`, custom mode when `false`. Immutable; changing forces replacement. Default `false` (provider default is `true`); see Notes. |
| `routing_mode` | `string` | `REGIONAL` | One of `REGIONAL`, `GLOBAL` (case-sensitive). Matches the provider default. |
| `delete_default_routes_on_create` | `bool` | `false` | Deletes the default internet gateway routes at create time only; later changes are ignored. |
| `mtu` | `number` | — | Maximum transmission unit in bytes; integer 1300–8896, provider default 1460. Validated client-side. |

## Outputs

`network_names` — map of network key => VPC network name.
`network_self_links` — map of network key => VPC network self link.
`network_ids` — map of network key => network ID (`projects/{project}/global/networks/{name}`).

## Example

```hcl
networks = {
  "prod" = {
    name                    = "example-vpc"
    project_id              = "example-project-1234"
    description             = "Example VPC"
    auto_create_subnetworks = false
    routing_mode            = "REGIONAL"
    mtu                     = 1460
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not network names. The key
  disambiguates entries that might share a name.
- `auto_create_subnetworks = false` (the module default; the provider default
  is `true`) creates the network in custom mode: subnets are then managed with
  the `gcp/subnet` module. `true` puts the network in auto mode — one subnet
  per region carved from `10.128.0.0/9` — and the subnet module must not be
  paired with it. The field can only be set at create time; changing it forces
  replacement.
- `delete_default_routes_on_create` removes the `0.0.0.0/0` default routes at
  create time only; later configuration changes are ignored by the provider.
  Keeping a network internet-free long term is the job of org policy and
  static routes, not this flag.
- `name` and `description` changes force replacement; `routing_mode` and `mtu`
  update in place. An `mtu` above 1500 bytes risks TCP MSS clamping or ICMP
  fragmentation-needed behavior when traffic leaves the VPC or crosses into a
  mixed-MTU network (see the provider's own note).
- Pair with `gcp/subnet`: wire each subnet entry's `network` attribute to the
  network name or to the `network_self_links` output of this module.

## Import

`google_compute_network` ← `projects/{project}/global/networks/{name}` (also
`{project}/{name}`, and the bare `{name}` within the provider's default
project).
