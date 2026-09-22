# aws/subnet

Map-keyed module for AWS VPC subnets.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subnets` | `map(object)` | `{}` | Map of subnets keyed by an arbitrary unique identifier. |

### `subnets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name tag applied to the subnet; at most 255 characters. Validated client-side. |
| `vpc_id` | `string` | — | VPC the subnet belongs to (typically `dependency.vpc.outputs.vpc_ids["main"]` with the `aws/vpc` module). Immutable; changing forces replacement. |
| `cidr_block` | `string` | — | IPv4 CIDR block within the VPC (e.g. `10.0.1.0/24`; host bits must be unset, validated client-side). Immutable; changing forces replacement. |
| `availability_zone` | `string` | — | AZ name (e.g. `us-east-1a`). Mutually exclusive with `availability_zone_id` (validated client-side). Immutable. Omit to let AWS choose; see `subnet_availability_zones` output. |
| `availability_zone_id` | `string` | — | AZ ID (e.g. `use1-az1`). Mutually exclusive with `availability_zone`. Immutable. |
| `map_public_ip_on_launch` | `bool` | `false` | Assign a public IPv4 address to instances launched in the subnet. Updated in place. |
| `private_dns_hostname_type_on_launch` | `string` | — | `ip-name` or `resource-name` — hostname type for instances launched with DNS hostnames. |
| `ipv6_cidr_block` | `string` | — | IPv6 CIDR to associate (from the VPC's IPv6 CIDR). |
| `assign_ipv6_address_on_creation` | `bool` | `false` | Assign an IPv6 address to instances launched in the subnet. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

## Outputs

`subnet_ids` — map of subnet key => subnet ID (`subnet-...`).
`subnet_arns` — map of subnet key => subnet ARN.
`subnet_cidr_blocks` — map of subnet key => IPv4 CIDR block.
`subnet_availability_zones` — map of subnet key => AZ the subnet was placed in (useful when `availability_zone` was omitted and AWS picked one).

## Example

```hcl
subnets = {
  "public-a" = {
    name                   = "example-public-us-east-1a"
    vpc_id                 = "vpc-0123456789abcdef0"
    cidr_block             = "10.0.1.0/24"
    availability_zone      = "us-east-1a"
    map_public_ip_on_launch = true
  }
  "private-a" = {
    name              = "example-private-us-east-1a"
    vpc_id            = "vpc-0123456789abcdef0"
    cidr_block        = "10.0.11.0/24"
    availability_zone = "us-east-1a"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not subnet names.
- **Public vs private is routing, not a subnet attribute** — an `aws_subnet`
  has no "public" flag. A subnet is public when its route table sends
  `0.0.0.0/0` to an internet gateway, private when it sends it to a NAT
  gateway. Route tables are consumer-side in this repo; the
  `map_public_ip_on_launch` flag only controls automatic IPv4 assignment at
  launch.
- Pair NAT gateways with the `aws/nat` module, one entry per AZ, pointing
  at the private subnet's AZ:

  ```hcl
  dependency "vpc" {
    config_path = "../vpc"
    mock_outputs = { vpc_ids = { main = "vpc-mock" } }
    mock_outputs_allowed_terraform_commands = ["validate"]
  }

  inputs = {
    subnets = {
      "public-a" = {
        name                    = "example-public-us-east-1a"
        vpc_id                  = dependency.vpc.outputs.vpc_ids["main"]
        cidr_block              = "10.0.1.0/24"
        availability_zone       = "us-east-1a"
        map_public_ip_on_launch = true
      }
    }
  }
  ```
- `cidr_block`, `vpc_id` and the AZ force replacement if changed;
  `map_public_ip_on_launch` and the IPv6 attributes update in place.
- A subnet's CIDR can be resized when the subnet is unused, but that path
  is out of scope here — plan for the CIDR you will keep.
- `availability_zone` is the AZ name (`us-east-1a`), `availability_zone_id`
  is the stable AZ ID (`use1-az1`) that stays constant across accounts.

## Import

`aws_subnet` — subnet ID only: `subnet-xxxxx`.
