# aws/vpc

Map-keyed module for AWS VPCs.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `vpcs` | `map(object)` | `{}` | Map of VPCs keyed by an arbitrary unique identifier. |

### `vpcs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name tag applied to the VPC; at most 255 characters. Validated client-side. |
| `cidr_block` | `string` | — | Primary IPv4 CIDR block (e.g. `10.0.0.0/16`; host bits must be unset, validated client-side). Set this **or** the IPAM pair — not both. Immutable; changing forces replacement. |
| `instance_tenancy` | `string` | `default` | One of `default`, `dedicated`, `host` (case-sensitive). Immutable; changing forces replacement. |
| `enable_dns_support` | `bool` | `true` | DNS resolution within the VPC. Updated in place. |
| `enable_dns_hostnames` | `bool` | `false` | DNS hostnames for instances. Updated in place. |
| `enable_network_address_usage_metrics` | `bool` | — | Enable network address usage metrics. |
| `ipv4_ipam_pool_id` | `string` | — | IPAM pool to allocate the CIDR from; requires `ipv4_netmask_length`. |
| `ipv4_netmask_length` | `number` | — | Netmask length to allocate from the IPAM pool; requires `ipv4_ipam_pool_id`. |
| `assign_generated_ipv6_cidr_block` | `bool` | `false` | Assign an Amazon-provided IPv6 `/56` CIDR to the VPC (only relevant for subnets carrying IPv6; legacy edge networks cannot use it). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

Per-entry cross checks (validated client-side): `ipv4_netmask_length` requires `ipv4_ipam_pool_id`, and `ipv4_ipam_pool_id` cannot be set together with `cidr_block` — AWS rejects both forms.

## Outputs

`vpc_ids` — map of VPC key => VPC ID (`vpc-...`).
`vpc_arns` — map of VPC key => VPC ARN.
`vpc_cidr_blocks` — map of VPC key => resolved IPv4 CIDR block (useful when IPAM-assigned).
`vpc_main_route_table_ids` — map of VPC key => ID of the VPC's main route table (route-table wiring in the consumer).

## Example

```hcl
vpcs = {
  "main" = {
    name                   = "example-vpc"
    cidr_block             = "10.0.0.0/16"
    enable_dns_hostnames   = true
    assign_generated_ipv6_cidr_block = true
    tags = {
      Environment = "example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not VPC names. Multiple entries
  can share a `name` (different regions/projects); only the key must be
  unique.
- `cidr_block`, `instance_tenancy` and the IPAM pair force replacement if
  changed; the DNS flags and metrics flag update in place.
- `cidr_block` cannot be modified after creation (the console's CIDR
  adjustment path is out of scope); use a CIDR wide enough for growth.
- Pair with the `aws/subnet` module for subnets (`vpc_ids` output →
  `subnets.*.vpc_id`) and the `aws/security-group` module
  (`vpc_ids` → `security_groups.*.vpc_id`).

## Import

`aws_vpc` — VPC ID only: `vpc-xxxxx`.
