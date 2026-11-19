terraform {
  required_version = ">= 1.9.0"

  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">= 12.0.0"
    }
  }
}

resource "akamai_appsec_configuration" "configuration" {
  for_each = var.configurations

  name        = each.value.name
  description = each.value.description
  contract_id = each.value.contract_id
  group_id    = each.value.group_id
  host_names  = each.value.host_names

  lifecycle {
    prevent_destroy = true
  }
}

resource "akamai_appsec_security_policy" "policy" {
  for_each = var.security_policies

  config_id                      = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  security_policy_name           = each.value.security_policy_name
  security_policy_prefix         = each.value.security_policy_prefix
  default_settings               = each.value.default_settings
  create_from_security_policy_id = each.value.create_from_security_policy_id
}

resource "akamai_appsec_waf_protection" "waf_protection" {
  for_each = { for k, v in var.security_policies : k => v if v.waf_protection_enabled != null }

  config_id          = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  security_policy_id = akamai_appsec_security_policy.policy[each.key].security_policy_id
  enabled            = each.value.waf_protection_enabled
}

resource "akamai_appsec_rate_protection" "rate_protection" {
  for_each = { for k, v in var.security_policies : k => v if v.rate_protection_enabled != null }

  config_id          = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  security_policy_id = akamai_appsec_security_policy.policy[each.key].security_policy_id
  enabled            = each.value.rate_protection_enabled
}

resource "akamai_appsec_slowpost_protection" "slowpost_protection" {
  for_each = { for k, v in var.security_policies : k => v if v.slowpost_protection_enabled != null }

  config_id          = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  security_policy_id = akamai_appsec_security_policy.policy[each.key].security_policy_id
  enabled            = each.value.slowpost_protection_enabled
}

resource "akamai_appsec_waf_ruleset" "waf_ruleset" {
  for_each = var.waf_rulesets

  config_id          = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  security_policy_id = akamai_appsec_security_policy.policy[each.value.policy_key].security_policy_id

  attack_groups = [
    for g in each.value.attack_groups : {
      attack_group        = g.attack_group
      attack_group_action = g.attack_group_action
      condition_exception = g.condition_exception
    }
  ]

  rules = [
    for u in each.value.rules : {
      rule_id             = u.rule_id
      rule_action         = u.rule_action
      condition_exception = u.condition_exception
    }
  ]
}

resource "akamai_appsec_match_target" "match_target" {
  for_each = var.match_targets

  config_id = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  match_target = jsonencode(merge(jsondecode(each.value.match_target), {
    securityPolicy = {
      policyId = akamai_appsec_security_policy.policy[each.value.policy_key].security_policy_id
    }
  }))

  lifecycle {
    precondition {
      condition     = can(keys(jsondecode(each.value.match_target)))
      error_message = "match_target must decode to a JSON object (got a non-object or invalid JSON)."
    }

    precondition {
      condition     = try(!contains(keys(jsondecode(each.value.match_target)), "securityPolicy"), true)
      error_message = "match_target must not contain a securityPolicy member: the module injects it from policy_key."
    }
  }
}

resource "akamai_appsec_rate_policy" "rate_policy" {
  for_each = var.rate_policies

  config_id   = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  rate_policy = each.value.rate_policy
}

resource "akamai_appsec_rate_policy_action" "rate_policy_action" {
  for_each = var.rate_policy_actions

  config_id          = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  security_policy_id = akamai_appsec_security_policy.policy[each.value.policy_key].security_policy_id
  rate_policy_id     = akamai_appsec_rate_policy.rate_policy[each.value.rate_policy_key].rate_policy_id
  ipv4_action        = each.value.ipv4_action
  ipv6_action        = each.value.ipv6_action
}

resource "akamai_appsec_slow_post" "slow_post" {
  for_each = var.slow_post_settings

  config_id                  = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  security_policy_id         = akamai_appsec_security_policy.policy[each.value.policy_key].security_policy_id
  slow_rate_action           = each.value.slow_rate_action
  slow_rate_threshold_rate   = each.value.slow_rate_threshold_rate
  slow_rate_threshold_period = each.value.slow_rate_threshold_period
  duration_threshold_timeout = each.value.duration_threshold_timeout
}

data "akamai_appsec_configuration" "by_name" {
  for_each = var.configurations

  name = akamai_appsec_configuration.configuration[each.key].name

  depends_on = [
    akamai_appsec_security_policy.policy,
    akamai_appsec_waf_protection.waf_protection,
    akamai_appsec_rate_protection.rate_protection,
    akamai_appsec_slowpost_protection.slowpost_protection,
    akamai_appsec_waf_ruleset.waf_ruleset,
    akamai_appsec_match_target.match_target,
    akamai_appsec_rate_policy.rate_policy,
    akamai_appsec_rate_policy_action.rate_policy_action,
    akamai_appsec_slow_post.slow_post,
  ]
}

resource "akamai_appsec_activations" "activation" {
  for_each = var.activations

  config_id           = akamai_appsec_configuration.configuration[each.value.config_key].config_id
  version             = each.value.version != null ? each.value.version : data.akamai_appsec_configuration.by_name[each.value.config_key].latest_version
  network             = each.value.network
  note                = each.value.note
  notification_emails = each.value.notification_emails
}
