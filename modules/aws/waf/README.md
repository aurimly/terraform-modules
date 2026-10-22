# aws/waf

Map-keyed module for WAFv2: IP sets, web ACLs (CLOUDFRONT or REGIONAL
scope) with rules built from IP-set references, rate-based limits or
AWS managed rule groups (with rule overrides), module-managed rule
groups that web ACL rules can reference, web ACL logging
configurations, and REGIONAL resource associations (ALBs, API Gateway
stages). Custom statement families (byte match, geo match, SQLi/XSS
significance, label metadata, custom keys) are
deliberately out of scope — for those, don't use this module (they need
a consumer-managed `aws_wafv2_web_acl` with inline `rule` statements or
`rule_json`).

## Destroy semantics (read before using)

- `name`+`scope` are immutable: changing either creates a new object.
- Inline rules take the ordering caveat from the provider: removing a
  rule that references an IP set or rule group can surface
  `WAFAssociatedItemException`/`WAFUnavailableEntityException`-style
  errors, and rule ordering can spuriously diff — for rule deletions
  that keep failing, destroy + recreate the whole web ACL via a
  consumer-side `state rm` plan or flip the ACL to a new key.
- Rule-group/managed references resolve through the module; deleting a
  web ACL whose rules reference module-managed IP sets or rule groups
  takes down the dependents through the standard ordering.
- Removing the `logging` object removes the logging configuration; a
  web ACL key removal destroys the whole ACL and logging config.

## CLOUDFRONT scope needs us-east-1

`CLOUDFRONT`-scope WAF objects **must be created in us-east-1**. The
module takes no provider block of its own, so consumers mix scopes with
a dual-alias provider setup and point the CLOUDFRONT-scoped call at the
us-east-1 alias:

```hcl
module "waf_edge" {
  source    = "git::https://github.com/aurimly/terraform-modules.git//modules/aws/waf?ref=vX.Y.Z"
  providers = { aws = aws.us_east_1 }

  # ...CLOUDFRONT-scope entries...
}

module "waf_regional" {
  source    = "git::https://github.com/aurimly/terraform-modules.git//modules/aws/waf?ref=vX.Y.Z"
  providers = { aws = aws.main }

  # ...REGIONAL-scope entries...
}
```

CloudFront distributions attach the CLOUDFRONT-scope ACL themselves
(`modules/aws/cloudfront`); REGIONAL ACLs attach via `associations`
below. Plan-time checks cannot see provider regions — mixed scopes in
one module call fail at the AWS API in the wrong region.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `ip_sets` | `map(object)` | `{}` | IP sets keyed by an arbitrary unique ID. |
| `web_acls` | `map(object)` | `{}` | Web ACLs keyed by an arbitrary unique ID. |
| `rule_groups` | `map(object)` | `{}` | Rule groups keyed by an arbitrary unique ID. |
| `associations` | `map(object)` | `{}` | REGIONAL web ACL ↔ resource bindings keyed by an arbitrary unique ID. |

### `ip_sets` object

`{name, scope (CLOUDFRONT/REGIONAL, validated), ip_address_version
(IPV4/IPV6, validated), addresses (≥ 1 CIDR block, format-validated),
description, tags}`.

### `web_acls` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Object of alphanumerics/`_` `-`, up to 128 (validated). |
| `scope` | `string` | — | `CLOUDFRONT` or `REGIONAL` (validated). |
| `description` | `string` | — | ACL description. |
| `default_action` | `string` | `allow` | `allow` or `block` (validated). |
| `visibility_config` | `object` | — | Required; `{cloudwatch_metrics_enabled, metric_name (alphanumerics + `_`, up to 128, validated; unique per ACL including rules — validated), sampled_requests_enabled}`. |
| `rules` | `map(object)` | `{}` | Rules keyed by an arbitrary ID; see the rule table row. Inline rules inherit the provider's known quirks: rule deletion can surface `WAFAssociatedItemException`-style ordering errors, and rule ordering can spuriously diff (AWS returns rules in unpredictable order) — rewrite-in-place for structural changes is the safest consumer strategy. |
| `logging` | `object` | — | `{log_destination_configs}` — CloudWatch log group / S3 / Firehose ARNs (Firehose streams must start `aws-waf-logs-`). The destination must allow the WAF service principal consumer-side. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name`. |

### `web_acls.rules` objects

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name. |
| `priority` | `number` | — | Unique per ACL (validated). |
| `action` | `string` | — | `allow`, `block`, `count`, `captcha`, `challenge` (validated). Regular statements use this; managed/rule-group statements use `override_action`. |
| `override_action` | `string` | — | `none` or `count` (validated) — only with managed-rule-group / rule-group statements (validated). |
| `statement` | `object` | — | Exactly one variant (validated): `ip_set_key` (module-managed, scope-matched — preconditions) `ip_set_arn`, `rate_based {limit (positive; AWS enforces the current floor, historically 100), aggregate_key_type (IP/FORWARDED_IP/CONSTANT, validated; CUSTOM_KEYS out of scope), evaluation_window_sec, forwarded_ip_config}`, `managed_rule_group {vendor_name, name, version, rule_action_overrides [{name, action}]}`, `rule_group_key` (module-managed, scope-matched) / `rule_group_arn`. `ip_set_key`+`ip_set_forwarded_ip_config {header_name, fallback_behavior (MATCH/NO_MATCH), position (FIRST/LAST/ANY)}` inspects the forwarded IP inside the referenced set. |
| `visibility_config` | `object` | — | Same shape as the ACL-level one, required per rule. |

### `rule_groups` object

`{name, scope, capacity (required WCU estimate — lower it if the apply
fails with an insufficient-capacity error; up to 2000, validated),
description, visibility_config (required), rules (same `statement`
shape as ACL rules minus managed/rule-group references, which cannot
nest inside a rule group; the `override_action` attribute also drops),
tags}`.

### `associations` object

`{web_acl_key (precondition: REGIONAL ACL), resource_arn}` — ALB,
API Gateway stage ARN (pair with `aws/api-gateway` stage output),
App Runner, API Gateway stage (CLOUDFRONT ACLs attach through
CloudFront distributions, not here).

## Outputs

`ip_set_arns`, `web_acl_arns`, `web_acl_ids` (what a CloudFront
distribution's `web_acl_id` takes), `rule_group_arns`,
`association_ids`.

## Example

```hcl
ip_sets = {
  "office" = {
    name               = "example-office-ranges"
    scope              = "REGIONAL"
    ip_address_version = "IPV4"
    addresses          = ["198.51.100.0/24"]
  }
}
web_acls = {
  "internal" = {
    name  = "example-internal-acl"
    scope = "REGIONAL"
    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name                = "example_internal_acl"
      sampled_requests_enabled   = false
    }
    rules = {
      "common" = {
        name     = "example-common"
        priority = 0
        override_action = "none"
        statement = {
          managed_rule_group = {
            vendor_name = "AWS"
            name        = "AWSManagedRulesCommonRuleSet"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "example_internal_common"
          sampled_requests_enabled   = false
        }
      }
      "rate-limit" = {
        name     = "example-rate"
        priority = 10
        action   = "count"
        statement = {
          rate_based = {
            limit = 2000
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "example_internal_rate"
          sampled_requests_enabled   = false
        }
      }
      "office-only" = {
        name     = "example-office-only"
        priority = 20
        action   = "allow"
        statement = {
          ip_set_key = "office"
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "example_internal_office"
          sampled_requests_enabled   = false
        }
      }
    }
  }
}
associations = {
  "alb" = {
    web_acl_key  = "internal"
    resource_arn = "arn:aws:elasticloadbalancing:eu-central-1:111111111111:loadbalancer/app/example/0000000000000000"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — two IP
  sets may share a name; the key disambiguates.
- Rule groups require a consumer-supplied `capacity` (WCU): pick a
  number and let the apply correct you — AWS rejects insufficient
  capacity at apply time, not plan time.
- Out of scope: custom non-managed statements (byte match, geo match,
  SQLi/XSS, regex, size), `CUSTOM_KEYS` rate aggregates,
  `scope_down_statement` nesting, `custom_request_handling` /
  `custom_response` bodies, `redacted_fields`, `logging_filter`,
  automatically created association resources, and the log destinations
  themselves (create the log group / bucket / stream with other
  modules and pass the ARNs in).
- Statement families beyond these four are not modeled — for those, use
  a consumer-managed `aws_wafv2_web_acl` (inline `rule` statements or
  the `rule_json` attribute) instead of mixing it with this module.
- The provider version floor for the resources used is `>= 6.0.0`.

## Import

(WAFv2 import strings have changed shape across provider releases —
verify against the provider version your consumer pins.)

`aws_wafv2_web_acl` ← `<id>/<name>/<scope>`.
`aws_wafv2_ip_set` ← `<id>/<name>/<scope>`.
`aws_wafv2_rule_group` ← `<id>/<name>/<scope>`.
`aws_wafv2_web_acl_association` ← `<web-acl-arn>,<resource-arn>`.
`aws_wafv2_web_acl_logging_configuration` ← web ACL ARN.
