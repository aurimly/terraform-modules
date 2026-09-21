# stackit/affinity_group

Map-keyed module for STACKIT affinity groups (placement policies) —
referenced by servers via stackit/server's `affinity_group` input.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `affinity_groups` | `map(object)` | — | Map of affinity groups keyed by an arbitrary unique ID. |

### `affinity_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID (validated). Changing it replaces the group. |
| `name` | `string` | — | Affinity group name (1–63 characters, IaaS name rule, validated). Changing it replaces the group. |
| `policy` | `string` | — | Placement policy: `hard-affinity` (schedule on the same node), `hard-anti-affinity` (schedule on different nodes), `soft-affinity` or `soft-anti-affinity` (same, best effort). Changing it replaces the group. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the group. |

## Outputs

`affinity_groups` — map of affinity group key => object:

| Attribute | Description |
|---|---|
| `affinity_group_id` | Affinity group UUID. Feed it into a server entry of stackit/server's `affinity_group` input. |
| `members` | List of member server UUIDs. |
| `id` | `"{project_id},{region},{affinity_group_id}"` — the import ID. |

## Example

```hcl
module "affinity_group" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/affinity_group?ref=v2.8.0"

  affinity_groups = {
    "app" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "app-anti-affinity"
      policy     = "soft-anti-affinity"
      region     = "eu01"
    }
  }
}
```

Join servers by referencing the group's ID from a server entry of
`modules/stackit/server`:

```hcl
servers = {
  "app-1" = {
    project_id     = "12345678-1234-1234-1234-123456789012"
    name           = "app-server-1"
    machine_type   = "s3.2xlarge.8"
    region         = "eu01"
    image_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    affinity_group = module.affinity_group.affinity_groups["app"].affinity_group_id
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **All attributes are create-only**: changing `name`, `policy`,
  `project_id` or `region` replaces the group. Membership is not managed
  by this module — servers join by setting their `affinity_group` input
  to the group's UUID. If the API rejects deleting a group that still
  has members, detach the servers first by clearing their
  `affinity_group` input and applying.
- **Hard policies are capacity-bound**: `hard-affinity` places every
  member on one compute node — scheduling fails once that node's
  capacity is exhausted; `hard-anti-affinity` requires a distinct node
  per member, so group size is limited by available nodes. The soft
  variants schedule best-effort instead.
- Renaming a map key destroys and recreates the group — the recreated
  group starts with no members; servers rejoin on their next apply.
- Plan-time validations mirror the provider's and API's rules
  (UUID for `project_id`, IaaS name rule) as forward-checking, plus a
  policy enum check the provider itself only enforces against the API.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_affinity_group` ← `{project_id},{region},{affinity_group_id}`
