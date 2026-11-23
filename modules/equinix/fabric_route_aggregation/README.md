# equinix/fabric_route_aggregation

Map-keyed module for Equinix Fabric route aggregations with their rules and
connection attachments. Each `route_aggregations` entry creates one
`equinix_fabric_route_aggregation`; `rules` and `connection_attachments`
reference aggregations by key and create
`equinix_fabric_route_aggregation_rule` /
`equinix_fabric_connection_route_aggregation` resources against them.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `route_aggregations` | `map(object)` | — | Route aggregations keyed by an arbitrary unique identifier. |
| `rules` | `map(object)` | — | Aggregation rules keyed by an arbitrary unique identifier. |
| `connection_attachments` | `map(object)` | — | Connection attachments keyed by an arbitrary unique identifier. |

### `route_aggregations/<key>` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | yes | Aggregation name. |
| `type` | `string` | yes | `BGP_IPv4_PREFIX_AGGREGATION` or `BGP_IPv6_PREFIX_AGGREGATION` (validated). |
| `description` | `string` | no | Customer-provided description. Create-only in practice (see update behavior). |
| `project` | `object` | yes | `{ project_id = string }` — Equinix IAM project id (validated non-empty). |

### `rules/<key>` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `aggregation_key` | `string` | yes | Key into `route_aggregations` (validated to exist). |
| `name` | `string` | yes | Rule name. Unique per aggregation (validated). Create-only in practice. |
| `prefix` | `string` | yes | CIDR, e.g. `192.168.0.0/24` (shape-validated; family-vs-type enforced by the API at apply). |
| `description` | `string` | no | Create-only in practice. |

### `connection_attachments/<key>` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `aggregation_key` | `string` | yes | Key into `route_aggregations` (validated to exist). |
| `connection_id` | `string` | yes | Fabric connection uuid (typically a `fabric_connection` output). One attachment per connection per aggregation (validated). |

## Outputs

| Name | Description |
|---|---|
| `route_aggregations` | Map of key → `{ uuid, state, rules_count, connections_count, href }`. `uuid` is the import ID. |
| `rules` | Map of key → `{ uuid, state, type, prefix, href }`, keyed by the same keys as `var.rules`. |
| `connection_attachments` | Map of key → `{ uuid, attachment_status, type }`. |

## Provider

This module only declares `required_providers` (`equinix/equinix`, floor
`>= 5.0.0`), never a `provider {}` block. Configure the provider (auth token
or `client_id`/`client_secret`) at the consumer's Terragrunt unit and pin the
exact version at the root.

## Update behavior

Verified against the provider source (equinix v5.4.0):

- **Aggregations update only `name` in place.** `type` and `description` are
  create-only in practice: changing them triggers an upstream Update that
  patches nothing, and the state re-parse reverts the value — a permanent
  plan diff. To change either, recreate the aggregation under a new map key.
- **Rules update only `prefix` in place.** `name` and `description` are
  create-only — recreate the rule under a new key to change them.
- **Moving a rule to another aggregation is safe.** The module keys rule
  resources by `aggregation_key:rule_key`, so a parent change is an honest
  destroy + create. Without this, the upstream resource would silently patch
  the prefix on the old aggregation and the rule would never move.

## Safe destroy

The API rejects deleting an aggregation that still has rules or attachments.
Terraform's reverse dependency order handles entries removed in the same
apply; when decommissioning gradually, remove the `rules` /
`connection_attachments` entries first and apply, then remove the
aggregation. Renaming any map key destroys and recreates the corresponding
resource — treat keys as stable identifiers.

## Import

- `equinix_fabric_route_aggregation` ← `<uuid>`
- **Rules and connection attachments cannot be imported.** The provider
  reads these resources with the parent aggregation id taken from state and
  ships no import override, so importing them cannot succeed. Brownfield
  rules must be re-created under this module (or managed out-of-band with
  acknowledged drift).

## Example

```hcl
route_aggregations = {
  "onprem-v4" = {
    name = "example-ra-v4"
    type = "BGP_IPv4_PREFIX_AGGREGATION"
    project = {
      project_id = "123456789012345"
    }
  },
}

rules = {
  "branch-a" = {
    aggregation_key = "onprem-v4"
    name            = "example-branch-a"
    prefix          = "192.168.0.0/24"
  },
  "branch-b" = {
    aggregation_key = "onprem-v4"
    name            = "example-branch-b"
    prefix          = "192.168.1.0/24"
  },
}

connection_attachments = {
  "fcr-attach" = {
    aggregation_key = "onprem-v4"
    connection_id   = "87654321-4321-4321-4321-210987654321"
  },
}
```

Wire `connection_id` from a `fabric_connection` unit:

```hcl
dependency "connection" {
  config_path = "../connection"
}

locals {
  connection_id = dependency.connection.outputs.connections["example-fcr-sp"].uuid
}
```

## Related modules

- `equinix/fabric_cloud_router` — route aggregations pair with FCR
  deployments for on-prem prefix aggregation.
- `equinix/fabric_connection` — the connections attached via
  `connection_attachments`.
- `equinix/fabric_routing_protocol` — the BGP sessions announcing the
  aggregated prefixes.
