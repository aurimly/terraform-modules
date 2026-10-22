resource "aws_wafv2_ip_set" "ip_set" {
  for_each = var.ip_sets

  name               = each.value.name
  scope              = each.value.scope
  ip_address_version = each.value.ip_address_version
  addresses          = each.value.addresses
  description        = each.value.description

  tags = merge(each.value.tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition     = length(each.value.addresses) > 0
      error_message = "ip_set \"${each.key}\" requires at least one address."
    }
  }
}

resource "aws_wafv2_web_acl" "web_acl" {
  for_each = var.web_acls

  name        = each.value.name
  scope       = each.value.scope
  description = each.value.description

  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      dynamic "allow" {
        for_each = default_action.value == "allow" ? [1] : []
        content {}
      }

      dynamic "block" {
        for_each = default_action.value == "block" ? [1] : []
        content {}
      }
    }
  }

  dynamic "visibility_config" {
    for_each = [each.value.visibility_config]
    content {
      cloudwatch_metrics_enabled = visibility_config.value.cloudwatch_metrics_enabled
      metric_name                = visibility_config.value.metric_name
      sampled_requests_enabled   = visibility_config.value.sampled_requests_enabled
    }
  }

  dynamic "rule" {
    for_each = each.value.rules

    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = rule.value.action != null ? [rule.value.action] : []
        content {
          dynamic "allow" {
            for_each = action.value == "allow" ? [1] : []
            content {}
          }
          dynamic "block" {
            for_each = action.value == "block" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = action.value == "count" ? [1] : []
            content {}
          }
          dynamic "captcha" {
            for_each = action.value == "captcha" ? [1] : []
            content {}
          }
          dynamic "challenge" {
            for_each = action.value == "challenge" ? [1] : []
            content {}
          }
        }
      }

      dynamic "override_action" {
        for_each = rule.value.override_action != null ? [rule.value.override_action] : []
        content {
          dynamic "none" {
            for_each = override_action.value == "none" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = override_action.value == "count" ? [1] : []
            content {}
          }
        }
      }

      statement {
        dynamic "ip_set_reference_statement" {
          for_each = each.value.statement.ip_set_key != null || each.value.statement.ip_set_arn != null ? [1] : []
          content {
            arn = each.value.statement.ip_set_key != null ? aws_wafv2_ip_set.ip_set[each.value.statement.ip_set_key].arn : each.value.statement.ip_set_arn

            dynamic "ip_set_forwarded_ip_config" {
              for_each = each.value.statement.ip_set_forwarded_ip_config != null ? [each.value.statement.ip_set_forwarded_ip_config] : []
              content {
                header_name       = ip_set_forwarded_ip_config.value.header_name
                fallback_behavior = ip_set_forwarded_ip_config.value.fallback_behavior
                position          = ip_set_forwarded_ip_config.value.position
              }
            }
          }
        }

        dynamic "rate_based_statement" {
          for_each = each.value.statement.rate_based != null ? [each.value.statement.rate_based] : []
          content {
            limit                 = rate_based_statement.value.limit
            aggregate_key_type    = rate_based_statement.value.aggregate_key_type
            evaluation_window_sec = rate_based_statement.value.evaluation_window_sec

            dynamic "forwarded_ip_config" {
              for_each = rate_based_statement.value.forwarded_ip_config != null ? [rate_based_statement.value.forwarded_ip_config] : []
              content {
                header_name       = forwarded_ip_config.value.header_name
                fallback_behavior = forwarded_ip_config.value.fallback_behavior
              }
            }
          }
        }

        dynamic "managed_rule_group_statement" {
          for_each = each.value.statement.managed_rule_group != null ? [each.value.statement.managed_rule_group] : []
          content {
            vendor_name = managed_rule_group_statement.value.vendor_name
            name        = managed_rule_group_statement.value.name
            version     = managed_rule_group_statement.value.version

            dynamic "rule_action_override" {
              for_each = managed_rule_group_statement.value.rule_action_overrides != null ? managed_rule_group_statement.value.rule_action_overrides : []
              content {
                name = rule_action_override.value.name

                dynamic "action_to_use" {
                  for_each = [rule_action_override.value.action]
                  content {
                    dynamic "allow" {
                      for_each = rule_action_override.value.action == "allow" ? [1] : []
                      content {}
                    }
                    dynamic "block" {
                      for_each = rule_action_override.value.action == "block" ? [1] : []
                      content {}
                    }
                    dynamic "count" {
                      for_each = rule_action_override.value.action == "count" ? [1] : []
                      content {}
                    }
                    dynamic "captcha" {
                      for_each = rule_action_override.value.action == "captcha" ? [1] : []
                      content {}
                    }
                    dynamic "challenge" {
                      for_each = rule_action_override.value.action == "challenge" ? [1] : []
                      content {}
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "rule_group_reference_statement" {
          for_each = each.value.statement.rule_group_key != null || each.value.statement.rule_group_arn != null ? [1] : []
          content {
            arn = each.value.statement.rule_group_key != null ? aws_wafv2_rule_group.rule_group[each.value.statement.rule_group_key].arn : each.value.statement.rule_group_arn
          }
        }
      }

      dynamic "visibility_config" {
        for_each = [rule.value.visibility_config]
        content {
          cloudwatch_metrics_enabled = visibility_config.value.cloudwatch_metrics_enabled
          metric_name                = visibility_config.value.metric_name
          sampled_requests_enabled   = visibility_config.value.sampled_requests_enabled
        }
      }
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition = alltrue([
        for rk, r in each.value.rules :
        r.statement.ip_set_key == null || var.ip_sets[r.statement.ip_set_key].scope == each.value.scope
      ])
      error_message = "web_acl \"${each.key}\": every rule rule-sourced ip_set_key must reference an ip_sets entry of the same scope as the ACL."
    }

    precondition {
      condition = alltrue([
        for rk, r in each.value.rules :
        r.statement.rule_group_key == null || var.rule_groups[r.statement.rule_group_key].scope == each.value.scope
      ])
      error_message = "web_acl \"${each.key}\": every rule-sourced rule_group_key must reference a rule_groups entry of the same scope as the ACL (AWS does not mix scopes)."
    }
  }
}

resource "aws_wafv2_rule_group" "rule_group" {
  for_each = var.rule_groups

  name        = each.value.name
  scope       = each.value.scope
  description = each.value.description
  capacity    = each.value.capacity

  dynamic "visibility_config" {
    for_each = [each.value.visibility_config]
    content {
      cloudwatch_metrics_enabled = visibility_config.value.cloudwatch_metrics_enabled
      metric_name                = visibility_config.value.metric_name
      sampled_requests_enabled   = visibility_config.value.sampled_requests_enabled
    }
  }

  dynamic "rule" {
    for_each = each.value.rules

    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = rule.value.action != null ? [rule.value.action] : []
        content {
          dynamic "allow" {
            for_each = action.value == "allow" ? [1] : []
            content {}
          }
          dynamic "block" {
            for_each = action.value == "block" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = action.value == "count" ? [1] : []
            content {}
          }
          dynamic "captcha" {
            for_each = action.value == "captcha" ? [1] : []
            content {}
          }
          dynamic "challenge" {
            for_each = action.value == "challenge" ? [1] : []
            content {}
          }
        }
      }

      statement {
        dynamic "ip_set_reference_statement" {
          for_each = each.value.statement.ip_set_key != null || each.value.statement.ip_set_arn != null ? [1] : []
          content {
            arn = each.value.statement.ip_set_key != null ? aws_wafv2_ip_set.ip_set[each.value.statement.ip_set_key].arn : each.value.statement.ip_set_arn

            dynamic "ip_set_forwarded_ip_config" {
              for_each = each.value.statement.ip_set_forwarded_ip_config != null ? [each.value.statement.ip_set_forwarded_ip_config] : []
              content {
                header_name       = ip_set_forwarded_ip_config.value.header_name
                fallback_behavior = ip_set_forwarded_ip_config.value.fallback_behavior
                position          = ip_set_forwarded_ip_config.value.position
              }
            }
          }
        }

        dynamic "rate_based_statement" {
          for_each = each.value.statement.rate_based != null ? [each.value.statement.rate_based] : []
          content {
            limit                 = rate_based_statement.value.limit
            aggregate_key_type    = rate_based_statement.value.aggregate_key_type
            evaluation_window_sec = rate_based_statement.value.evaluation_window_sec

            dynamic "forwarded_ip_config" {
              for_each = rate_based_statement.value.forwarded_ip_config != null ? [rate_based_statement.value.forwarded_ip_config] : []
              content {
                header_name       = forwarded_ip_config.value.header_name
                fallback_behavior = forwarded_ip_config.value.fallback_behavior
              }
            }
          }
        }
      }

      dynamic "visibility_config" {
        for_each = [rule.value.visibility_config]
        content {
          cloudwatch_metrics_enabled = visibility_config.value.cloudwatch_metrics_enabled
          metric_name                = visibility_config.value.metric_name
          sampled_requests_enabled   = visibility_config.value.sampled_requests_enabled
        }
      }
    }
  }

  tags = merge(each.value.tags, { Name = each.value.name })
}

resource "aws_wafv2_web_acl_association" "association" {
  for_each = var.associations

  web_acl_arn  = aws_wafv2_web_acl.web_acl[each.value.web_acl_key].arn
  resource_arn = each.value.resource_arn

  lifecycle {
    precondition {
      condition     = var.web_acls[each.value.web_acl_key].scope == "REGIONAL"
      error_message = "association \"${each.key}\": only REGIONAL web ACLs can be associated to a resource (CloudFront distributions take a CLOUDFRONT-scope ACL through the distribution's web_acl_id instead — see modules/aws/cloudfront)."
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "logging" {
  for_each = { for k, a in var.web_acls : k => a if a.logging != null }

  resource_arn            = aws_wafv2_web_acl.web_acl[each.key].arn
  log_destination_configs = each.value.logging.log_destination_configs
}
