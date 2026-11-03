# aws/vpc-endpoints

Map-keyed module for AWS VPC endpoints: gateway endpoints (S3, DynamoDB
— route-table associated) and interface endpoints (PrivateLink — ENI
and security-group wired), one `aws_vpc_endpoint` per entry. Route
table, subnet and security-group associations are inline on the entry;
the module never creates standalone association resources.

## Destroy semantics (read before using)

- Removing a key destroys the endpoint together with its inline
  route-table/subnet/security-group associations; consumer-side
  resources pointing at the endpoint (routes via the prefix list, SG
  rules) are untouched.
- A gateway endpoint carries its route table associations inline; AWS
  deletes the endpoint routes when it deletes the endpoint, so removing
  the key deletes everything cleanly both in and outside Terraform.
- Changing `vpc_endpoint_type`, `vpc_id`, `service_name` or
  `service_region` forces replacement; `route_table_ids`,
  `subnet_ids`, `security_group_ids`, `private_dns_enabled`,
  `ip_address_type`, `dns_options` and `policy` update in place.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `vpc_endpoints` | `map(object)` | `{}` | Map of VPC endpoints keyed by an arbitrary unique identifier. |

### `vpc_endpoints` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `vpc_endpoint_type` | `string` | `Interface` | `Gateway` or `Interface` (validated). Upstream defaults to `Gateway` — set it explicitly when importing existing gateway endpoints. Changing forces replacement. |
| `vpc_id` | `string` | — | VPC for the endpoint. Changing forces replacement. |
| `service_name` | `string` | — | Service name, `com.amazonaws.<region>.<service>` (resolve consumer-side with a `data "aws_vpc_endpoint_service"` lookup). Changing forces replacement. |
| `service_region` | `string` | — | Region of the endpoint service, for cross-region interface endpoints (interface only; provider ≥5.82.0 — no in-module constraint, consumers pin). Changing forces replacement. |
| `route_table_ids` | `list(string)` | `[]` | Route tables to associate — gateway endpoints only (validated; the API rejects them on interface endpoints). |
| `subnet_ids` | `list(string)` | `[]` | Subnets hosting the endpoint ENIs — interface endpoints only, at least one required (both validated; the API rejects subnets on gateway endpoints). |
| `security_group_ids` | `list(string)` | `[]` | Security groups for the endpoint ENIs — interface endpoints only (validated; the API rejects them on gateway endpoints). Empty leaves the VPC default security group associated. |
| `private_dns_enabled` | `bool` | — | Associate the service's private hosted zone with the VPC. Interface endpoints only — leave unset on gateway entries. |
| `ip_address_type` | `string` | — | `ipv4`, `dualstack`, `ipv6` (validated). Interface endpoints only — leave unset on gateway entries. |
| `dns_options` | `object` | — | `{dns_record_ip_type, private_dns_only_for_inbound_resolver_endpoint}`; see the `dns_options` object table. Interface endpoints only. |
| `subnet_configuration` | `list(object)` | — | Fixed IPv4/IPv6 addresses per subnet; see the `subnet_configuration` object table. Interface endpoints only. |
| `auto_accept` | `bool` | — | Accept a pending endpoint connection to an endpoint service in the same account (non-AWS services). |
| `policy` | `string` | — | Endpoint policy as a JSON string (e.g. `data.aws_iam_policy_document` output); unset means full access. All gateway and some interface endpoints support policies — the API is the validator. |
| `name` | `string` | — | Name tag; `aws_vpc_endpoint` has no name argument. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` when set — Name wins on collision (consumer tags win on any other key). |

### `dns_options` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `dns_record_ip_type` | `string` | — | IP type of the endpoint's DNS records: `ipv4`, `dualstack`, `ipv6`, `service-defined` (validated). |
| `private_dns_only_for_inbound_resolver_endpoint` | `bool` | — | S3 multi-VPCE pattern: VPC-originated traffic uses the gateway endpoint, on-premises (inbound-resolver) traffic this interface endpoint. Requires `private_dns_enabled = true` (validated) and a gateway endpoint for the same service to exist first (see Notes). |

### `subnet_configuration` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `subnet_id` | `string` | — | Subnet for this ENI; must also appear in `subnet_ids` (validated). |
| `ipv4` | `string` | — | Fixed IPv4 address for the ENI in that subnet. |
| `ipv6` | `string` | — | Fixed IPv6 address for the ENI in that subnet. |

## Outputs

`endpoint_ids` — map of endpoint key => endpoint ID (`vpce-...`).
`endpoint_arns` — map of endpoint key => endpoint ARN.
`prefix_list_ids` — map of endpoint key => prefix list ID of the exposed service (for security-group egress rules), `null` for interface endpoints. Covers all endpoint keys.
`cidr_blocks` — map of endpoint key => CIDR blocks of the exposed service, `null` for interface endpoints. Covers all endpoint keys.
`dns_names` — map of endpoint key => DNS names of the endpoint, `null` for gateway endpoints. Covers all endpoint keys.
`hosted_zone_ids` — map of endpoint key => private hosted zone IDs of the endpoint's DNS entries, `null` for gateway endpoints. Covers all endpoint keys.
`network_interface_ids` — map of endpoint key => ENI IDs, `null` for gateway endpoints (NACL and flow-log wiring). Covers all endpoint keys.
`states` — map of endpoint key => endpoint state (`available`, `pendingAcceptance`, ...).

Outputs deliberately cover all endpoint keys (not just gateway or
interface ones) — a subset-keyed output makes missing-key vs null
ambiguous for `dependency.*.outputs` consumers.

## Example

```hcl
data "aws_iam_policy_document" "s3" {
  statement {
    sid       = "ExampleArtifactsRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::example-artifacts",
      "arn:aws:s3:::example-artifacts/*",
    ]
  }
}

vpc_endpoints = {
  "s3" = {
    vpc_endpoint_type = "Gateway"
    vpc_id            = dependency.vpc.outputs.vpc_ids["main"]
    service_name      = "com.amazonaws.us-east-1.s3"
    route_table_ids   = [dependency.vpc.outputs.vpc_main_route_table_ids["main"]]
    policy            = data.aws_iam_policy_document.s3.json
  }
  "kms" = {
    vpc_id              = dependency.vpc.outputs.vpc_ids["main"]
    service_name        = "com.amazonaws.us-east-1.kms"
    subnet_ids          = [dependency.subnets.outputs.subnet_ids["private-a"]]
    security_group_ids  = [dependency.security-group.outputs.security_group_ids["endpoints"]]
    private_dns_enabled = true
  }
  # S3 multi-VPCE: VPC-originated traffic goes through the gateway
  # endpoint above, on-premises traffic through this interface endpoint.
  # The gateway endpoint must exist first — see Notes.
  "s3-onprem" = {
    vpc_id              = dependency.vpc.outputs.vpc_ids["main"]
    service_name        = "com.amazonaws.us-east-1.s3"
    subnet_ids          = [dependency.subnets.outputs.subnet_ids["private-a"]]
    private_dns_enabled = true
    dns_options = {
      private_dns_only_for_inbound_resolver_endpoint = true
    }
  }
}
```

## Notes

- Do not manage standalone `aws_vpc_endpoint_route_table_association`,
  `aws_vpc_endpoint_subnet_association` or
  `aws_vpc_endpoint_security_group_association` resources for endpoints
  this module creates: the provider docs warn that using the same
  endpoint in both a VPC endpoint resource (inline
  `route_table_ids`/`subnet_ids`) and an association resource causes
  conflicting associations that overwrite each other. This also
  matters when importing an existing endpoint — drop any standalone
  association resources for it first.
- `route_table_ids` is gateway-only and `subnet_ids`,
  `subnet_configuration`, `security_group_ids` are interface-only —
  cross-use is rejected client-side because the API rejects it.
  `private_dns_enabled`, `ip_address_type`, `dns_options` and
  `service_region` are interface-only upstream too, but with no
  documented hard reject they are not client-validated — leave them
  unset on gateway entries.
- Interface endpoints exist only for specific AWS services (not all of
  them); resolve `service_name` with `data "aws_vpc_endpoint_service"`
  consumer-side. Endpoint services of your own or third parties
  (`aws_vpc_endpoint_service`, the GWLB endpoint pattern) are out of
  scope.
- An interface endpoint with no `security_group_ids` gets the VPC
  default security group associated.
- `prefix_list_ids` and `cidr_blocks` populate for gateway endpoints
  (S3/DynamoDB ranges for SG egress rules); interface endpoints expose
  `dns_names`, `hosted_zone_ids` and `network_interface_ids` instead —
  the type-inapplicable outputs are `null`, keyed over all entries.
- `dns_options.private_dns_only_for_inbound_resolver_endpoint`
  (interface endpoints of services that also have a gateway endpoint —
  S3's multi-VPCE pattern) requires the gateway endpoint for the same
  service to exist first. Map entries are created concurrently, so put
  the gateway endpoint in an earlier Terragrunt unit (`dependency`) or
  a separate module invocation.
- `service_region` needs provider ≥5.82.0 (consumers pin — no in-module
  constraint). `GatewayLoadBalancer` and Lattice
  (`Resource`/`ServiceNetwork`/`Tunnel`) endpoint types are out of
  scope (validated).

## Import

`aws_vpc_endpoint` — endpoint ID only: `vpce-xxxxx`. With Terraform /
OpenTofu 1.12+ `import { identity }` blocks, `region` (and
`account_id`) can be added — relevant for cross-region
(`service_region`) endpoints.
