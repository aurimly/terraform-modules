# aws/nat

Map-keyed module for AWS NAT gateways, conventionally one entry per
availability zone (an AWS NAT gateway is single-AZ; multi-AZ egress means
one NAT per AZ).

Each entry creates one `aws_nat_gateway` and — unless `allocation_id` is
passed and connectivity is public — one `aws_eip` for it.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `nat_gateways` | `map(object)` | `{}` | Map of NAT gateways keyed by an arbitrary unique identifier, conventionally one entry per AZ. |

### `nat_gateways` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name tag applied to the EIP and the NAT gateway; at most 255 characters. Validated client-side. |
| `subnet_id` | `string` | — | Public subnet the NAT gateway lives in (typically from `aws/subnet` outputs). Immutable; changing forces replacement. |
| `connectivity_type` | `string` | `public` | `public` (IGW egress, needs an EIP) or `private` (internal-only, no EIP). Immutable; changing forces replacement. |
| `allocation_id` | `string` | — | Allocation ID of an existing EIP to use instead of creating one; public connectivity only (validated client-side). |
| `private_ip` | `string` | — | Private IPv4 address to assign to the NAT gateway in the subnet. |
| `secondary_allocation_ids` | `list(string)` | — | Additional EIPs for multi-IP NAT gateways. |
| `secondary_private_ip_addresses` | `list(string)` | — | Additional private IPv4 addresses. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

## Outputs

`nat_gateway_ids` — map of NAT key => NAT gateway ID (`nat-...`).
`nat_gateway_network_interface_ids` — map of NAT key => ENI ID backing the NAT gateway (for NACL and flow-log wiring).
`allocation_ids` — map of NAT key => resolved EIP allocation ID (created by the module or passed in), `null` for private NAT gateways. Covers all NAT keys.
`public_ips` — map of NAT key => public IPv4 address, `null` for private NAT gateways. Covers all NAT keys.

Outputs deliberately cover all NAT keys (not just the subset with an EIP) — a subset-keyed output makes missing-key vs null ambiguous for `dependency.*.outputs` consumers.

## Example

```hcl
nat_gateways = {
  "az-a" = {
    name      = "example-nat-us-east-1a"
    subnet_id = dependency.subnets.outputs.subnet_ids["public-a"]
  }
  "az-b" = {
    name      = "example-nat-us-east-1b"
    subnet_id = dependency.subnets.outputs.subnet_ids["public-b"]
  }
}
```

## Notes

- One NAT per AZ is the high-availability shape; NAT gateways are zonal,
  so if an AZ fails, only that AZ's egress is affected. Regional NAT
  gateways (`availability_mode = "regional"`) are out of scope.
- A public NAT gateway needs an Internet Gateway in the VPC, and the
  subnet it lives in must route to that IGW. Routing is consumer-side; if
  the IGW is its own Terragrunt unit, add an explicit `dependency` on it
  so ordering is respected (the provider's own example uses
  `depends_on = [aws_internet_gateway]`).
- Private NAT gateways (`connectivity_type = "private"`) take no EIP and
  receive no allocation; private subnets route 0.0.0.0/0 to them
  consumer-side.
- For every public entry the module creates one EIP unless
  `allocation_id` is passed; a module-created EIP is released on destroy,
  a passed-in one is never touched.
- `secondary_allocation_ids` / `secondary_private_ip_addresses` require a
  recent AWS provider (~5.40+; no in-module constraint — consumers pin),
  and must **not** be combined with an `aws_nat_gateway_eip_association`
  resource (perpetual diffs/overwrites). To remove all secondary
  addresses, set empty lists (`[]`) rather than omitting them — `null`
  leaves the attribute unset.

## Import

`aws_nat_gateway` — NAT gateway ID only: `nat-xxxxx`.
`aws_eip` — allocation ID only: `eipalloc-xxxxx` (the legacy import-by-IP-address form is no longer supported upstream).
