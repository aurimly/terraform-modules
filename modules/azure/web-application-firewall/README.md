# azure/web-application-firewall

> **Provider floor** — developed against the `azurerm` provider v5.x
> (v5.9.0 at build time); nothing is pinned in-module — pin the provider
> version at the consumer's root Terragrunt level.

Map-keyed module for Azure Web Application Firewall policies. Each entry
creates one `azurerm_web_application_firewall_policy` — the Application
Gateway WAF v2 policy resource, consumed by `azure/application-gateway` as
`firewall_policy_id` (gateway-level on `WAF_v2` SKUs or per-listener in
`http_listeners`). The provider's required `managed_rules` block is
flattened onto the entry (`managed_rule_sets`, `exclusions`); custom rules
are emitted sorted by `priority`.

Scope: Application Gateway only. Front Door Standard/Premium WAF policies
are the separate `azurerm_cdn_frontdoor_firewall_policy` resource (attached
via `azurerm_cdn_frontdoor_security_policy`), and classic Front Door is the
deprecated `azurerm_frontdoor_firewall_policy` — neither is this module.

## Destroy semantics (read before using)

- **Deletion is blocked while a policy is attached.** Azure refuses to
  delete a policy that an Application Gateway references. Since
  `azure/application-gateway` takes `firewall_policy_id` as a plain string
  pass-through, there is no provider-side ordering between the two stacks:
  dropping a policy key while a gateway still references the ID fails at
  apply. Remove the gateway's `firewall_policy_id` first, apply, then remove
  the policy entry.
- Renaming a policy entry (`name`, `resource_group_name` or `location`)
  forces replacement; attached gateways keep pointing at the old (now
  deleted) ID until re-applied.
- Removing a custom-rule, exclusion or override key only edits the policy
  in place.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `policies` | `map(object)` | `{}` | Map of WAF policies keyed by an arbitrary unique ID. |

Map keys must not contain `.` at any level.

Plan-time validation: policy settings `mode` within the documented values;
custom rules with non-empty unique names, unique priorities, `action` and
`rule_type` within the documented values, the rate-limit trio restricted
to `RateLimitRule` rules (threshold set to 1 or greater, `Allow` action
rejected there), `match_values` empty exactly when the operator is `Any`,
transform and variable-name enums; managed rule sets present with at least
one entry with type and version within the flat provider enums, override
rule action `JSChallenge` only on `Microsoft_BotManagerRuleSet`; exclusions
with non-empty selectors and their enums; log-scrubbing rules carrying a
selector when their operator is `Equals`; and tags within Azure's limits.

### `policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy name. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the policy lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `policy_settings` | `object` | `null` | Policy-level settings (see below). |
| `managed_rule_sets` | `map(object)` | — | Managed rule sets (see below) — required, at least one entry (validated); the provider's `managed_rules` block is flattened onto the entry. |
| `exclusions` | `map(object)` | `{}` | Policy-level WAF exclusions (see below). |
| `custom_rules` | `map(object)` | `{}` | Custom rules (see below), emitted sorted by `priority`. |
| `tags` | `map(string)` | `{}` | Tags. |

Deliberately not exposed (candidates for a later minor): the read-only
association attributes `http_listener_ids` and `path_based_rule_ids`
(associations are owned by `azure/application-gateway` on its side),
`timeouts`, and the CAPTCHA-cookie settings — CAPTCHA expiration exists at
the API level but is absent from the pinned azurerm 5.9.0 schema (as is the
never-shipped `js_challenge_cookie_consent_values`).

### `policy_settings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `true` | Whether the policy is enabled. |
| `mode` | `string` | `Prevention` | `Detection` or `Prevention` (validated). |
| `request_body_check` | `bool` | `true` | Whether the WAF inspects request bodies. |
| `max_request_body_size_in_kb` | `number` | `128` | Maximum request body size in KB, 8–2000. |
| `file_upload_limit_in_mb` | `number` | `100` | Maximum file upload size in MB, 1–4000. |
| `file_upload_enforcement` | `bool` | `true` | Whether the WAF blocks uploads past `file_upload_limit_in_mb`. Explicit module default: the provider schema carries no default and always sends the value — unset would read `false` and silently disable enforcement. The API ties this setting to OWASP 3.2-class rule sets (see Notes). |
| `request_body_enforcement` | `bool` | `true` | Whether the WAF blocks requests past `max_request_body_size_in_kb`. |
| `request_body_inspect_limit_in_kb` | `number` | `128` | Maximum request body inspection limit in KB. |
| `js_challenge_cookie_expiration_in_minutes` | `number` | `30` | JavaScript challenge cookie lifetime in minutes, 5–1440. |
| `log_scrubbing` | `object` | `null` | Log scrubbing (see below). |

`log_scrubbing` entries:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `true` | Whether log scrubbing is enabled. |
| `rules` | `map(object)` | `{}` | Scrubbing rules, keyed by an arbitrary ID (see below). |

Scrubbing rules shape: `match_variable` (one of `RequestHeaderNames`,
`RequestCookieNames`, `RequestArgNames`, `RequestPostArgNames`,
`RequestJSONArgNames` or `RequestIPAddress`), `selector` (optional),
`selector_match_operator` (`Equals`, the default, or `EqualsAny`) and
`enabled` (default `true`). `Equals` needs a non-empty `selector`
(validated); `EqualsAny` applies to the whole variable.

### `managed_rule_sets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | `OWASP` | `Microsoft_BotManagerRuleSet`, `Microsoft_DefaultRuleSet` or `OWASP` (validated). |
| `version` | `string` | — | One of `0.1`, `1.0`, `1.1`, `2.1`, `2.2`, `2.2.9`, `3.0`, `3.1` or `3.2` (validated as a flat enum — pairings are checked at apply, not plan; see the matrix in Notes). |
| `rule_group_overrides` | `map(object)` | `{}` | Per-rule-group overrides (see below). |

`rule_group_overrides` entries:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `rule_group_name` | `string` | — | Managed rule group to override (e.g. `REQUEST-920-PROTOCOL-ENFORCEMENT`, `BadBots`). |
| `rules` | `map(object)` | `{}` | Per-rule overrides (see below). |

Override `rules` shape: `id` (the managed rule ID, e.g. `920300`),
`enabled` (default `true` in this module — see Notes for the deliberate
divergence from the provider default) and `action` (`Allow`,
`AnomalyScoring`, `Block`, `JSChallenge` or `Log`; `JSChallenge` is only
valid on `Microsoft_BotManagerRuleSet`, validated).

### `exclusions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `match_variable` | `string` | — | One of `RequestArgKeys`, `RequestArgNames`, `RequestArgValues`, `RequestCookieKeys`, `RequestCookieNames`, `RequestCookieValues`, `RequestHeaderKeys`, `RequestHeaderNames` or `RequestHeaderValues` (provider-checked). |
| `selector` | `string` | — | The element of the collection to exclude — must not be empty or whitespace (validated; the provider's rejection of an empty selector is unhelpful). |
| `selector_match_operator` | `string` | — | `Contains`, `EndsWith`, `Equals`, `EqualsAny` or `StartsWith` (validated). |
| `excluded_rule_set` | `object` | `null` | Single optional excluded rule set (see below) — the provider block is max one per exclusion, so this is an object, not a map. |

`excluded_rule_set` shape: `type` (default `OWASP`, validated), `version`
(default `3.2`, validated against the flat enum) and `rule_groups` (a map
of `{ rule_group_name, excluded_rules }` entries, `excluded_rules` being a
list of rule IDs to exclude within the group).

### `custom_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name, unique within the policy (validated) — required and non-empty (validated): the provider sends an empty string to the API when its optional name is unset. |
| `priority` | `number` | — | Evaluation order, lower first, unique within the policy (validated). Application Gateway documents 1–100 — see Notes for why the module does not validate the range. |
| `action` | `string` | — | `Allow`, `Block`, `JSChallenge` or `Log` (validated); `Allow` is rejected on `RateLimitRule` (validated). |
| `rule_type` | `string` | `MatchRule` | `MatchRule` or `RateLimitRule` (validated). |
| `enabled` | `bool` | `true` | Whether the rule is evaluated. |
| `rate_limit_duration` | `string` | `null` | `FiveMins` or `OneMin`; `RateLimitRule` only (validated as part of the rate-limit trio). |
| `rate_limit_threshold` | `number` | `null` | Threshold, 1 or greater; `RateLimitRule` only (validated). |
| `group_rate_limit_by` | `string` | `null` | `ClientAddr`, `ClientAddrXFFHeader`, `GeoLocation`, `GeoLocationXFFHeader` or `None`; `RateLimitRule` only (validated as part of the trio — the value's enum is provider-checked). |
| `match_conditions` | `map(object)` | — | Match conditions (see below) — required; the provider needs at least one entry. |

`match_conditions` entries:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `operator` | `string` | — | `Any`, `IPMatch`, `GeoMatch`, `Equal`, `Contains`, `LessThan`, `GreaterThan`, `LessThanOrEqual`, `GreaterThanOrEqual`, `BeginsWith`, `EndsWith` or `Regex` (provider-checked). |
| `match_variables` | `map(object)` | — | Match variables (see below) — required; the provider needs at least one entry. |
| `match_values` | `list(string)` | `[]` | Values to match — empty when the operator is `Any`, non-empty otherwise (validated). |
| `negation_condition` | `bool` | `false` | Whether the condition result is negated. |
| `transforms` | `list(string)` | `[]` | `HtmlEntityDecode`, `Lowercase`, `RemoveNulls`, `Trim`, `Uppercase`, `UrlDecode` or `UrlEncode` (validated). |

`match_variables` shape: `variable_name` — one of `RemoteAddr`,
`RequestMethod`, `QueryString`, `PostArgs`, `RequestUri`, `RequestHeaders`,
`RequestBody` or `RequestCookies` (validated) — plus an optional `selector`
naming the element within collection variables (e.g. `UserAgent` for
`RequestHeaders`).

## Outputs

| Name | Description |
|---|---|
| `policy_ids` | Map of policies key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/<name>`) — feed `azure/application-gateway` `firewall_policy_id`. |
| `policy_names` | Map of policies key => policy name. |

## Example

```hcl
policies = {
  "web" = {
    name                = "wafp-web-prod"
    resource_group_name = "rg-network-prod"
    location            = "westeurope"

    policy_settings = {
      enabled                                   = true
      mode                                      = "Prevention"
      request_body_check                        = true
      max_request_body_size_in_kb               = 128
      file_upload_limit_in_mb                   = 100
      file_upload_enforcement                   = true
      request_body_enforcement                  = true
      request_body_inspect_limit_in_kb          = 128
      js_challenge_cookie_expiration_in_minutes = 30

      log_scrubbing = {
        enabled = true
        rules = {
          "auth-cookie" = {
            match_variable = "RequestCookieNames"
            selector       = "session-token"
          }
        }
      }
    }

    managed_rule_sets = {
      "owasp" = {
        type    = "OWASP"
        version = "3.2"

        rule_group_overrides = {
          "protocol-enforcement" = {
            rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"

            rules = {
              "920300" = {
                id     = "920300"
                action = "Log"
              }

              "920440" = {
                id     = "920440"
                action = "Block"
              }
            }
          }
        }
      }
    }

    exclusions = {
      "verification-token" = {
        match_variable          = "RequestArgNames"
        selector                = "__RequestVerificationToken"
        selector_match_operator = "Equals"

        excluded_rule_set = {
          type    = "OWASP"
          version = "3.2"

          rule_groups = {
            "sqli" = {
              rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
              excluded_rules  = ["942100"]
            }
          }
        }
      }
    }

    custom_rules = {
      "block-scanner-net" = {
        name     = "block-scanner-net"
        priority = 100
        action   = "Block"

        match_conditions = {
          "source" = {
            operator     = "IPMatch"
            match_values = ["203.0.113.0/24"]

            match_variables = {
              "remote-addr" = {
                variable_name = "RemoteAddr"
              }
            }
          }
        }
      }

      "geo-allow" = {
        name      = "geo-allow"
        priority  = 200
        action    = "Allow"
        enabled   = true

        match_conditions = {
          "geo" = {
            operator           = "GeoMatch"
            negation_condition = true
            match_values       = ["US"]

            match_variables = {
              "remote-addr" = {
                variable_name = "RemoteAddr"
              }
            }

            transforms = ["Lowercase", "Trim"]
          }
        }
      }
    }

    tags = {
      env = "prod"
    }
  }
}
```

## Notes

- **Managed rule-set type/version matrix.** `type` and `version` are each
  validated against flat enums only — a pairing the SKU scope rejects is
  rejected at **apply**, never at plan. Pairings per Azure docs:

  | `type` | `version` | Application Gateway (this module) | Front Door Standard/Premium (separate `azurerm_cdn_frontdoor_firewall_policy`) |
  |---|---|---|---|
  | `Microsoft_DefaultRuleSet` | `2.2` | supported (current generation) | supported (Premium) |
  | `Microsoft_DefaultRuleSet` | `2.1` | supported | supported (Premium) |
  | `Microsoft_DefaultRuleSet` | `2.0` | not accepted | supported (Premium) |
  | `Microsoft_BotManagerRuleSet` | `1.1` | supported | supported (Premium) |
  | `Microsoft_BotManagerRuleSet` | `1.0` | supported | supported (Premium) |
  | `Microsoft_BotManagerRuleSet` | `0.1` | preview, not supported | preview |
  | `OWASP` | `3.2` | supported (WAF_v2 SKU only, legacy generation) | not accepted |
  | `OWASP` | `3.1` | legacy — new-policy creation ended June 2026, support ends February 2027 | not accepted |
  | `OWASP` | `3.0` | legacy — same dates as 3.1 | not accepted |
  | `OWASP` | `2.2.9` | not supported since March 2025 | not accepted |

- **Custom-rule `priority`.** No module-level range validation: the
  provider schema has no validator on `priority` and neither does the API.
  Application Gateway documents 1–100, unique across the policy's custom
  rules — uniqueness is validated here, the range is not, so values outside
  1–100 surface as API rejections at apply.
- **Override rules default to enabled.** Unset ⇒ `enabled = true` in this
  module; the provider default is `false` and the provider always sends the
  state — relying on the provider default would silently disable every
  overridden rule left unset.
- **Action scoping.** Override-rule `JSChallenge` is only valid on
  `Microsoft_BotManagerRuleSet` (validated); the JS challenge feature on
  Application Gateway is in preview and its action is not supported on
  `RateLimitRule` custom rules during the preview. DRS/CRS rule actions are
  block/log/anomaly-scoring; the Bot Manager rule set supports
  allow/block/log.
- **Body-size and upload knobs are Application-Gateway-scope attributes**
  of this resource: `request_body_enforcement`,
  `request_body_inspect_limit_in_kb` and `file_upload_enforcement`. The
  provider's schema notes `file_upload_enforcement` is only available under
  certain conditions (OWASP 3.2-class rule sets) — the API may reject it on
  other rule-set versions at apply.
- **`js_challenge_cookie_expiration_in_minutes` imports.** Policies
  imported from pre-fix provider state read `0` from the API; the v5.9.0
  flatten maps `0` back to the default `30` (azure-rest-api-specs#36330) —
  import-safe.
- **Rate-limit rules.** The rate-limit trio belongs to `RateLimitRule`
  (validated) and `RateLimitRule` forbids `Allow` (validated,
  provider-documented). Per Azure's design guide, Application Gateway WAF
  supports rate limiting.
- **Log scrubbing.** `Equals` targets one selector (validated non-empty);
  `EqualsAny` applies to the whole variable (e.g. `RequestIPAddress`).
- **Duplicate policy-level exclusions are not validated.** Azure likely
  rejects exact-duplicate triples at apply; distinct selectors or match
  variables make entries distinct.
- **Exclusions are policy-level** in this resource model — rule-group
  scoping rides the `excluded_rule_set` nesting, unlike the classic Front
  Door resource's per-override exclusions.
- **`custom_rules` block churn.** The provider block is a list that diffs
  positionally; Azure returns rules in priority order, so the module emits
  them sorted by `priority` to keep plans stable. A one-rule edit still
  re-positions later rules in the list — group policy edits into one apply.
  The set caveat applies only to `transforms` (set-typed upstream).
- The caller needs
  `Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/write`
  plus reader access to the resource group.

## Import

```shell
tofu import 'azurerm_web_application_firewall_policy.policy["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/<name>"
```
