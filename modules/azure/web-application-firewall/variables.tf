variable "policies" {
  description = "Map of Azure Web Application Firewall policies keyed by an arbitrary identifier. Each entry creates one azurerm_web_application_firewall_policy for Application Gateway WAF v2 — entries feed azure/application-gateway firewall_policy_id (gateway-level on WAF_v2 SKUs or per-listener). The provider's managed_rules block is flattened onto the entry: managed_rule_sets is required (at least one rule set) and exclusions are optional policy-level WAF exclusions. Custom rules are emitted sorted by priority."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    policy_settings = optional(object({
      enabled                                   = optional(bool, true)
      mode                                      = optional(string, "Prevention")
      request_body_check                        = optional(bool, true)
      max_request_body_size_in_kb               = optional(number, 128)
      file_upload_limit_in_mb                   = optional(number, 100)
      file_upload_enforcement                   = optional(bool, true)
      request_body_enforcement                  = optional(bool, true)
      request_body_inspect_limit_in_kb          = optional(number, 128)
      js_challenge_cookie_expiration_in_minutes = optional(number, 30)
      log_scrubbing = optional(object({
        enabled = optional(bool, true)
        rules = optional(map(object({
          match_variable          = string
          selector                = optional(string)
          selector_match_operator = optional(string, "Equals")
          enabled                 = optional(bool, true)
        })), {})
      }))
    }))

    managed_rule_sets = map(object({
      type    = optional(string, "OWASP")
      version = string
      rule_group_overrides = optional(map(object({
        rule_group_name = string
        rules = optional(map(object({
          id      = string
          enabled = optional(bool, true)
          action  = optional(string)
        })), {})
      })), {})
    }))

    exclusions = optional(map(object({
      match_variable          = string
      selector                = string
      selector_match_operator = string
      excluded_rule_set = optional(object({
        type    = optional(string, "OWASP")
        version = optional(string, "3.2")
        rule_groups = optional(map(object({
          rule_group_name = string
          excluded_rules  = optional(list(string), [])
        })), {})
      }))
    })), {})

    custom_rules = optional(map(object({
      name                 = string
      priority             = number
      action               = string
      rule_type            = optional(string, "MatchRule")
      enabled              = optional(bool, true)
      rate_limit_duration  = optional(string)
      rate_limit_threshold = optional(number)
      group_rate_limit_by  = optional(string)
      match_conditions = map(object({
        operator = string
        match_variables = map(object({
          variable_name = string
          selector      = optional(string)
        }))
        match_values       = optional(list(string), [])
        negation_condition = optional(bool, false)
        transforms         = optional(list(string), [])
      }))
    })), {})

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.policies) : !can(regex("\\.", key))
    ])
    error_message = "policies map keys must not contain \".\"."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for key in concat(
          keys(p.custom_rules),
          flatten([for rule in p.custom_rules : concat(keys(rule.match_conditions), flatten([for mc in rule.match_conditions : keys(mc.match_variables)]))])
        ) : !can(regex("\\.", key))
      ]
    ]))
    error_message = "custom_rules, match_conditions and match_variables map keys must not contain \".\"."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for key in concat(
          keys(p.managed_rule_sets),
          flatten([for rule_set in p.managed_rule_sets : concat(keys(rule_set.rule_group_overrides), flatten([for override in rule_set.rule_group_overrides : keys(override.rules)]))])
        ) : !can(regex("\\.", key))
      ]
    ]))
    error_message = "managed_rule_sets, rule_group_overrides and rules map keys must not contain \".\"."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for key in concat(
          keys(p.exclusions),
          flatten([for exclusion in p.exclusions : exclusion.excluded_rule_set != null ? keys(exclusion.excluded_rule_set.rule_groups) : []])
        ) : !can(regex("\\.", key))
      ]
    ]))
    error_message = "exclusions and excluded_rule_set rule_groups map keys must not contain \".\"."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for key in p.policy_settings != null && p.policy_settings.log_scrubbing != null ? keys(p.policy_settings.log_scrubbing.rules) : [] : !can(regex("\\.", key))
      ]
    ]))
    error_message = "log_scrubbing rules map keys must not contain \".\"."
  }

  validation {
    condition = alltrue([
      for p in var.policies : p.policy_settings == null || contains(["Detection", "Prevention"], p.policy_settings.mode)
    ])
    error_message = "policy_settings mode must be one of Detection or Prevention (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule in p.custom_rules : length(trimspace(rule.name)) > 0
      ]
    ]))
    error_message = "custom rule name must not be empty or whitespace — the provider sends an empty rule name to the API when the optional name is unset."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule_names in [[for key, rule in p.custom_rules : rule.name]] : [
          for a in range(length(rule_names)) : alltrue([
            for b in range(length(rule_names)) : a == b || rule_names[a] != rule_names[b]
          ])
        ]
      ]
    ]))
    error_message = "custom rule names must be unique within their policy — the API rejects duplicates."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for priorities in [[for key, rule in p.custom_rules : rule.priority]] : [
          for a in range(length(priorities)) : alltrue([
            for b in range(length(priorities)) : a == b || priorities[a] != priorities[b]
          ])
        ]
      ]
    ]))
    error_message = "custom rule priorities must be unique within their policy — priorities order rule evaluation and the API rejects duplicates."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule in p.custom_rules : contains(["Allow", "Block", "JSChallenge", "Log"], rule.action)
      ]
    ]))
    error_message = "custom rule action must be one of Allow, Block, JSChallenge or Log (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule in p.custom_rules : contains(["MatchRule", "RateLimitRule"], rule.rule_type)
      ]
    ]))
    error_message = "custom rule rule_type must be MatchRule or RateLimitRule (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule in p.custom_rules : [
          rule.rule_type == "RateLimitRule" || (rule.rate_limit_duration == null && rule.rate_limit_threshold == null && rule.group_rate_limit_by == null),
          rule.rule_type != "RateLimitRule" || (rule.rate_limit_duration != null && rule.rate_limit_threshold != null && rule.rate_limit_threshold >= 1)
        ]
      ]
    ]))
    error_message = "rate_limit_duration, rate_limit_threshold and group_rate_limit_by belong to RateLimitRule custom rules only (threshold must be 1 or greater), and a RateLimitRule needs at least rate_limit_duration and rate_limit_threshold set."
  }

  validation {
    condition = alltrue([
      for p in var.policies : alltrue([
        for rule in p.custom_rules : rule.rule_type != "RateLimitRule" || rule.action != "Allow"
      ])
    ])
    error_message = "RateLimitRule custom rules do not support the Allow action — use Block, JSChallenge or Log."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule in p.custom_rules : [
          for mc in rule.match_conditions : [
            mc.operator != "Any" || length(mc.match_values) == 0,
            mc.operator == "Any" || length(mc.match_values) > 0
          ]
        ]
      ]
    ]))
    error_message = "match_values must be empty when the operator is Any (Any matches everything) and non-empty for every other operator."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule in p.custom_rules : [
          for mc in rule.match_conditions : [
            for transform in mc.transforms : contains(["HtmlEntityDecode", "Lowercase", "RemoveNulls", "Trim", "Uppercase", "UrlDecode", "UrlEncode"], transform)
          ]
        ]
      ]
    ]))
    error_message = "transforms entries must be one of HtmlEntityDecode, Lowercase, RemoveNulls, Trim, Uppercase, UrlDecode or UrlEncode (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule in p.custom_rules : [
          for mc in rule.match_conditions : [
            for mv in mc.match_variables : contains(["RemoteAddr", "RequestMethod", "QueryString", "PostArgs", "RequestUri", "RequestHeaders", "RequestBody", "RequestCookies"], mv.variable_name)
          ]
        ]
      ]
    ]))
    error_message = "match_variables variable_name must be one of RemoteAddr, RequestMethod, QueryString, PostArgs, RequestUri, RequestHeaders, RequestBody or RequestCookies (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for p in var.policies : length(p.managed_rule_sets) > 0
    ])
    error_message = "each policy needs at least one managed_rule_sets entry — the provider requires the managed_rules block with at least one managed rule set."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule_set in p.managed_rule_sets : contains(["Microsoft_BotManagerRuleSet", "Microsoft_DefaultRuleSet", "OWASP"], rule_set.type)
      ]
    ]))
    error_message = "managed rule set type must be one of Microsoft_BotManagerRuleSet, Microsoft_DefaultRuleSet or OWASP (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule_set in p.managed_rule_sets : contains(["0.1", "1.0", "1.1", "2.1", "2.2", "2.2.9", "3.0", "3.1", "3.2"], rule_set.version)
      ]
    ]))
    error_message = "managed rule set version must be one of 0.1, 1.0, 1.1, 2.1, 2.2, 2.2.9, 3.0, 3.1 or 3.2 (case-sensitive) — type and version are validated separately; pairings the SKU scope rejects fail at apply, not plan."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule_set in p.managed_rule_sets : [
          for override in rule_set.rule_group_overrides : [
            for rule in override.rules : rule.action != "JSChallenge" || rule_set.type == "Microsoft_BotManagerRuleSet"
          ]
        ]
      ]
    ]))
    error_message = "override rule action JSChallenge is only valid on Microsoft_BotManagerRuleSet rule sets — use another action on other rule set types."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for exclusion in p.exclusions : contains(["RequestArgKeys", "RequestArgNames", "RequestArgValues", "RequestCookieKeys", "RequestCookieNames", "RequestCookieValues", "RequestHeaderKeys", "RequestHeaderNames", "RequestHeaderValues"], exclusion.match_variable)
      ]
    ]))
    error_message = "exclusion match_variable must be one of RequestArgKeys, RequestArgNames, RequestArgValues, RequestCookieKeys, RequestCookieNames, RequestCookieValues, RequestHeaderKeys, RequestHeaderNames or RequestHeaderValues (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for exclusion in p.exclusions : length(trimspace(exclusion.selector)) > 0
      ]
    ]))
    error_message = "exclusion selector must not be empty or whitespace — the provider rejects an empty selector with an unhelpful message."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for exclusion in p.exclusions : contains(["Contains", "EndsWith", "Equals", "EqualsAny", "StartsWith"], exclusion.selector_match_operator)
      ]
    ]))
    error_message = "exclusion selector_match_operator must be one of Contains, EndsWith, Equals, EqualsAny or StartsWith (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for exclusion in p.exclusions : exclusion.excluded_rule_set == null || contains(["Microsoft_BotManagerRuleSet", "Microsoft_DefaultRuleSet", "OWASP"], exclusion.excluded_rule_set.type)
      ]
    ]))
    error_message = "excluded_rule_set type must be one of Microsoft_BotManagerRuleSet, Microsoft_DefaultRuleSet or OWASP (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for exclusion in p.exclusions : exclusion.excluded_rule_set == null || contains(["0.1", "1.0", "1.1", "2.1", "2.2", "2.2.9", "3.0", "3.1", "3.2"], exclusion.excluded_rule_set.version)
      ]
    ]))
    error_message = "excluded_rule_set version must be one of 0.1, 1.0, 1.1, 2.1, 2.2, 2.2.9, 3.0, 3.1 or 3.2 (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.policies : [
        for rule in p.policy_settings != null && p.policy_settings.log_scrubbing != null ? p.policy_settings.log_scrubbing.rules : {} : [
          rule.selector_match_operator != "Equals" || (rule.selector != null && length(trimspace(rule.selector)) > 0)
        ]
      ]
    ]))
    error_message = "log scrubbing rules with the Equals operator need a non-empty selector — Equals matches a specific element; use EqualsAny to scrub the whole variable."
  }

  validation {
    condition = alltrue([
      for p in var.policies : length(p.tags) <= 50 && alltrue([for k, v in p.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
