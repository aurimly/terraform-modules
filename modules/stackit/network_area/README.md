# stackit/network_area

Map-keyed module for STACKIT network areas (SNA) at the organization
level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `network_areas` | `map(object)` | — | Map of network areas keyed by an arbitrary unique ID. |

### `network_areas` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `organization_id` | `string` | — | STACKIT organization UUID owning the area. Changing it replaces the area. |
| `name` | `string` | — | Area name (1–63 characters; the provider applies no charset restriction here). In-place update. |
| `labels` | `map(string)` | `{}` | Labels attached to the area. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. Validated here for consistency with the other IaaS modules, though the provider does not enforce it on this resource. |

## Outputs

`network_areas` — map of network area key => object:

| Attribute | Description |
|---|---|
| `network_area_id` | Network area UUID. |
| `project_count` | Number of projects referencing the area. |
| `id` | `"{organization_id},{network_area_id}"` — the import ID. |

## Example

```hcl
network_areas = {
  "prod" = {
    organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name            = "prod-network-area"
    labels = {
      "env" = "prod"
    }
  }
}
```

## Relationship to networks

A network area is the parent construct of classic (SNA) networks and
sits above projects. Networks created with `routed = true` or an
`ipv4_prefix_length` (see `stackit/network`) draw their prefixes from
the area's pool, and `project_count` counts the projects attached to
the area. The area resource itself carries only name and labels — it
does not create networks or prefixes.

The regional configuration — transfer network, IPv4 network ranges,
default/min/max prefix length, default nameservers — is covered by
`modules/stackit/network_area_region`. Area routes
(`stackit_network_area_route`) remain out of scope here and are a
candidate for a follow-up module.

## Notes

- Network areas apply to SNA networks only, not VPC networks.
- Keys are arbitrary unique identifiers, not area names.
- An area with attached projects (`project_count > 0`) cannot be
  deleted upstream; detach the projects first.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  attribute in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_network_area` ← `{organization_id},{network_area_id}`
