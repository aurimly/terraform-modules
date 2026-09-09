resource "google_compute_security_policy" "policy" {
  for_each = var.security_policies

  name            = each.value.name
  project         = each.value.project_id
  description     = each.value.description
  type            = each.value.type
  deletion_policy = each.value.deletion_policy
  labels          = each.value.labels

  dynamic "advanced_options_config" {
    for_each = each.value.advanced_options_config != null ? [each.value.advanced_options_config] : []

    content {
      json_parsing                 = advanced_options_config.value.json_parsing
      log_level                    = advanced_options_config.value.log_level
      user_ip_request_headers      = advanced_options_config.value.user_ip_request_headers
      request_body_inspection_size = advanced_options_config.value.request_body_inspection_size

      dynamic "json_custom_config" {
        for_each = advanced_options_config.value.json_custom_config != null ? [advanced_options_config.value.json_custom_config] : []

        content {
          content_types = json_custom_config.value.content_types
        }
      }
    }
  }

  dynamic "adaptive_protection_config" {
    for_each = each.value.adaptive_protection_config != null ? [each.value.adaptive_protection_config] : []

    content {
      dynamic "layer_7_ddos_defense_config" {
        for_each = adaptive_protection_config.value.layer_7_ddos_defense_config != null ? [adaptive_protection_config.value.layer_7_ddos_defense_config] : []

        content {
          enable          = layer_7_ddos_defense_config.value.enable
          rule_visibility = layer_7_ddos_defense_config.value.rule_visibility
        }
      }
    }
  }

  dynamic "recaptcha_options_config" {
    for_each = each.value.recaptcha_options_config != null ? [each.value.recaptcha_options_config] : []

    content {
      redirect_site_key = recaptcha_options_config.value.redirect_site_key
    }
  }

  dynamic "rule" {
    for_each = each.value.rules

    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      preview     = rule.value.preview

      dynamic "match" {
        for_each = [rule.value.match]

        content {
          versioned_expr = match.value.versioned_expr

          dynamic "config" {
            for_each = match.value.config != null ? [match.value.config] : []

            content {
              src_ip_ranges = config.value.src_ip_ranges
            }
          }

          dynamic "expr" {
            for_each = match.value.expr != null ? [match.value.expr] : []

            content {
              expression = expr.value.expression
            }
          }
        }
      }

      dynamic "header_action" {
        for_each = rule.value.header_action != null ? [rule.value.header_action] : []

        content {
          dynamic "request_headers_to_adds" {
            for_each = header_action.value.request_headers_to_adds

            content {
              header_name  = request_headers_to_adds.value.header_name
              header_value = request_headers_to_adds.value.header_value
            }
          }
        }
      }

      dynamic "rate_limit_options" {
        for_each = rule.value.rate_limit_options != null ? [rule.value.rate_limit_options] : []

        content {
          conform_action      = rate_limit_options.value.conform_action
          exceed_action       = rate_limit_options.value.exceed_action
          enforce_on_key      = rate_limit_options.value.enforce_on_key
          enforce_on_key_name = rate_limit_options.value.enforce_on_key_name
          ban_duration_sec    = rate_limit_options.value.ban_duration_sec

          dynamic "enforce_on_key_configs" {
            for_each = rate_limit_options.value.enforce_on_key_configs != null ? rate_limit_options.value.enforce_on_key_configs : []

            content {
              enforce_on_key_type = enforce_on_key_configs.value.enforce_on_key_type
              enforce_on_key_name = enforce_on_key_configs.value.enforce_on_key_name
            }
          }

          dynamic "rate_limit_threshold" {
            for_each = rate_limit_options.value.rate_limit_threshold != null ? [rate_limit_options.value.rate_limit_threshold] : []

            content {
              count        = rate_limit_threshold.value.count
              interval_sec = rate_limit_threshold.value.interval_sec
            }
          }

          dynamic "ban_threshold" {
            for_each = rate_limit_options.value.ban_threshold != null ? [rate_limit_options.value.ban_threshold] : []

            content {
              count        = ban_threshold.value.count
              interval_sec = ban_threshold.value.interval_sec
            }
          }

          dynamic "exceed_redirect_options" {
            for_each = rate_limit_options.value.exceed_redirect_options != null ? [rate_limit_options.value.exceed_redirect_options] : []

            content {
              type   = exceed_redirect_options.value.type
              target = exceed_redirect_options.value.target
            }
          }
        }
      }

      dynamic "redirect_options" {
        for_each = rule.value.redirect_options != null ? [rule.value.redirect_options] : []

        content {
          type   = redirect_options.value.type
          target = redirect_options.value.target
        }
      }

      dynamic "preconfigured_waf_config" {
        for_each = rule.value.preconfigured_waf_config != null ? [rule.value.preconfigured_waf_config] : []

        content {
          dynamic "exclusion" {
            for_each = preconfigured_waf_config.value.exclusions

            content {
              target_rule_set = exclusion.value.target_rule_set
              target_rule_ids = exclusion.value.target_rule_ids

              dynamic "request_header" {
                for_each = exclusion.value.request_header

                content {
                  operator = request_header.value.operator
                  value    = request_header.value.value
                }
              }

              dynamic "request_cookie" {
                for_each = exclusion.value.request_cookie

                content {
                  operator = request_cookie.value.operator
                  value    = request_cookie.value.value
                }
              }

              dynamic "request_uri" {
                for_each = exclusion.value.request_uri

                content {
                  operator = request_uri.value.operator
                  value    = request_uri.value.value
                }
              }

              dynamic "request_query_param" {
                for_each = exclusion.value.request_query_param

                content {
                  operator = request_query_param.value.operator
                  value    = request_query_param.value.value
                }
              }
            }
          }
        }
      }
    }
  }
}
