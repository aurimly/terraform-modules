variable "security_policies" {
  description = "Map of Cloud Armor security policies keyed by an arbitrary identifier. Each entry creates one google_compute_security_policy with its rules."
  type = map(object({
    name            = string
    project_id      = optional(string)
    description     = optional(string)
    type            = optional(string)
    deletion_policy = optional(string)
    labels          = optional(map(string), {})
    advanced_options_config = optional(object({
      json_parsing                 = optional(string)
      log_level                    = optional(string)
      user_ip_request_headers      = optional(list(string))
      request_body_inspection_size = optional(string)
      json_custom_config = optional(object({
        content_types = list(string)
      }))
    }))
    adaptive_protection_config = optional(object({
      layer_7_ddos_defense_config = optional(object({
        enable          = optional(bool)
        rule_visibility = optional(string)
      }))
    }))
    recaptcha_options_config = optional(object({
      redirect_site_key = string
    }))
    rules = optional(list(object({
      action      = string
      priority    = number
      description = optional(string)
      preview     = optional(bool)
      match = object({
        versioned_expr = optional(string)
        config = optional(object({
          src_ip_ranges = list(string)
        }))
        expr = optional(object({
          expression = string
        }))
      })
      header_action = optional(object({
        request_headers_to_adds = optional(list(object({
          header_name  = string
          header_value = optional(string)
        })), [])
      }))
      rate_limit_options = optional(object({
        conform_action      = optional(string)
        exceed_action       = optional(string)
        enforce_on_key      = optional(string)
        enforce_on_key_name = optional(string)
        ban_duration_sec    = optional(number)
        enforce_on_key_configs = optional(list(object({
          enforce_on_key_type = string
          enforce_on_key_name = optional(string)
        })))
        rate_limit_threshold = optional(object({
          count        = number
          interval_sec = number
        }))
        ban_threshold = optional(object({
          count        = number
          interval_sec = number
        }))
        exceed_redirect_options = optional(object({
          type   = optional(string)
          target = optional(string)
        }))
      }))
      redirect_options = optional(object({
        type   = optional(string)
        target = optional(string)
      }))
      preconfigured_waf_config = optional(object({
        exclusions = optional(list(object({
          target_rule_set     = string
          target_rule_ids     = optional(list(string))
          request_header      = optional(list(object({ operator = string, value = optional(string) })), [])
          request_cookie      = optional(list(object({ operator = string, value = optional(string) })), [])
          request_uri         = optional(list(object({ operator = string, value = optional(string) })), [])
          request_query_param = optional(list(object({ operator = string, value = optional(string) })), [])
        })), [])
      }))
    })), [])
  }))

  validation {
    condition     = alltrue([for k, p in var.security_policies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.type == null || contains(["CLOUD_ARMOR", "CLOUD_ARMOR_EDGE", "CLOUD_ARMOR_INTERNAL_SERVICE"], p.type)])
    error_message = "type must be one of CLOUD_ARMOR, CLOUD_ARMOR_EDGE or CLOUD_ARMOR_INTERNAL_SERVICE (case-sensitive; defaults to CLOUD_ARMOR)."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], p.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : length(distinct([for r in p.rules : r.priority])) == length(p.rules)])
    error_message = "rules.priority must be unique within each security policy."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.priority >= 0 && r.priority <= 2147483647])])
    error_message = "rules.priority must be between 0 and 2147483647; priority 2147483647 is the default rule."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : can(regex("^(allow|deny\\((403|404|502)\\)|redirect|throttle|rate_based_ban)$", r.action))])])
    error_message = "rules.action must be allow, deny(403), deny(404), deny(502), redirect, throttle or rate_based_ban (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : (r.match.versioned_expr == null) != (r.match.expr == null)])])
    error_message = "rules.match requires exactly one of versioned_expr (with config) or expr."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.match.versioned_expr == null || (r.match.versioned_expr == "SRC_IPS_V1" && r.match.config != null && length(r.match.config.src_ip_ranges) > 0)])])
    error_message = "rules.match.versioned_expr must be SRC_IPS_V1 and requires a non-empty match.config.src_ip_ranges."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.match.expr == null || length(r.match.expr.expression) > 0])])
    error_message = "rules.match.expr.expression must be a non-empty CEL expression (e.g. evaluatePreconfiguredExpr('sqli-v33-stable'))."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : !can(regex("^(throttle|rate_based_ban)$", r.action)) || r.rate_limit_options != null])])
    error_message = "rules.action throttle or rate_based_ban requires rate_limit_options to be set."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.rate_limit_options == null || (r.rate_limit_options.conform_action != null && r.rate_limit_options.exceed_action != null && r.rate_limit_options.rate_limit_threshold != null)])])
    error_message = "rules.rate_limit_options requires conform_action, exceed_action and rate_limit_threshold to be set."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.rate_limit_options == null || r.rate_limit_options.conform_action == "allow"])])
    error_message = "rules.rate_limit_options.conform_action must be allow (the only accepted value)."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.rate_limit_options == null || r.rate_limit_options.exceed_action == null || can(regex("^(deny\\((403|404|429|502)\\)|redirect)$", r.rate_limit_options.exceed_action))])])
    error_message = "rules.rate_limit_options.exceed_action must be deny(403), deny(404), deny(429), deny(502) or redirect."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.rate_limit_options == null || r.rate_limit_options.enforce_on_key_configs == null || r.rate_limit_options.enforce_on_key == null || r.rate_limit_options.enforce_on_key == ""])])
    error_message = "rules.rate_limit_options.enforce_on_key must be empty (or unset) when enforce_on_key_configs is set."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.redirect_options == null || (contains(["GOOGLE_RECAPTCHA", "EXTERNAL_302"], r.redirect_options.type) && (r.redirect_options.type == "EXTERNAL_302" ? r.redirect_options.target != null : r.redirect_options.target == null))])])
    error_message = "rules.redirect_options.type must be GOOGLE_RECAPTCHA or EXTERNAL_302; target is required for EXTERNAL_302 and must not be set for GOOGLE_RECAPTCHA."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.rate_limit_options == null || r.rate_limit_options.exceed_redirect_options == null || (contains(["GOOGLE_RECAPTCHA", "EXTERNAL_302"], r.rate_limit_options.exceed_redirect_options.type) && (r.rate_limit_options.exceed_redirect_options.type == "EXTERNAL_302" ? r.rate_limit_options.exceed_redirect_options.target != null : r.rate_limit_options.exceed_redirect_options.target == null))])])
    error_message = "rules.rate_limit_options.exceed_redirect_options.type must be GOOGLE_RECAPTCHA or EXTERNAL_302; target is required for EXTERNAL_302 and must not be set for GOOGLE_RECAPTCHA."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.advanced_options_config == null || (p.advanced_options_config.json_parsing == null || contains(["STANDARD", "DISABLED", "STANDARD_WITH_GRAPHQL"], p.advanced_options_config.json_parsing))])
    error_message = "advanced_options_config.json_parsing must be one of STANDARD, DISABLED or STANDARD_WITH_GRAPHQL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.advanced_options_config == null || (p.advanced_options_config.log_level == null || contains(["NORMAL", "VERBOSE"], p.advanced_options_config.log_level))])
    error_message = "advanced_options_config.log_level must be NORMAL or VERBOSE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.advanced_options_config == null || p.advanced_options_config.json_custom_config == null || p.advanced_options_config.json_parsing == "STANDARD"])
    error_message = "advanced_options_config.json_custom_config can only be set when json_parsing is STANDARD."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.advanced_options_config == null || p.advanced_options_config.json_custom_config == null || length(p.advanced_options_config.json_custom_config.content_types) > 0])
    error_message = "advanced_options_config.json_custom_config.content_types must contain at least one entry."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.advanced_options_config == null || p.advanced_options_config.request_body_inspection_size == null || can(regex("^[0-9]+KB$", p.advanced_options_config.request_body_inspection_size))])
    error_message = "advanced_options_config.request_body_inspection_size must be a KB-suffixed string (e.g. 16KB, range 8KB-64KB)."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : p.adaptive_protection_config == null || p.adaptive_protection_config.layer_7_ddos_defense_config == null || p.adaptive_protection_config.layer_7_ddos_defense_config.rule_visibility == null || contains(["STANDARD", "PREMIUM"], p.adaptive_protection_config.layer_7_ddos_defense_config.rule_visibility)])
    error_message = "adaptive_protection_config.layer_7_ddos_defense_config.rule_visibility must be STANDARD or PREMIUM (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.security_policies : alltrue([for r in p.rules : r.preconfigured_waf_config == null || alltrue([for x in r.preconfigured_waf_config.exclusions : alltrue([for f in concat(x.request_header, x.request_cookie, x.request_uri, x.request_query_param) : can(regex("^[A-Z][A-Z_]*$", f.operator))])])])])
    error_message = "preconfigured_waf_config exclusion operator must be an uppercase identifier (e.g. CONTAINS, STARTS_WITH, EQUALS)."
  }
}
