# cloudflare/ruleset

Map-keyed module for zone-level Cloudflare custom rulesets: WAF custom
rules, rate limits, request/response transforms, redirects, and origin
overrides. Kinds are hardcoded to `custom` — managed, zone, and root
rulesets are Cloudflare-managed or out of scope; only `zone_id` (no
account-level rulesets).

Researched against provider 5.24.0; the `required_providers` floor stays
the repo-wide `>= 5.0.0`. The provider's full `action_parameters` surface
is much larger and grows every release; this module ships a curated
subset (see under `rules`). Consumers needing fields outside the subset
should use the raw `cloudflare_ruleset` resource — one owner per
ruleset, as always.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zone_id` | `string` | — | Cloudflare zone ID. |
| `rulesets` | `map(object)` | — | Map of rulesets keyed by an arbitrary unique ID. |

### `rulesets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `phase` | `string` | — | Ruleset phase, e.g. `http_request_firewall_custom`, `http_ratelimit`, `http_request_transform`, `http_request_redirect`, `http_request_origin`, `http_request_late_transform`, `http_response_headers_transform`. |
| `name` | `string` | — | Ruleset name. Renaming is an in-place update. |
| `description` | `string` | `null` | — |
| `rules` | `list(object)` | `null` | Ordered rules — evaluation order matters, hence a list. See below. |

### `rules` items

| Attribute | Type | Default | Description |
|---|---|---|---|
| `action` | `string` | — | The curated subset is `block`, `challenge`, `js_challenge`, `managed_challenge`, `log`, `log_custom_field`, `skip`, `execute`, `redirect`, `rewrite`, `route`. The provider accepts 20 values in v5.24.0; cache, compression, and the remaining exotic actions are out of scope here. |
| `expression` | `string` | — | Rule expression (Cloudflare Rules language). |
| `description` | `string` | `null` | — |
| `enabled` | `bool` | `null` | — |
| `ref` | `string` | `null` | Rule reference (the ID by default). |
| `logging` | `object` | `null` | `enabled` bool. |
| `ratelimit` | `object` | `null` | Rate limit config — see below. |
| `exposed_credential_check` | `object` | `null` | `username_expression` (required), `password_expression` (required). |
| `action_parameters` | `object` | `null` | Curated subset — see below. |

### `ratelimit` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `characteristics` | `list(string)` | — | Counting dimensions, e.g. `["cf.cname.id", "ip.src"]`. |
| `period` | `number` | — | Window in seconds. |
| `requests_per_period` | `number` | `null` | Threshold. |
| `mitigation_timeout` | `number` | `null` | Seconds the action stays engaged. |
| `counting_expression` | `string` | `null` | Defaults to the rule expression. |
| `requests_to_origin` | `bool` | `null` | Count only when the request reaches the origin. |
| `score_per_period` | `number` | `null` | Score threshold. |
| `score_response_header_name` | `string` | `null` | Origin header carrying the score. |

The module does not couple `ratelimit` to particular actions — the
provider doesn't validate it either and the accepted set has changed
across API versions. Rate limits pair with the rate-limitable actions;
the API rejects invalid combinations at apply.

### `action_parameters` object (curated subset)

Everything is optional except where marked **required**. The full
provider union (v5.24.0: ~70 fields, growing every release) is
deliberately not typed here.

| Attribute | Type | Description |
|---|---|---|
| `overrides` | `object` | Managed-ruleset overrides (`execute` only... see the coupling note): `enabled`, `action`, `sensitivity_level`, `rules` (list: `id` required, `enabled`, `action`, `score_threshold`, `sensitivity_level`), `categories` (list: `category` required, `enabled`, `action`, `sensitivity_level`). |
| `id` | `string` | Managed-ruleset ID targeted by an `execute` rule. |
| `matched_data` | `object` | `public_key` (required) — logging matched WAF data. |
| `response` | `object` | Custom block response: `content`, `content_type`, `status_code` (all required). |
| `phases` | `list(string)` | `skip` — phases to skip. |
| `rulesets` | `list(string)` | `skip` — 32-hex ruleset IDs to skip. |
| `rules` | `map(list(string))` | `skip` — ruleset ID ⇒ rule IDs. |
| `host_header` | `string` | `route` / `origin`. |
| `sni` | `object` | `value` (required) — SNI to the origin. |
| `origin` | `object` | `host`, `port` — origin override. |
| `uri` | `object` | `rewrite` / transforms: `path` and `query`, each `{ value, expression }`. |
| `headers` | `map(object)` | Header rewrites keyed by header name: `operation` (required: `add`, `set`, `remove`), `value`, `expression`. |
| `request_fields` / `response_fields` / `transformed_request_fields` / `cookie_fields` | `list(object)` | Log-custom-field lists: `name` (required), `response_fields` items may also carry `preserve_duplicates`. |
| `from_value` | `object` | `redirect` static target: `target_url` (required: `{ value, expression }`), `status_code`, `preserve_query_string`. |
| `from_list` | `object` | `redirect` list source: `name` (required), `key` (required). |

## Outputs

- `ruleset_ids`, `ruleset_versions` — keyed by ruleset key.

## Notes

- **One ruleset per phase.** Cloudflare allows a single custom ruleset in
  each phase entrypoint; two map entries must not share a `phase` (the
  API rejects it at create).
- `kind` is always `custom`. To manage a phase's Cloudflare-managed
  ruleset or account-level rulesets, use the raw resource.
- The curated `action_parameters` subset targets the supported actions;
  fields exclusive to the excluded actions (cache, compression) won't be
  accepted. This is a scope cut, not an omission — the full union is
  tracked upstream and the raw resource is the escape hatch.
- Rules lists are order-semantic (evaluation order), matching the repo's
  treatment of other ordered sub-collections.
- **Action/parameter coupling is provider-validated at plan time**
  (verified from the v5.24.0 source — `RequiresOtherStringAttributeToBe`
  validators): `matched_data` and `id` (the executed ruleset ID) pair
  with `execute`; `overrides` with `execute`; `phases`, `ruleset` (the
  singular field, which only accepts `"current"` and is not exposed by
  this module), `rulesets` (32-hex IDs), and `rules` pair with `skip`;
  `from_list`/`from_value` with `redirect`; `uri`,
  `headers` with `rewrite`; `host_header`, `origin`, `sni` with `route`;
  `response` with `block`; the `*_fields` with `log_custom_field`;
  cache fields with `set_cache_*`; config fields with `set_config`. The
  module does not duplicate that matrix — invalid pairings fail before
  any API call.

## Example

```hcl
zone_id = "023e105f4ecef8ad9ca31a8372d0c354"

rulesets = {
  "waf-custom" = {
    phase = "http_request_firewall_custom"
    name  = "example-waf-custom"
    rules = [
      {
        action     = "skip"
        expression = "cf.waf.score le 10 and ip.src in {192.0.2.0/24}"
        action_parameters = {
          rulesets = ["a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"]
        }
      },
      {
        action      = "execute"
        expression  = "cf.threat_score gt 50"
        description = "example managed-rules execution with overrides"
        action_parameters = {
          id = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"
          overrides = {
            rules = [
              { id = "b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7", action = "managed_challenge" },
            ]
          }
        }
      },
      {
        action      = "block"
        expression  = "(not starts_with(http.request.uri.path, \"/healthz\"))"
        description = "example plain block with a custom response"
        action_parameters = {
          response = {
            content      = "example block page"
            content_type = "text/html"
            status_code  = 403
          }
        }
      },
    ]
  }
  "rate-limit" = {
    phase = "http_ratelimit"
    name  = "example-rate-limit"
    rules = [
      {
        action     = "block"
        expression = "starts_with(http.request.uri.path, \"/api/\")"
        ratelimit = {
          characteristics     = ["ip.src"]
          period              = 60
          requests_per_period = 30
        }
      },
    ]
  }
  "request-transform" = {
    phase = "http_request_transform"
    name  = "example-request-transform"
    rules = [
      {
        action     = "rewrite"
        expression = "http.host eq \"old.example.com\""
        action_parameters = {
          uri = {
            path = { value = "/v2" }
            query = {
              value = "source=example-redirect"
            }
          }
        }
      },
      {
        action     = "rewrite"
        expression = "true"
        action_parameters = {
          headers = {
            "X-Example-Injection" = { operation = "add", value = "example-header-value" }
          }
        }
      },
    ]
  }
}
```

## Import

| Resource | Import ID |
|---|---|
| `cloudflare_ruleset` | `<zones>/<zone_id>/<ruleset_id>` |
