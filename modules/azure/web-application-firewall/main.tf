locals {
  custom_rules_by_priority = { for policy_key, policy in var.policies : policy_key => {
    for rule_key, rule in policy.custom_rules : format("%06d.%s", rule.priority, rule_key) => rule
  } }

  custom_rules = { for policy_key, rules in local.custom_rules_by_priority : policy_key => [
    for rule_key in sort(keys(rules)) : rules[rule_key]
  ] }
}

resource "azurerm_web_application_firewall_policy" "policy" {
  for_each = var.policies

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  dynamic "custom_rules" {
    for_each = local.custom_rules[each.key]

    content {
      name      = custom_rules.value.name
      priority  = custom_rules.value.priority
      rule_type = custom_rules.value.rule_type
      action    = custom_rules.value.action
      enabled   = custom_rules.value.enabled

      rate_limit_duration  = custom_rules.value.rate_limit_duration
      rate_limit_threshold = custom_rules.value.rate_limit_threshold
      group_rate_limit_by  = custom_rules.value.group_rate_limit_by

      dynamic "match_conditions" {
        for_each = custom_rules.value.match_conditions

        content {
          operator           = match_conditions.value.operator
          match_values       = match_conditions.value.match_values
          negation_condition = match_conditions.value.negation_condition
          transforms         = match_conditions.value.transforms

          dynamic "match_variables" {
            for_each = match_conditions.value.match_variables

            content {
              variable_name = match_variables.value.variable_name
              selector      = match_variables.value.selector
            }
          }
        }
      }
    }
  }

  dynamic "policy_settings" {
    for_each = each.value.policy_settings != null ? [each.value.policy_settings] : []

    content {
      enabled                                   = policy_settings.value.enabled
      mode                                      = policy_settings.value.mode
      request_body_check                        = policy_settings.value.request_body_check
      max_request_body_size_in_kb               = policy_settings.value.max_request_body_size_in_kb
      file_upload_limit_in_mb                   = policy_settings.value.file_upload_limit_in_mb
      file_upload_enforcement                   = policy_settings.value.file_upload_enforcement
      request_body_enforcement                  = policy_settings.value.request_body_enforcement
      request_body_inspect_limit_in_kb          = policy_settings.value.request_body_inspect_limit_in_kb
      js_challenge_cookie_expiration_in_minutes = policy_settings.value.js_challenge_cookie_expiration_in_minutes

      dynamic "log_scrubbing" {
        for_each = policy_settings.value.log_scrubbing != null ? [policy_settings.value.log_scrubbing] : []

        content {
          enabled = log_scrubbing.value.enabled

          dynamic "rule" {
            for_each = log_scrubbing.value.rules

            content {
              match_variable          = rule.value.match_variable
              selector                = rule.value.selector
              selector_match_operator = rule.value.selector_match_operator
              enabled                 = rule.value.enabled
            }
          }
        }
      }
    }
  }

  dynamic "managed_rules" {
    for_each = [1]

    content {
      dynamic "exclusion" {
        for_each = each.value.exclusions

        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator

          dynamic "excluded_rule_set" {
            for_each = exclusion.value.excluded_rule_set != null ? [exclusion.value.excluded_rule_set] : []

            content {
              type    = excluded_rule_set.value.type
              version = excluded_rule_set.value.version

              dynamic "rule_group" {
                for_each = excluded_rule_set.value.rule_groups

                content {
                  rule_group_name = rule_group.value.rule_group_name
                  excluded_rules  = rule_group.value.excluded_rules
                }
              }
            }
          }
        }
      }

      dynamic "managed_rule_set" {
        for_each = each.value.managed_rule_sets

        content {
          type    = managed_rule_set.value.type
          version = managed_rule_set.value.version

          dynamic "rule_group_override" {
            for_each = managed_rule_set.value.rule_group_overrides

            content {
              rule_group_name = rule_group_override.value.rule_group_name

              dynamic "rule" {
                for_each = rule_group_override.value.rules

                content {
                  id      = rule.value.id
                  enabled = rule.value.enabled
                  action  = rule.value.action
                }
              }
            }
          }
        }
      }
    }
  }

  tags = each.value.tags
}
