# akamai/waf

Map-keyed module for Akamai AppSec (Kona Site Defender core): security configurations, security policies, hostname coverage match targets, WAF rulesets (attack groups + rules), rate policies with actions, slow-POST settings, and staging/production activations.

Out of scope (v1): IP/Geo, reputation, penalty box, custom rules, eval, malware, URL protection, bot management, and the advanced-settings AppSec resources.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `configurations` | `map(object)` | — | AppSec configurations keyed by an arbitrary unique ID. |
| `security_policies` | `map(object)` | — | Security policies, each bound to one configuration via `config_key`. |
| `waf_rulesets` | `map(object)` | — | KSD rulesets, one per (configuration, policy). |
| `match_targets` | `map(object)` | — | Hostname coverage match targets, each bound to one policy via `policy_key`. |
| `rate_policies` | `map(object)` | — | Rate policies. |
| `rate_policy_actions` | `map(object)` | — | IPv4/IPv6 actions for rate policies. |
| `slow_post_settings` | `map(object)` | — | Slow-POST settings, one per (configuration, policy). |
| `activations` | `map(object)` | — | Staging/production activations. |

All keys are arbitrary unique identifiers: they pick the `for_each` instance and appear in resource addresses and outputs only. All cross-references between the maps use these keys, and every reference is validated to exist and to belong to the same configuration.

### `configurations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Configuration name. Must be unique ignoring case across the map (the API requires account-wide uniqueness; the in-module version data source resolves by name). |
| `description` | `string` | — | Free text. |
| `contract_id` | `string` | — | Contract ID (`ctr_` prefix). |
| `group_id` | `string` | — | Group ID (`grp_` prefix). |
| `host_names` | `list(string)` | — | At least one hostname (API requirement to create); validated. |

### `security_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `config_key` | `string` | — | Key of the owning configuration in `configurations` (validated). |
| `security_policy_name` | `string` | — | Policy name. |
| `security_policy_prefix` | `string` | — | Exactly 4 alphanumeric characters, unique within the configuration (validated; the provider does not shape-check). |
| `default_settings` | `bool` | `true` | Blank policy when `false`. `create_from_security_policy_id` requires `false` (validated). |
| `create_from_security_policy_id` | `string` | null | Clone an existing policy instead of creating a blank one. |
| `waf_protection_enabled` | `bool` | null | null ⇒ no `akamai_appsec_waf_protection` toggle resource. See Notes on removal semantics. |
| `rate_protection_enabled` | `bool` | null | null ⇒ no rate enablement toggle. Configuring rate actions does NOT enable the defense — this toggle does. |
| `slowpost_protection_enabled` | `bool` | null | null ⇒ no slow-POST enablement toggle. Same contract as above for slow-POST. |

### `waf_rulesets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `config_key` | `string` | — | Owning configuration. |
| `policy_key` | `string` | — | Owning security policy (must belong to the same configuration — validated). |
| `attack_groups` | `list(object)` | `[]` | `{ attack_group, attack_group_action, condition_exception }`. `attack_group_action` must be `alert`, `deny`, `none` or `deny_custom_<id>` (validated). |
| `rules` | `list(object)` | `[]` | `{ rule_id, rule_action, condition_exception }`. Same action enum as above. |

`condition_exception` is a JSON string. The resource merges **per entry**: listed attack groups and rules are added or updated; entries dropped from the config are reset to action `none`; rules or attack groups the resource never listed are left untouched. One entry set per (configuration, policy) is enforced.

### `match_targets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `config_key` | `string` | — | Owning configuration. |
| `policy_key` | `string` | — | Security policy bound to the target. The module injects `securityPolicy.policyId` from the policy resource, so the binding works on first creation. |
| `match_target` | `string` | — | JSON string encoding ONE target object per the [Match targets docs page](https://techdocs.akamai.com/terraform/docs/match-target-options): `{ "type": "website" | "api", "hostnames": [...], "paths": [...], "fileExtensions": [...], "isNegativePathMatch": bool, "isNegativeFileExtensionMatch": bool }`. Must decode to an object (validated) and must NOT contain a `securityPolicy` member (validated — the module injects it). |

Multiple targets per configuration/policy are legitimate (ordering via `akamai_appsec_match_target_sequence` is out of scope).

### `rate_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `config_key` | `string` | — | Owning configuration. |
| `rate_policy` | `string` | — | JSON string in the Rate policy API shape per the [Rate policy docs page](https://techdocs.akamai.com/terraform/docs/rate-policy-options) (the provider does not model it structurally). |

### `rate_policy_actions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `config_key` | `string` | — | Owning configuration. |
| `policy_key` | `string` | — | Owning security policy. |
| `rate_policy_key` | `string` | — | Rate policy in `rate_policies` (same configuration — validated). |
| `ipv4_action` | `string` | — | One of `alert`, `delay`, `deny`, `monitor`, `none`, `slow`, `tarpit`, or `deny_custom_<id>`, `cond_action_<id>`, `serve_alt_<id>`, `challenge_<id>` (validated). |
| `ipv6_action` | `string` | — | Same enum as `ipv4_action`. |

Multiple entries may target the same policy through different rate policies (the resource identity is configuration + policy + rate policy) — uniqueness is enforced on that triple.

### `slow_post_settings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `config_key` | `string` | — | Owning configuration. |
| `policy_key` | `string` | — | Owning security policy. |
| `slow_rate_action` | `string` | — | `alert` or `abort` (validated). |
| `slow_rate_threshold_rate` | `number` | null | Bytes/sec threshold. |
| `slow_rate_threshold_period` | `number` | null | Period in seconds. |
| `duration_threshold_timeout` | `number` | null | Timeout in seconds. |

### `activations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `config_key` | `string` | — | Configuration to activate. |
| `network` | `string` | — | `STAGING` or `PRODUCTION` (validated). |
| `note` | `string` | null | Activation note. |
| `notification_emails` | `list(string)` | — | At least one email (validated). |
| `version` | `number` | null | Explicit version to deploy. null ⇒ the latest version read by the in-module data source after every mutation resource has applied. One entry per (configuration, network) — enforced. |

## Outputs

All keyed by the input map key of the respective map:

| Output | Description |
|---|---|
| `configuration_ids` | key => numeric `config_id` (import ID base). |
| `configuration_latest_versions` | key => latest version read by the in-module name data source. |
| `security_policy_ids` | configuration key => policy key => policy ID (`xxxx_123456`). |
| `rate_policy_ids` | key => numeric rate policy ID. |
| `match_target_ids` | key => numeric match target ID. |
| `activation_statuses` | key => activation status (indicative only — see Notes). |

## Example

```hcl
module "waf" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/akamai/waf?ref=v2.68.0"

  configurations = {
    "web" = {
      name        = "example.com"
      description = "www.example.com"
      contract_id = "ctr_C-0N7RAC7"
      group_id    = "grp_12345"
      host_names  = ["www.example.com"]
    }
  }

  security_policies = {
    "web-default" = {
      config_key                  = "web"
      security_policy_name        = "default"
      security_policy_prefix      = "abcd"
      waf_protection_enabled      = true
      rate_protection_enabled     = true
      slowpost_protection_enabled = true
    }
    "web-api" = {
      config_key                     = "web"
      security_policy_name           = "api"
      security_policy_prefix         = "efgh"
      default_settings               = false
      create_from_security_policy_id = "abcd_123456"
  } }

  waf_rulesets = {
    "web-default" = {
      config_key = "web"
      policy_key = "web-default"
      attack_groups = [{
        attack_group        = "SQL"
        attack_group_action = "alert"
      }]
    }
  }

  match_targets = {
    "web-default" = {
      config_key = "web"
      policy_key = "web-default"
      match_target = jsonencode({
        type           = "website"
        hostnames      = ["www.example.com"]
        paths          = []
        fileExtensions = []
      })
    }
  }

  rate_policies = {
    "login-flood" = {
      config_key = "web"
      rate_policy = jsonencode({
        name                         = "login-flood"
        prefix                       = "flood"
        averages                     = { requestsPer10xSecond = 100, requestsPerSecond = 10, requestsPerMinute = 5 }
        nameAggregationSlidingWindow = "10 seconds"
        requestInterval              = "1 minute"
        matchExpression              = "http.request.path == \"/login\""
        usePrefix                    = false
        matchType                    = "components"
        type                         = "WAF_Rule"
        clientIdentifier             = "ip"
        additionalMatchOptions       = []
      })
    }
  }

  rate_policy_actions = {
    "login-flood" = {
      config_key      = "web"
      policy_key      = "web-default"
      rate_policy_key = "login-flood"
      ipv4_action     = "tarpit"
      ipv6_action     = "tarpit"
    }
  }

  slow_post_settings = {
    "web-default" = {
      config_key                 = "web"
      policy_key                 = "web-default"
      slow_rate_action           = "abort"
      slow_rate_threshold_rate   = 100
      slow_rate_threshold_period = 10
      duration_threshold_timeout = 60
    }
  }

  activations = {
    "web-staging" = {
      config_key          = "web"
      network             = "STAGING"
      notification_emails = ["secops@example.com"]
    }
  }
}
```

### Wiring records

Downstream units consume `configuration_ids` / `security_policy_ids` with a Terragrunt `dependency` block (Terraform-style `depends_on = [module.waf]` does not exist in Terragrunt):

```hcl
dependency "waf" {
  config_path = "../waf"

  mock_outputs = {
    security_policy_ids = { "web" = { "web-default" = "abcd_123456" } }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  security_policy_id = dependency.waf.outputs.security_policy_ids["web"]["web-default"]
}
```

The mocks exist so `validate`/`plan` work on a fresh clone before the WAF unit has state; the first downstream apply must follow the WAF unit's apply.

### Provider authentication

The Akamai provider authenticates with EdgeGrid credentials — an `~/.edgerc` file (optionally selecting a section with `config_section` in the provider block at the consumer's unit level) or the `AKAMAI_*` environment variables. The consumer unit also needs AppSec authorization for the contract and group. Modules never configure the provider themselves.

## Notes

- `akamai_appsec_waf_ruleset` is labeled beta by Akamai's docs (the underlying API is GA); `akamai_appsec_attack_group` is deprecated in its favor. This module deliberately uses the ruleset resource.
- **Versioning and activation ordering**: sub-resource updates edit the latest *modifiable* version (cloned first when the current one is production-active). The in-module version data source carries an explicit `depends_on` on every mutation resource, so with pending mutations the version read defers to apply time and activations deploy the complete version. Cost: one configuration's activation waits on every other configuration's mutations (deterministic over racy). On a fresh clone the read also defers to apply (the configuration itself is pending); if your Terraform/OpenTofu version instead resolves it earlier and the first plan fails, re-run the plan after the first apply.
- An explicit `version` override deploys exactly that version — it does not include just-mutated unactivated changes unless the version already contains them.
- **Removal is disabling**: removing the WAF-protection toggle (or nulling `waf_protection_enabled`) sets `ApplyApplicationLayerControls: false`; removing a slow-POST settings entry turns slow-post protection off; removing a rate action sets both actions to `none`; dropping an attack group or rule entry from a `waf_rulesets` entry (or destroying the ruleset resource) resets that entry's action to `none` — it stops firing. There is no "leave as created" on transition — these paths change the security posture.
- **Slow-POST toggle vs settings can disagree after partial removal**: removing a `slow_post_settings` entry while keeping `slowpost_protection_enabled = true` applies the settings Delete (which disables slow-POST controls) while the unchanged toggle resource stays true — the module can then activate a version with slow-POST disabled while its input still says enabled, and the next plan surfaces the contradiction as drift. Change the toggle and the settings entries together; on partial removal, set the toggle false/null in the same apply.
- **Enablement vs configuration**: configuring rate actions or slow-POST thresholds does not enable those protections; the `*_protection_enabled` toggles do (they set `ApplyRateControls` / `ApplySlowPostControls`).
- **Activation may move hostnames between configurations**: the provider's activation validation can auto-move hostnames out of another (possibly unmanaged) configuration — it then asks for that configuration's state to be refreshed — and rejects hostnames sourced from multiple configurations. Hostname ownership boundaries and parallel workloads are consumer responsibilities.
- **Activation status is not proof of deployment**: a polling failure that refreshes cleanly surfaces as a warning with the previously active version restored in state, so a green apply or an `ACTIVE`-looking status does not guarantee the requested version deployed. Verify the deployed version via Control Center or the API after activation.
- Activation requires the configuration to have a valid hostname set and at least one match target; with none, the activation fails at apply with an API error (not at plan). Match targets may come from other units.
- `match_target` and `rate_policy` are JSON-string inputs because the provider's own API shape is a JSON blob — see the [Match targets](https://techdocs.akamai.com/terraform/docs/match-target-options) and [Rate policy](https://techdocs.akamai.com/terraform/docs/rate-policy-options) docs pages for the expected fields. The API validates the final payload; when the module's checks cannot run (unknown values at plan time) the API remains the arbiter.
- The rate-action regex is deliberately stricter than the provider validator (which accepts any suffix after the custom-action prefixes): this module requires alphanumeric/underscore suffixes. Values the provider accepts but the module rejects are not API-valid actions.
- The `security_policy_prefix` shape and the IP/Geo-scope exclusions are module policy; the API is the final arbiter.
- The provider floor `>= 12.0.0` is a loose floor; exact pinning is done at the consumer's unit level.
- Terraform/OpenTofu floor: the map cross-reference validations (every `config_key`/`policy_key`/`rate_policy_key` check) reference other variables, a 1.9+ variable-validation feature, and the module declares `required_version = ">= 1.9.0"` accordingly. Older cores fail at `init` with a version error instead of `Invalid reference in variable validation` errors.

## Import

Configuration by numeric ID, policies/rulesets by `configID:securityPolicyID`, match targets by `configID:matchTargetID`, rate policies by `configID:ratePolicyID`, rate actions by `configID:securityPolicyID:ratePolicyID`, slow-POST settings by `configID:securityPolicyID`, activations by `configID:version:network`:

```hcl
import {
  to = module.waf.akamai_appsec_configuration.configuration["web"]
  id = "12345"
}

import {
  to = module.waf.akamai_appsec_security_policy.policy["web-default"]
  id = "12345:abcd_123456"
}

import {
  to = module.waf.akamai_appsec_waf_ruleset.waf_ruleset["web-default"]
  id = "12345:abcd_123456"
}

import {
  to = module.waf.akamai_appsec_activations.activation["web-staging"]
  id = "12345:4:STAGING"
}
```
