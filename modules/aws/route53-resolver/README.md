# aws/route53-resolver

Map-keyed module for AWS Route 53 Resolver: inbound, outbound, and
inbound-delegation endpoints, forward/system/recursive rules with target
IPs, rule-to-VPC associations, and DNSSEC validation configs.

> **Provider floor** — developed against the `aws` provider v6.x: the
> `INBOUND_DELEGATION` direction and the endpoint/`DoH-FIPS` protocol
> enums are v6-era additions; pin v6 or newer on the consumer side.

## Destroy semantics (read before using)

- Endpoint destroy takes minutes (two or more ENIs to delete; provider
  default timeout 10m per operation). Rules reference endpoints, so
  Terraform orders rule deletes before endpoint deletes automatically —
  but associations of a shared rule from another account are not
  ordered against this module's endpoints.
- Removing an association detaches the rule from the VPC only; the rule
  remains. Removing all associations of a rule leaves the rule intact.
- Removing a DNSSEC config stops DNSSEC validation on the VPC — domains
  that need validation start failing during the disable window.
- Changing `direction` replaces the endpoint (new ENIs): outbound
  forward rules referencing the endpoint are destroyed and recreated,
  and inbound clients must re-point at the new `endpoint_ips`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `endpoints` | `map(object)` | `{}` | Map of resolver endpoints keyed by an arbitrary unique ID. |
| `rules` | `map(object)` | `{}` | Map of resolver rules keyed by an arbitrary unique ID. |
| `associations` | `map(object)` | `{}` | Map of rule-to-VPC associations keyed by an arbitrary unique ID. |
| `dnssec_configs` | `map(object)` | `{}` | Map of VPC DNSSEC validation configs keyed by an arbitrary unique ID. |

### `endpoints` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Friendly name (module-required; the API generates one when omitted). Becomes the `Name` tag. |
| `direction` | `string` | — | `INBOUND` (answer queries from your network), `OUTBOUND` (forward queries from VPCs to your network) or `INBOUND_DELEGATION` (delegate queries to private hosted zones); validated. Immutable — changing it replaces the endpoint. |
| `ip_addresses` | `list(object)` | — | `{subnet_id, ip, ipv6}` — one entry per subnet; 2 to 10 entries (validated, subnets in different AZs). `ip`/`ipv6` pin the address inside the subnet; omit for automatic assignment. |
| `security_group_ids` | `set(string)` | — | At least one security group (validated); pass-through, pair with the `aws/security-group` module (ingress tcp/udp 53 for inbound, egress tcp/udp 53 for outbound). |
| `protocols` | `set(string)` | — | `Do53`, `DoH` or `DoH-FIPS` (validated); defaults to `Do53` at the API. |
| `resolver_endpoint_type` | `string` | — | `IPV4`, `IPV6` or `DUALSTACK` (validated); applied to all IP addresses. |
| `rni_enhanced_metrics_enabled` | `bool` | — | RNI enhanced metrics; defaults to `false` at the API (once set, disabling requires explicitly passing `false`). |
| `target_name_server_metrics_enabled` | `bool` | — | Target name server metrics, outbound endpoints only; defaults to `false` (once set, disabling requires explicitly passing `false`). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `domain_name` | `string` | — | DNS queries for this domain are forwarded to the target IPs (e.g. `corp.example.com` or `10.in-addr.arpa`). |
| `rule_type` | `string` | — | `FORWARD`, `SYSTEM` or `RECURSIVE` (validated). FORWARD needs an endpoint and target IPs (validated); SYSTEM and RECURSIVE take neither (validated). |
| `resolver_endpoint_id` | `string` | — | Outbound endpoint ID (`rslvr-out-...`) pass-through for FORWARD rules. Exactly one of this or `endpoint_key` (validated). |
| `endpoint_key` | `string` | — | An `endpoints` map key (the in-module edge; checked at plan/apply). Exactly one of this or `resolver_endpoint_id` (validated). |
| `target_ips` | `list(object)` | — | `{ip, ipv6, port, protocol}` — FORWARD rules need at least one entry (validated), each with exactly one of `ip`/`ipv6` (validated); `port` defaults to 53, `protocol` to `Do53` (`Do53`, `DoH`, `DoH-FIPS`, validated). |
| `name` | `string` | — | Friendly name; defaults to none (the domain is the `Name` tag fallback). |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` or the domain name. |

### `associations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `rule_key` | `string` | — | A `rules` map key (the in-module edge; checked at plan/apply). Exactly one of this or `rule_id` (validated). |
| `rule_id` | `string` | — | Rule ID (`rslvr-rr-...`) pass-through for rules shared from another account. Exactly one of this or `rule_key` (validated). |
| `vpc_id` | `string` | — | VPC to associate the rule with (validated `vpc-...`); pair with the `aws/vpc` module. |
| `name` | `string` | — | Friendly name for the association. |

### `dnssec_configs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `vpc_id` | `string` | — | VPC to enable DNSSEC validation on (validated `vpc-...`); one config per VPC (validated). |

## Outputs

`endpoint_ids`, `endpoint_arns`, `endpoint_host_vpc_ids` — maps of
endpoint key => endpoint ID / ARN / hosting VPC ID.

`endpoint_ips` — map of endpoint key => list of
`{subnet_id, ip, ipv6}`; the inbound addresses on-premises resolvers
forward to, and the outbound addresses firewalls must allow.

`rule_ids`, `rule_arns`, `rule_owner_ids`, `rule_share_statuses` — maps
of rule key => rule ID / ARN / owner account / share status
(`NOT_SHARED`, `SHARED_BY_ME`, `SHARED_WITH_ME`).

`association_ids` — map of association key => association ID
(`rslvr-rrassoc-...`), keyed by the association's own map key.

`dnssec_config_ids`, `dnssec_validation_statuses` — maps of config key
=> config ID (`rdsc-...`) / validation status.

## Example

```hcl
endpoints = {
  "out" = {
    name               = "example-outbound"
    direction          = "OUTBOUND"
    security_group_ids = dependency.security_groups.outputs.security_group_ids["resolver-out"]
    ip_addresses       = [
      { subnet_id = dependency.network.outputs.private_subnet_ids["a"] },
      { subnet_id = dependency.network.outputs.private_subnet_ids["b"] },
    ]
  },
  "in" = {
    name               = "example-inbound"
    direction          = "INBOUND"
    security_group_ids = dependency.security_groups.outputs.security_group_ids["resolver-in"]
    ip_addresses       = [
      { subnet_id = dependency.network.outputs.private_subnet_ids["a"] },
      { subnet_id = dependency.network.outputs.private_subnet_ids["b"] },
    ]
  },
}

rules = {
  "corp" = {
    domain_name = "corp.example.com"
    rule_type   = "FORWARD"
    endpoint_key = "out"
    target_ips  = [
      { ip = "10.0.8.10" },
      { ip = "10.0.16.10" },
    ]
  },
  "reverse-10" = {
    domain_name = "10.in-addr.arpa"
    rule_type   = "FORWARD"
    endpoint_key = "out"
    target_ips  = [
      { ip = "10.0.8.10" },
    ]
  },
  "system-aws-internal" = {
    domain_name = "aws.internal"
    rule_type   = "SYSTEM"
  },
}

associations = {
  "corp-prod" = {
    rule_key = "corp"
    vpc_id   = dependency.network.outputs.vpc_ids["prod"]
  },
  "corp-staging" = {
    rule_key = "corp"
    vpc_id   = dependency.network.outputs.vpc_ids["staging"]
  },
  "reverse-prod" = {
    rule_key = "reverse-10"
    vpc_id   = dependency.network.outputs.vpc_ids["prod"]
  },
  "reverse-staging" = {
    rule_key = "reverse-10"
    vpc_id   = dependency.network.outputs.vpc_ids["staging"]
  },
}

dnssec_configs = {
  "prod" = {
    vpc_id = dependency.network.outputs.vpc_ids["prod"]
  },
}
```

On-premises resolvers forward `example.com` queries to the inbound
endpoint: `dependency.resolver.outputs.endpoint_ips["in"]`.

## Notes

- Pair with `aws/security-group` (port 53 ingress/egress) and
  `aws/vpc`/`aws/subnet` (endpoint subnets across two AZs).
- Keys are arbitrary unique identifiers; all four maps iterate by their
  own keys — no composite keys anywhere in this module.
- Endpoint `name` is module-required although the API allows omitting
  it; the generated name is not deterministic.
- Cross-account rule sharing is consumer-side: share the rule via RAM
  (the `rule_arns`/`rule_owner_ids` outputs feed the share), then
  associate in the consumer account with `rule_id`. Out of scope here.
- Route 53 Resolver firewall resources (domain lists, rule groups,
  firewall configs) are a different API family and out of scope for
  this module.
- SYSTEM rules: AWS auto-creates one per VPC for internal domains;
  explicit SYSTEM entries exist for completeness — most consumers only
  need FORWARD.

## Import

`aws_route53_resolver_endpoint` ← endpoint ID (`rslvr-in-...`/`rslvr-out-...`).
`aws_route53_resolver_rule` ← rule ID (`rslvr-rr-...`).
`aws_route53_resolver_rule_association` ← association ID
(`rslvr-rrassoc-...`).
`aws_route53_resolver_dnssec_config` ← config ID (`rdsc-...`).
