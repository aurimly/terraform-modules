# equinix/fabric_service_token

Map-keyed module for Equinix Fabric service tokens. Each entry creates one
`equinix_fabric_service_token` — a VC or EPL token that invites remote
connections onto a port, virtual device, or network you own. Feed the `uuid`
output into `equinix/fabric_connection` as a side's `service_token.uuid`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `service_tokens` | `map(object)` | — | Map of service tokens keyed by an arbitrary unique identifier. |

### `service_tokens/<key>` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `type` | `string` | yes | `VC_TOKEN` or `EPL_TOKEN` (validated). |
| `name` | `string` | no | Token name. |
| `description` | `string` | no | Customer-provided description. |
| `expiration_date_time` | `string` | yes | RFC3339 timestamp (e.g. `2026-06-18T06:43:49.981Z`). Shape-validated at plan. |
| `notifications` | `list(object)` | yes | At least one notification entry. |
| `connection` | `object` | yes | What the token may be used to connect. |
| `project` | `object` | no | `{ project_id = optional(string) }` — Equinix IAM project. |

### `connection` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `type` | `string` | yes | `EVPL_VC`, `EVPLAN_VC`, `EPLAN_VC` or `IPWAN_VC` (validated). |
| `bandwidth_limit` | `number` | `null` | Mbps, 1–100000 (validated). |
| `supported_bandwidths` | `list(number)` | `null` | Bandwidth options offered to the remote side. |
| `allow_custom_bandwidth` | `bool` | `null` | Allow bandwidths outside `supported_bandwidths`. |
| `allow_remote_connection` | `bool` | `null` | Allow connections from remote accounts. |
| `a_side` | `object` | no | Issuing side access point selectors. |
| `z_side` | `object` | no | Issuing side access point selectors. |

Exactly one of `a_side` or `z_side` must be set — this module's check,
mirroring the API's issuer-side semantics (every provider example sets one).

### `a_side` / `z_side` object

Single attribute:

| Attribute | Type | Required | Description |
|---|---|---|---|
| `access_point_selectors` | `list(object)` | yes | Where the token admits connections. |

### `access_point_selectors` entries

| Attribute | Type | Required | Description |
|---|---|---|---|
| `type` | `string` | yes | `COLO`, `VD` or `NETWORK` (validated). |
| `port` | `object` | with `COLO` | `{ uuid = string, type = optional(string) }`. |
| `virtual_device` | `object` | with `VD` | `{ uuid = string, type = optional(string) }`. |
| `network` | `object` | with `NETWORK` | `{ uuid = string }`. |
| `interface` | `object` | no | `{ type = string }` — only with a `VD` selector. |
| `link_protocol` | `object` | no | Encapsulation: `type` (`UNTAGGED`, `DOT1Q`, `QINQ`, `EVPN_VXLAN`), `vlan_tag` (required with `DOT1Q`), `vlan_s_tag`/`vlan_c_tag` (required with `QINQ`). |

## Outputs

| Name | Description |
|---|---|
| `service_tokens` | Map of key → `{ uuid, state, issuer_side, type, expiration_date_time, href }`. `uuid` is the import ID and the value to wire into `fabric_connection` (`service_token.uuid`). |

## Provider

This module only declares `required_providers` (`equinix/equinix`, floor
`>= 5.0.0`), never a `provider {}` block. Configure the provider (auth token
or `client_id`/`client_secret`) at the consumer's Terragrunt unit and pin the
exact version at the root.

## Safe destroy

Service tokens are credentials. Deleting one invalidates the token remotely;
any consumer-side connection created with its uuid loses the ability to
accept new remote connections. Renaming a map key destroys and recreates the
token — treat keys as stable identifiers.

A token whose `expiration_date_time` passes goes `EXPIRED` remotely even with
no Terraform change. Renew by updating the input — the update applies in
place and keeps the uuid.

## Example

```hcl
service_tokens = {
  "z-colo-token" = {
    type                 = "VC_TOKEN"
    name                 = "example-z-colo"
    expiration_date_time = "2027-06-18T06:43:49.981Z"
    notifications = [
      {
        type   = "ALL"
        emails = ["ops@example.com"]
      },
    ]
    connection = {
      type                   = "EVPLAN_VC"
      supported_bandwidths   = [50, 100, 200]
      allow_remote_connection = true
      z_side = {
        access_point_selectors = [
          {
            type = "COLO"
            port = {
              uuid = "12345678-1234-1234-1234-123456789012"
            }
            link_protocol = {
              type     = "DOT1Q"
              vlan_tag = 1234
            }
          },
        ]
      }
    }
  },
  "a-vd-token" = {
    type                 = "VC_TOKEN"
    expiration_date_time = "2027-06-18T06:43:49.981Z"
    notifications = [
      {
        type   = "ALL"
        emails = ["ops@example.com"]
      },
    ]
    connection = {
      type = "EPLAN_VC"
      a_side = {
        access_point_selectors = [
          {
            type = "VD"
            virtual_device = {
              uuid = "87654321-4321-4321-4321-210987654321"
            }
          },
        ]
      }
    }
  },
}
```

To let a connection in another unit accept this token:

```hcl
dependency "service_token" {
  config_path = "../service-token"
}

# In the fabric_connection unit inputs:
#
#   z_side = {
#     access_point = {
#       type = "COLO"
#       port = { uuid = "..." }
#     }
#     service_token = {
#       uuid = dependency.service_token.outputs.service_tokens["z-colo-token"].uuid
#       type = "VC_TOKEN"
#     }
#   }
```

## Import

- `equinix_fabric_service_token` ← `<uuid>`

## Related modules

- `equinix/fabric_connection` — connections that consume the token via
  `service_token.uuid`.
- `equinix/fabric_cloud_router` — virtual devices that can act as the issuing
  `VD` selector side.
