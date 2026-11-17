variable "configurations" {
  description = "Map of AppSec configurations keyed by an arbitrary unique identifier. Keys only pick the for_each instance and appear in resource addresses and outputs; the name inside the entry is what the API sees."
  type = map(object({
    name        = string
    description = string
    contract_id = string
    group_id    = string
    host_names  = list(string)
  }))

  validation {
    condition     = alltrue([for c in var.configurations : length(c.host_names) >= 1])
    error_message = "host_names must contain at least one hostname (an API requirement to create the configuration)."
  }

  validation {
    condition     = alltrue([for c in var.configurations : length(c.name) >= 1])
    error_message = "name must not be empty."
  }

  validation {
    condition     = length(distinct([for c in var.configurations : lower(c.name)])) == length(var.configurations)
    error_message = "configuration names must be unique ignoring case: the in-module version data source resolves configurations by name."
  }
}

variable "security_policies" {
  description = "Map of security policies keyed by an arbitrary unique identifier. Each entry belongs to exactly one configuration (config_key). The three *_protection_enabled toggles are nullable: null means the toggle resource is absent (a policy stays as created on first apply, but see the README removal notes)."
  type = map(object({
    config_key                     = string
    security_policy_name           = string
    security_policy_prefix         = string
    default_settings               = optional(bool, true)
    create_from_security_policy_id = optional(string)
    waf_protection_enabled         = optional(bool)
    rate_protection_enabled        = optional(bool)
    slowpost_protection_enabled    = optional(bool)
  }))

  validation {
    condition     = alltrue([for p in var.security_policies : contains(keys(var.configurations), p.config_key)])
    error_message = "every config_key must be one of the keys of var.configurations. Offending keys: ${join(", ", [for k, v in var.security_policies : k if !contains(keys(var.configurations), v.config_key)])}."
  }

  validation {
    condition     = alltrue([for p in var.security_policies : can(regex("^[A-Za-z0-9]{4}$", p.security_policy_prefix))])
    error_message = "security_policy_prefix must be exactly 4 alphanumeric characters (module policy; the provider does not shape-check it, and the prefix must be unique within the configuration). Offending keys: ${join(", ", [for k, v in var.security_policies : k if !can(regex("^[A-Za-z0-9]{4}$", v.security_policy_prefix))])}."
  }

  validation {
    condition     = alltrue([for p in var.security_policies : p.create_from_security_policy_id == null || !p.default_settings])
    error_message = "create_from_security_policy_id requires default_settings = false: the provider would otherwise create a default-settings policy and ignore the clone."
  }
}

variable "waf_rulesets" {
  description = "Map of KSD ruleset entry sets keyed by an arbitrary unique identifier; one entry set per (configuration, policy). The resource merges per entry: listed attack groups and rules are added or updated, entries dropped from the config are reset to attack_group_action/rule_action none, and rules or attack groups the resource never listed are left untouched."
  type = map(object({
    config_key = string
    policy_key = string
    attack_groups = optional(list(object({
      attack_group        = string
      attack_group_action = string
      condition_exception = optional(string)
    })), [])
    rules = optional(list(object({
      rule_id             = number
      rule_action         = string
      condition_exception = optional(string)
    })), [])
  }))

  validation {
    condition     = alltrue([for r in var.waf_rulesets : contains(keys(var.configurations), r.config_key)])
    error_message = "every config_key must be one of the keys of var.configurations. Offending keys: ${join(", ", [for k, v in var.waf_rulesets : k if !contains(keys(var.configurations), v.config_key)])}."
  }

  validation {
    condition     = alltrue([for r in var.waf_rulesets : contains(keys(var.security_policies), r.policy_key)])
    error_message = "every policy_key must be one of the keys of var.security_policies. Offending keys: ${join(", ", [for k, v in var.waf_rulesets : k if !contains(keys(var.security_policies), v.policy_key)])}."
  }

  validation {
    condition     = alltrue([for r in var.waf_rulesets : try(var.security_policies[r.policy_key].config_key == r.config_key, false)])
    error_message = "waf_rulesets entries must reference a policy that belongs to the same configuration (the referenced policy's config_key must equal the entry's config_key). Offending keys: ${join(", ", [for k, v in var.waf_rulesets : k if !try(var.security_policies[v.policy_key].config_key == v.config_key, false)])}."
  }

  validation {
    condition = alltrue([for r in var.waf_rulesets :
      alltrue([for g in r.attack_groups : can(regex("^(alert|deny|deny_custom_[A-Za-z0-9_]+|none)$", g.attack_group_action))]) &&
    alltrue([for u in r.rules : can(regex("^(alert|deny|deny_custom_[A-Za-z0-9_]+|none)$", u.rule_action))])])
    error_message = "attack_group_action and rule_action must be one of alert, deny, none, or deny_custom_<id>."
  }

  validation {
    condition     = length(distinct([for r in var.waf_rulesets : "${r.config_key}/${r.policy_key}"])) == length(var.waf_rulesets)
    error_message = "each (config_key, policy_key) combination may appear at most once: one entry set resource owns the ruleset entries for one policy. Offending keys: ${join(", ", [for k, r in var.waf_rulesets : k if length([for k2, r2 in var.waf_rulesets : k2 if k2 != k && r2.config_key == r.config_key && r2.policy_key == r.policy_key]) > 0])}."
  }
}

variable "match_targets" {
  description = "Map of hostname coverage match targets keyed by an arbitrary unique identifier. match_target is a JSON string encoding one target object WITHOUT a securityPolicy member — the module injects securityPolicy.policyId from policy_key."
  type = map(object({
    config_key   = string
    policy_key   = string
    match_target = string
  }))

  validation {
    condition     = alltrue([for t in var.match_targets : contains(keys(var.configurations), t.config_key)])
    error_message = "every config_key must be one of the keys of var.configurations. Offending keys: ${join(", ", [for k, v in var.match_targets : k if !contains(keys(var.configurations), v.config_key)])}."
  }

  validation {
    condition     = alltrue([for t in var.match_targets : contains(keys(var.security_policies), t.policy_key)])
    error_message = "every policy_key must be one of the keys of var.security_policies. Offending keys: ${join(", ", [for k, v in var.match_targets : k if !contains(keys(var.security_policies), v.policy_key)])}."
  }

  validation {
    condition     = alltrue([for t in var.match_targets : try(var.security_policies[t.policy_key].config_key == t.config_key, false)])
    error_message = "match_targets entries must reference a policy that belongs to the same configuration (the referenced policy's config_key must equal the entry's config_key). Offending keys: ${join(", ", [for k, v in var.match_targets : k if !try(var.security_policies[v.policy_key].config_key == v.config_key, false)])}."
  }

  validation {
    condition     = alltrue([for t in var.match_targets : can(keys(jsondecode(t.match_target)))])
    error_message = "match_target must be a JSON string encoding one object (e.g. {\"type\": \"website\", \"hostnames\": [...], \"paths\": []}); arrays, nulls and plain strings are rejected."
  }

  validation {
    condition     = alltrue([for t in var.match_targets : try(!contains(keys(jsondecode(t.match_target)), "securityPolicy"), true)])
    error_message = "match_target must not contain a securityPolicy member: the module injects it from policy_key."
  }
}

variable "rate_policies" {
  description = "Map of rate policies keyed by an arbitrary unique identifier. rate_policy is a JSON string in the Rate policy API shape (the provider does not model it structurally)."
  type = map(object({
    config_key  = string
    rate_policy = string
  }))

  validation {
    condition     = alltrue([for r in var.rate_policies : contains(keys(var.configurations), r.config_key)])
    error_message = "every config_key must be one of the keys of var.configurations. Offending keys: ${join(", ", [for k, v in var.rate_policies : k if !contains(keys(var.configurations), v.config_key)])}."
  }
}

variable "rate_policy_actions" {
  description = "Map of rate policy actions keyed by an arbitrary unique identifier; each entry owns one rate policy on one security policy."
  type = map(object({
    config_key      = string
    policy_key      = string
    rate_policy_key = string
    ipv4_action     = string
    ipv6_action     = string
  }))

  validation {
    condition     = alltrue([for a in var.rate_policy_actions : contains(keys(var.configurations), a.config_key)])
    error_message = "every config_key must be one of the keys of var.configurations. Offending keys: ${join(", ", [for k, v in var.rate_policy_actions : k if !contains(keys(var.configurations), v.config_key)])}."
  }

  validation {
    condition     = alltrue([for a in var.rate_policy_actions : contains(keys(var.security_policies), a.policy_key)])
    error_message = "every policy_key must be one of the keys of var.security_policies. Offending keys: ${join(", ", [for k, v in var.rate_policy_actions : k if !contains(keys(var.security_policies), v.policy_key)])}."
  }

  validation {
    condition     = alltrue([for a in var.rate_policy_actions : contains(keys(var.rate_policies), a.rate_policy_key)])
    error_message = "every rate_policy_key must be one of the keys of var.rate_policies. Offending keys: ${join(", ", [for k, v in var.rate_policy_actions : k if !contains(keys(var.rate_policies), v.rate_policy_key)])}."
  }

  validation {
    condition     = alltrue([for a in var.rate_policy_actions : try(var.security_policies[a.policy_key].config_key == a.config_key, false)])
    error_message = "rate_policy_actions entries must reference a policy that belongs to the same configuration (the referenced policy's config_key must equal the entry's config_key). Offending keys: ${join(", ", [for k, v in var.rate_policy_actions : k if !try(var.security_policies[v.policy_key].config_key == v.config_key, false)])}."
  }

  validation {
    condition     = alltrue([for a in var.rate_policy_actions : try(var.rate_policies[a.rate_policy_key].config_key == a.config_key, false)])
    error_message = "rate_policy_actions entries must reference a rate policy that belongs to the same configuration (the referenced rate policy's config_key must equal the entry's config_key). Offending keys: ${join(", ", [for k, v in var.rate_policy_actions : k if !try(var.rate_policies[v.rate_policy_key].config_key == v.config_key, false)])}."
  }

  validation {
    condition = alltrue([for a in var.rate_policy_actions :
      can(regex("^(alert|delay|deny|monitor|none|slow|tarpit|deny_custom_[A-Za-z0-9_]+|cond_action_[A-Za-z0-9_]+|serve_alt_[A-Za-z0-9_]+|challenge_[A-Za-z0-9_]+)$", a.ipv4_action)) &&
    can(regex("^(alert|delay|deny|monitor|none|slow|tarpit|deny_custom_[A-Za-z0-9_]+|cond_action_[A-Za-z0-9_]+|serve_alt_[A-Za-z0-9_]+|challenge_[A-Za-z0-9_]+)$", a.ipv6_action))])
    error_message = "ipv4_action and ipv6_action must be one of alert, delay, deny, monitor, none, slow, tarpit, or a deny_custom_*, cond_action_*, serve_alt_*, challenge_* action (deliberately stricter than the provider validator: suffixes must be alphanumeric or underscore)."
  }

  validation {
    condition     = length(distinct([for a in var.rate_policy_actions : "${a.config_key}/${a.policy_key}/${a.rate_policy_key}"])) == length(var.rate_policy_actions)
    error_message = "each (config_key, policy_key, rate_policy_key) combination may appear at most once: the action resource owns one rate policy on one security policy. Multiple rate policies on the same policy are fine — use one entry per rate policy. Offending keys: ${join(", ", [for k, v in var.rate_policy_actions : k if length([for k2, v2 in var.rate_policy_actions : k2 if k2 != k && v2.config_key == v.config_key && v2.policy_key == v.policy_key && v2.rate_policy_key == v.rate_policy_key]) > 0])}."
  }
}

variable "slow_post_settings" {
  description = "Map of slow-POST protection settings keyed by an arbitrary unique identifier; one settings entry per (configuration, policy) — the resource replaces the policy's slow-POST settings."
  type = map(object({
    config_key                 = string
    policy_key                 = string
    slow_rate_action           = string
    slow_rate_threshold_rate   = optional(number)
    slow_rate_threshold_period = optional(number)
    duration_threshold_timeout = optional(number)
  }))

  validation {
    condition     = alltrue([for s in var.slow_post_settings : contains(keys(var.configurations), s.config_key)])
    error_message = "every config_key must be one of the keys of var.configurations. Offending keys: ${join(", ", [for k, v in var.slow_post_settings : k if !contains(keys(var.configurations), v.config_key)])}."
  }

  validation {
    condition     = alltrue([for s in var.slow_post_settings : contains(keys(var.security_policies), s.policy_key)])
    error_message = "every policy_key must be one of the keys of var.security_policies. Offending keys: ${join(", ", [for k, v in var.slow_post_settings : k if !contains(keys(var.security_policies), v.policy_key)])}."
  }

  validation {
    condition     = alltrue([for s in var.slow_post_settings : try(var.security_policies[s.policy_key].config_key == s.config_key, false)])
    error_message = "slow_post_settings entries must reference a policy that belongs to the same configuration (the referenced policy's config_key must equal the entry's config_key). Offending keys: ${join(", ", [for k, v in var.slow_post_settings : k if !try(var.security_policies[v.policy_key].config_key == v.config_key, false)])}."
  }

  validation {
    condition     = alltrue([for s in var.slow_post_settings : contains(["alert", "abort"], s.slow_rate_action)])
    error_message = "slow_rate_action must be one of alert, abort. Offending keys: ${join(", ", [for k, v in var.slow_post_settings : k if !contains(["alert", "abort"], v.slow_rate_action)])}."
  }

  validation {
    condition     = length(distinct([for s in var.slow_post_settings : "${s.config_key}/${s.policy_key}"])) == length(var.slow_post_settings)
    error_message = "each (config_key, policy_key) combination may appear at most once: the settings resource replaces the policy's whole slow-POST settings. Offending keys: ${join(", ", [for k, s in var.slow_post_settings : k if length([for k2, s2 in var.slow_post_settings : k2 if k2 != k && s2.config_key == s.config_key && s2.policy_key == s.policy_key]) > 0])}."
  }
}

variable "activations" {
  description = "Map of AppSec activations keyed by an arbitrary unique identifier. version = null activates the latest version observed by the in-module version data source (which waits for every mutation resource); an explicit version deploys exactly that version."
  type = map(object({
    config_key          = string
    network             = string
    note                = optional(string)
    notification_emails = list(string)
    version             = optional(number)
  }))

  validation {
    condition     = alltrue([for a in var.activations : contains(keys(var.configurations), a.config_key)])
    error_message = "every config_key must be one of the keys of var.configurations. Offending keys: ${join(", ", [for k, v in var.activations : k if !contains(keys(var.configurations), v.config_key)])}."
  }

  validation {
    condition     = alltrue([for a in var.activations : contains(["STAGING", "PRODUCTION"], a.network)])
    error_message = "network must be one of STAGING, PRODUCTION."
  }

  validation {
    condition     = alltrue([for a in var.activations : length(a.notification_emails) >= 1])
    error_message = "notification_emails must contain at least one email address."
  }

  validation {
    condition     = length(distinct([for a in var.activations : "${a.config_key}/${a.network}"])) == length(var.activations)
    error_message = "each (config_key, network) combination may appear at most once: two activation resources on the same deployed slot could carry different versions. Offending keys: ${join(", ", [for k, v in var.activations : k if length([for k2, v2 in var.activations : k2 if k2 != k && v2.config_key == v.config_key && v2.network == v.network]) > 0])}."
  }
}
