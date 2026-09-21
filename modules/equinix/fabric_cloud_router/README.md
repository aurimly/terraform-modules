# equinix/fabric_cloud_router

Map-keyed module for Equinix Fabric Cloud Routers (FCR). Each entry creates one
`equinix_fabric_cloud_router`. Feed the `uuid` output into
`equinix/fabric_connection` as a `CLOUD_ROUTER` access point.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cloud_routers` | `map(object)` | — | Map of FCRs keyed by an arbitrary unique identifier. |

### `cloud_routers/<key>` object

| Attribute | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | yes | FCR name, up to 24 chars (letters, digits, `-`, `_`). Validated at plan. |
| `type` | `string` | yes | FCR type, e.g. `XF_ROUTER`. Provider docs do not publish a closed enum; non-`XF_ROUTER` values are not validated here — reject happens upstream at apply. |
| `description` | `string` | no | Customer-provided description. |
| `location` | `object` | yes | Access point location. |
| `package` | `object` | yes | FCR package. |
| `project` | `object` | yes | Equinix IAM project. Passing `project_id` is required for IAM-onboarded accounts. |
| `notifications` | `list(object)` | yes | At least one notification entry. |
| `account` | `object` | no | `{ account_number = number }`. |
| `order` | `object` | no | Purchase/order details. |
| `marketplace_subscription` | `object` | no | `{ uuid = string, type = optional(string) }`. |

### `location` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `metro_code` | `string` | required | Access point metro code (e.g. `SV`). |
| `ibx` | `string` | `null` | IBX code. |
| `metro_name` | `string` | `null` | Metro display name. |
| `region` | `string` | `null` | Access point region. |

### `package` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `code` | `string` | required | Package code, e.g. `STANDARD`. Not enum-validated here (upstream rejects unknown codes at apply). |

### `notifications` entries

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | required | e.g. `ALL`. |
| `emails` | `list(string)` | required | At least one address (validated). |
| `send_interval` | `string` | `null` | Send interval. |

### `order` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `purchase_order_number` | `string` | `null` | Purchase order number. |
| `order_number` | `string` | `null` | Order reference number. |
| `order_id` | `string` | `null` | Order ID. |
| `billing_tier` | `string` | `null` | Billing tier. |
| `term_length` | `number` | `null` | Months: 1, 12, 24 or 36 (validated). |

## Outputs

| Name | Description |
|---|---|
| `cloud_routers` | Map of key → `{ uuid, id, state, href, equinix_asn, connections_count }`. `uuid` is the import ID and the value to wire into `fabric_connection` (`router.uuid`). |

## Provider

This module only declares `required_providers` (`equinix/equinix`, floor
`>= 5.0.0`), never a `provider {}` block. Configure the provider (auth token
or `client_id`/`client_secret`) at the consumer's Terragrunt unit and pin the
exact version at the root.

## Safe destroy

Renaming a map key or changing `name` destroys and recreates the FCR with
service-affecting downtime and re-provisioning on the connected services.
Treat keys as stable identifiers.

## Example

```hcl
cloud_routers = {
  "example-fcr" = {
    name     = "example-fcr"
    type     = "XF_ROUTER"
    location = {
      metro_code = "SV"
    }
    package = {
      code = "STANDARD"
    }
    project = {
      project_id = "123456789012345"
    }
    notifications = [
      {
        type   = "ALL"
        emails = ["ops@example.com"]
      },
    ]
  },
}
```

To attach a connection, chain the output:

```hcl
dependency "fcr" {
  config_path = "../fcr"
}

locals {
  fcr_uuid = dependency.fcr.outputs.cloud_routers["example-fcr"].uuid
}
```

## Import

- `equinix_fabric_cloud_router` ← `<uuid>`

## Related modules

- `equinix/fabric_connection` — connect the FCR to a port, virtual device,
  service provider, or network.
