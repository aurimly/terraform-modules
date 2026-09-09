# gcp/cloud-armor

Map-keyed module for Google Cloud Armor security policies — IP allow/deny
rules, preconfigured WAF rules, rate limiting, redirects and adaptive
protection. Policies created here attach to load balancers created by
`gcp/load-balancer` (see Outputs).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `security_policies` | `map(object)` | — | Map of security policies keyed by an arbitrary unique ID. |

### `security_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy name, RFC1035 (validated). Immutable. |
| `project_id` | `string` | — | Project the policy lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Free-text description. |
| `type` | `string` | `CLOUD_ARMOR` | One of `CLOUD_ARMOR`, `CLOUD_ARMOR_EDGE`, `CLOUD_ARMOR_INTERNAL_SERVICE` (validated). `CLOUD_ARMOR_EDGE` policies attach to backend buckets via `edge_security_policy`. |
| `deletion_policy` | `string` | `DELETE` | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `advanced_options_config` | `object` | — | Advanced inspection options; see table below. |
| `adaptive_protection_config` | `object` | — | `{layer_7_ddos_defense_config: {enable, rule_visibility}}`; `rule_visibility` one of `STANDARD`, `PREMIUM` (validated) — `PREMIUM` requires the Cloud Armor Enterprise tier. |
| `recaptcha_options_config` | `object` | — | `{redirect_site_key}` for reCAPTCHA-protected actions. |
| `rules` | `list(object)` | `[]` | Policy rules; see the `rules` object table. Order in the list is irrelevant — `priority` decides evaluation order. |

### `advanced_options_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `json_parsing` | `string` | `DISABLED` | One of `STANDARD`, `DISABLED`, `STANDARD_WITH_GRAPHQL` (validated). |
| `log_level` | `string` | `NORMAL` | One of `NORMAL`, `VERBOSE` (validated). |
| `user_ip_request_headers` | `list(string)` | — | Headers used to determine the originating user IP when the immediate peer is not the user. |
| `request_body_inspection_size` | `string` | — | Bytes of the request body to inspect, KB-suffixed (e.g. `16KB`, range `8KB`–`64KB`; shape validated). |
| `json_custom_config` | `object` | — | `{content_types}` list; only allowed when `json_parsing = "STANDARD"` (validated). |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `action` | `string` | — | One of `allow`, `deny(403)`, `deny(404)`, `deny(502)`, `redirect`, `throttle`, `rate_based_ban` (validated). |
| `priority` | `number` | — | 0–2147483647, unique per policy (validated). Priority `2147483647` is the default rule: define a rule there to override the implicit allow-all; omitting `rules` entirely leaves the implicit default allow rule in place. |
| `description` | `string` | — | Free-text description. |
| `preview` | `bool` | — | Preview (dry-run) mode: match counts to logs, no enforcement. |
| `match` | `object` | — | Exactly one of `versioned_expr` + `config` or `expr` (validated). `versioned_expr` must be `SRC_IPS_V1` with non-empty `config.src_ip_ranges`; `expr.expression` is a CEL expression, typically `evaluatePreconfiguredExpr('...')` (validated). |
| `header_action` | `object` | — | `{request_headers_to_adds: [{header_name, header_value}]}` added to matched requests. |
| `rate_limit_options` | `object` | — | Required for `throttle` and `rate_based_ban` actions (validated); see table below. |
| `redirect_options` | `object` | — | For `redirect` actions: `{type, target}`; `type` required (`GOOGLE_RECAPTCHA` or `EXTERNAL_302`), `target` required for `EXTERNAL_302` and forbidden for `GOOGLE_RECAPTCHA` (validated). |
| `preconfigured_waf_config` | `object` | — | `{exclusions: [...]}` — exclusions from preconfigured WAF rule sets; see table below. |

### `rate_limit_options` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `conform_action` | `string` | — | Must be `allow` (validated). |
| `exceed_action` | `string` | — | One of `deny(403)`, `deny(404)`, `deny(429)`, `deny(502)`, `redirect` (validated; `redirect` requires `exceed_redirect_options`). |
| `enforce_on_key` | `string` | — | Single rate-limit key; must be empty when `enforce_on_key_configs` is set (validated). |
| `enforce_on_key_name` | `string` | — | Key name when `enforce_on_key` refers to a named entity (e.g. the header name). |
| `ban_duration_sec` | `number` | — | Ban length for `rate_based_ban` (max 7200). |
| `enforce_on_key_configs` | `list(object)` | — | Multi-key rate limiting: `{enforce_on_key_type, enforce_on_key_name}`; `enforce_on_key_type` one of `ALL`, `IP`, `HTTP_HEADER`, `XFF_IP`, `HTTP_COOKIE`, `HTTP_PATH`, `SNI`, `REGION_CODE`, `TLS_JA3_FINGERPRINT`, `TLS_JA4_FINGERPRINT`, `USER_IP`. |
| `rate_limit_threshold` | `object` | — | Required (validated): `{count, interval_sec}`. |
| `ban_threshold` | `object` | — | Same shape as `rate_limit_threshold`; used by `rate_based_ban`. |
| `exceed_redirect_options` | `object` | — | Same shape and validation as `redirect_options`. |

### `preconfigured_waf_config.exclusions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `target_rule_set` | `string` | — | Preconfigured rule set name, e.g. `sqli-v33-stable`. |
| `target_rule_ids` | `list(string)` | — | Rule IDs within the set to exclude; all rules in the set when omitted. |
| `request_header`, `request_cookie`, `request_uri`, `request_query_param` | `list(object)` | `[]` | Traffic to exclude: `{operator, value}`; operator is an uppercase identifier such as `CONTAINS`, `STARTS_WITH`, `EQUALS` (shape validated). |

## Outputs

`policy_ids` — map of policy key => policy id.
`policy_self_links` — map of policy key => self link. Pass to
`gcp/load-balancer` `backend_services[].security_policy` (for `CLOUD_ARMOR`)
or `backend_buckets[].edge_security_policy` (for `CLOUD_ARMOR_EDGE`).
`policy_fingerprints` — map of policy key => fingerprint.

## Example

```hcl
security_policies = {
  "app" = {
    name        = "example-app-policy"
    description = "allow trusted sources, block known CVEs"

    adaptive_protection_config = {
      layer_7_ddos_defense_config = {
        enable = false
      }
    }

    rules = [
      {
        action      = "allow"
        priority    = 90
        description = "allow trusted sources"
        match = {
          versioned_expr = "SRC_IPS_V1"
          config = {
            src_ip_ranges = ["192.0.2.0/24", "198.51.100.0/24"]
          }
        }
      },
      {
        action      = "deny(403)"
        priority    = 1000
        description = "preconfigured cve rules"
        match = {
          expr = {
            expression = "evaluatePreconfiguredExpr('cve-canary')"
          }
        }
      },
      {
        action      = "deny(403)"
        priority    = 2147483647
        description = "default deny"
        match = {
          versioned_expr = "SRC_IPS_V1"
          config = {
            src_ip_ranges = ["*"]
          }
        }
      },
    ]
  },
}
```

Wired into `gcp/load-balancer`:

```hcl
backend_services = {
  "app" = {
    name            = "example-app-bes"
    security_policy = module.armor.policy_self_links["app"]
    ...
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- `match.expr` uses CEL expressions; `evaluatePreconfiguredExpr('<ruleset>')`
  activates a preconfigured WAF rule set (e.g. `sqli-v33-stable`,
  `xss-v33-stable`, `cve-canary`). Use `preview = true` while tuning rules.
- Rate limiting (`throttle` / `rate_based_ban`) requires
  `rate_limit_options`; `ban_duration_sec` only applies to `rate_based_ban`.
- Pair with `gcp/project-services` (`compute.googleapis.com`) when the target
  project does not have the Compute Engine API enabled yet; this module does
  not enable APIs itself.
- Not implemented (beta-only at the time of writing): `CLOUD_ARMOR_NETWORK`
  policies and their `network_match`/layer-4 rules. File an issue if you need
  them.
- Also not implemented: `match.expr_options` (reCAPTCHA token validation,
  GA but deferred — file an issue if you need it).

## Import

`google_compute_security_policy` ←
`projects/{project}/global/securityPolicies/{name}`.
