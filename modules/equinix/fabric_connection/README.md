# equinix/fabric_connection

Map-keyed module for Equinix Fabric connections. Each entry creates one
`equinix_fabric_connection` between any two of: Fabric port, cloud router
(FCR), virtual device (Network Edge), service token, Equinix network, or a
service provider (AWS Direct Connect, Azure ExpressRoute, etc.).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `connections` | `map(object)` | — | Map of connections keyed by an arbitrary unique identifier. |

### `connections/<key>` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | yes | Up to 24 chars (letters, digits, `-`, `_`). Validated at plan. |
| `type` | `string` | yes | e.g. `EVPL_VC`, `EPL_VC`, `IP_VC`, `IPWAN_VC`, `EVPLAN_VC`, `EPLAN_VC`, `ACCESS_EPL_VC`, `EIA_VC`, `IA_VC`, `EC_VC`. Docs list these as examples ("like"), not a closed enum; unknown values are rejected upstream at apply. |
| `bandwidth` | `number` | yes | Mbps. Must be > 0 (validated). |
| `notifications` | `list(object)` | yes | At least one entry. Same shape as in the FCR module. |
| `description` | `string` | no | |
| `geo_scope` | `string` | no | Geographic boundary type. |
| `additional_info` | `list(object)` | no | `{ key, value }` entries (e.g. AWS `accessKey`/`secretKey`, IBM `ASN`). |
| `order` | `object` | no | Purchase/order details; `term_length` ∈ 1/12/24/36 (validated). |
| `project` | `object` | no | `{ project_id }` for IAM-onboarded accounts. |
| `redundancy` | `object` | no | `{ priority, group }` — Azure redundant connections (PRIMARY/SECONDARY, validated). |
| `a_side` | `object` | yes | The side object below. |
| `z_side` | `object` | yes | Identical shape. |

### The side object (`a_side` / `z_side`)

Exactly one of `access_point` or `service_token` per side (this is
API-enforced at apply, not plan-validated):

| Attribute | Type | Default | Description |
|---|---|---|---|
| `access_point` | `object` | `null` | Access point. |
| `service_token` | `object` | `null` | `{ uuid, type }` — token-based connections; `type` optional (`VC_TOKEN`), validated. |
| `additional_info` | `list(object)` | `[]` | Side-scoped `{ key, value }` entries. |

### `access_point` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | `null` | `COLO` (port), `VD`, `VG`, `SP`, `IGW`, `SUBNET`, `CLOUD_ROUTER`, `NETWORK`, `METAL_NETWORK` (validated). |
| `port` | `object` | `null` | `{ uuid }` — for `COLO`. |
| `router` | `object` | `null` | `{ uuid }` — for `CLOUD_ROUTER`; get it from the FCR module's `cloud_routers` output. |
| `network` | `object` | `null` | `{ uuid }` — for `NETWORK`. |
| `virtual_device` | `object` | `null` | `{ uuid, type, name }` — for `VD`; needs `interface`. |
| `interface` | `object` | `null` | `{ type = "NETWORK"\|"CLOUD", id }` (or `uuid`). |
| `profile` | `object` | `null` | `{ uuid, type }` — `SP` needs it; `type` required within the object (validated: `L2_PROFILE`, `L3_PROFILE`, `ECIA_PROFILE`, `ECMC_PROFILE`, `IA_PROFILE`). |
| `authentication_key` | `string` | `null` | Provider auth (AWS account ID, Azure auth key...). `SP` needs it. |
| `seller_region` | `string` | `null` | e.g. `us-west-1`. |
| `peering_type` | `string` | `null` | `PRIVATE`, `MICROSOFT`, `PUBLIC`, `MANUAL` (validated). |
| `role` | `string` | `null` | Network role (`NETWORK` access points). |
| `link_protocol` | `object` | `null` | `{ type, vlan_tag, vlan_s_tag, vlan_c_tag }` — see below. |
| `location` | `object` | `null` | `{ metro_code, ibx, metro_name, region }`. |

### `link_protocol` fields

| Attribute | Type | Description |
|---|---|---|
| `type` | `string` | `UNTAGGED`, `DOT1Q`, `QINQ`, `EVPN_VXLAN` (validated). |
| `vlan_tag` | `number` | `DOT1Q` only. |
| `vlan_s_tag` | `number` | `QINQ` only. |
| `vlan_c_tag` | `number` | `QINQ` only. |

VLAN tags: the provider schema does not constrain tag values; the pairing of
`type` with the right tag fields per access point type and reserved tags are
checked by the API at apply time, not validated here.

## Secrets in state

`additional_info` passes anything to the provider API as-is: the upstream
examples use it for provider-side rules (AWS `accessKey`/`secretKey`, IBM
`ASN`/`BGP_IBM_CIDR`). Anything set here — including secret keys — is
persisted in plain text in Terraform state. If a flow requires secrets in
`additional_info`, plan for state security (encrypted backend, minimal
access) or prefer provider-portal acceptance flows that don't need secrets
in state at all.

## Outputs

| Name | Description |
|---|---|
| `connections` | Map of key → `{ uuid, id, state, href, direction, is_remote, redundancy_group }`. `uuid` is the import ID. `redundancy_group` is `null` for non-redundant connections; create the primary first, then set `redundancy.group` on the secondary from its output. |

## Provider

This module only declares `required_providers` (`equinix/equinix`, floor
`>= 5.0.0`), never a `provider {}` block. Configure the provider (auth token
or `client_id`/`client_secret`) at the consumer's Terragrunt unit and pin the
exact version at the root.

## Safe destroy

Renaming a map key, changing `name`, `type`, or either side's access point
typically destroys and recreates the connection with service-affecting
downtime on the attached providers. Some providers additionally require the
deletion to be initiated from their portal (e.g. Alibaba's fabric
connections must be terminated portal-side; IBM connections may need
`ibm_dl_gateway_action` approve resources). Treat keys and endpoints as
stable.

## Example (Cloud Router to service provider)

```hcl
connections = {
  "example-fcr-to-sp" = {
    name      = "example-fcr-sp"
    type      = "IP_VC"
    bandwidth = 50
    notifications = [
      {
        type   = "ALL"
        emails = ["ops@example.com"]
      },
    ]
    a_side = {
      access_point = {
        type   = "CLOUD_ROUTER"
        router = {
          # from equinix/fabric_cloud_router: dependency.fcr.outputs.cloud_routers["example-fcr"].uuid
          uuid = "12345678-1234-1234-1234-123456789012"
        }
      }
    }
    z_side = {
      access_point = {
        type               = "SP"
        authentication_key = "example-auth-key"
        profile = {
          type = "L2_PROFILE"
          uuid = "87654321-4321-4321-4321-210987654321"
        }
        location = {
          metro_code = "SV"
        }
      }
    }
  },
}
```

### Port to port (`DOT1Q`)

Same shape with `type = "EVPL_VC"`, both sides `access_point.type = "COLO"`
with `port.uuid` set and a `link_protocol` (`type = "DOT1Q"`,
`vlan_tag = 300`) per side.

### Redundant (Azure)

Provision the primary with `redundancy = { priority = "PRIMARY" }`, then
declare the second entry with `redundancy = { priority = "SECONDARY", group
= <primary's connections output redundancy_group> }`.

## Import

- `equinix_fabric_connection` ← `<uuid>`

## Related modules

- `equinix/fabric_cloud_router` — FCR whose `uuid` feeds a `CLOUD_ROUTER`
  access point.
