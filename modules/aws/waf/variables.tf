variable "ip_sets" {
  description = "Map of WAFv2 IP sets keyed by an arbitrary identifier."
  type = map(object({
    name               = string
    scope              = string
    ip_address_version = string
    addresses          = list(string)
    description        = optional(string)
    tags               = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.ip_sets : contains(["CLOUDFRONT", "REGIONAL"], s.scope)])
    error_message = "scope must be one of CLOUDFRONT or REGIONAL (case-sensitive). CLOUDFRONT-scope objects must be created in us-east-1 (provider-side)."
  }

  validation {
    condition     = alltrue([for s in var.ip_sets : contains(["IPV4", "IPV6"], s.ip_address_version)])
    error_message = "ip_address_version must be one of IPV4 or IPV6 (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.ip_sets : [
        for a in s.addresses : s.ip_address_version != "IPV4" || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", a))
      ]
    ]))
    error_message = "IPV4 ip_sets addresses must be IP addresses or IP/CIDR blocks in dotted-decimal form."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.ip_sets : [
        for a in s.addresses : s.ip_address_version != "IPV6" || can(regex("^[0-9A-Fa-f:]+(/[0-9]{1,3})?$", a))
      ]
    ]))
    error_message = "IPV6 ip_sets addresses must be IPv6 addresses or prefix/CIDR blocks in hex/colon form (light check; the provider validates the rest)."
  }

  validation {
    condition     = alltrue([for s in var.ip_sets : can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,127}$", s.name))])
    error_message = "name must be up to 128 characters starting with a letter/digit, containing alphanumerics, underscores and hyphens (WAFv2 naming rules)."
  }
}

variable "web_acls" {
  description = "Map of WAFv2 web ACLs keyed by an arbitrary identifier, each with its rules, an optional logging configuration, and (separately in var.associations) REGIONAL resource associations."
  type = map(object({
    name           = string
    scope          = string
    description    = optional(string)
    default_action = optional(string, "allow")
    visibility_config = object({
      cloudwatch_metrics_enabled = bool
      metric_name                = string
      sampled_requests_enabled   = bool
    })
    rules = optional(map(object({
      name            = string
      priority        = number
      action          = optional(string)
      override_action = optional(string)
      statement = object({
        ip_set_key = optional(string)
        ip_set_arn = optional(string)
        ip_set_forwarded_ip_config = optional(object({
          header_name       = string
          fallback_behavior = string
          position          = string
        }))
        rate_based = optional(object({
          limit                 = number
          aggregate_key_type    = optional(string)
          evaluation_window_sec = optional(number)
          forwarded_ip_config = optional(object({
            header_name       = string
            fallback_behavior = string
          }))
        }))
        managed_rule_group = optional(object({
          vendor_name = string
          name        = string
          version     = optional(string)
          rule_action_overrides = optional(list(object({
            name   = string
            action = string
          })))
        }))
        rule_group_key = optional(string)
        rule_group_arn = optional(string)
      })
      visibility_config = object({
        cloudwatch_metrics_enabled = bool
        metric_name                = string
        sampled_requests_enabled   = bool
      })
    })), {})
    logging = optional(object({
      log_destination_configs = list(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for a in var.web_acls : contains(["CLOUDFRONT", "REGIONAL"], a.scope)])
    error_message = "scope must be one of CLOUDFRONT or REGIONAL (case-sensitive). CLOUDFRONT-scope web ACLs must be created in us-east-1 (provider-side)."
  }

  validation {
    condition     = alltrue([for a in var.web_acls : contains(["allow", "block"], a.default_action)])
    error_message = "default_action must be one of allow or block (case-sensitive)."
  }

  validation {
    condition     = alltrue([for a in var.web_acls : can(regex("^[a-zA-Z0-9_]{1,128}$", a.visibility_config.metric_name))])
    error_message = "visibility_config.metric_name must be up to 128 characters of alphanumerics and underscores (CloudWatch metric naming rules)."
  }

  validation {
    condition     = alltrue([for a in var.web_acls : can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,127}$", a.name))])
    error_message = "name must be up to 128 characters starting with a letter/digit, containing alphanumerics, underscores and hyphens (WAFv2 naming rules)."
  }

  validation {
    condition = alltrue([
      for a in var.web_acls : alltrue([
        for r in a.rules : length([for v in [
          r.statement.ip_set_key != null || r.statement.ip_set_arn != null,
          r.statement.rate_based != null,
          r.statement.managed_rule_group != null,
          r.statement.rule_group_key != null || r.statement.rule_group_arn != null,
        ] : v if v]) == 1
      ])
    ])
    error_message = "rule statements must declare exactly one variant: (ip_set_key or ip_set_arn), rate_based, managed_rule_group or (rule_group_key or rule_group_arn)."
  }

  validation {
    condition = alltrue([
      for a in var.web_acls : alltrue([
        for r in a.rules : !(r.statement.ip_set_key != null && r.statement.ip_set_arn != null)
      ])
    ])
    error_message = "rule statements referencing an IP set must set exactly one of ip_set_key (of the module-managed ip_sets with the same scope) or ip_set_arn (external IP set)."
  }

  validation {
    condition = alltrue([
      for a in var.web_acls : alltrue([
        for r in a.rules : !(r.statement.rule_group_key != null && r.statement.rule_group_arn != null)
      ])
    ])
    error_message = "rule statements referencing a rule group must set exactly one of rule_group_key (of the module-managed rule_groups with the same scope) or rule_group_arn (external rule group)."
  }

  validation {
    condition = alltrue([
      for a in var.web_acls : alltrue([
        for r in a.rules : (r.action != null) != (r.override_action != null)
      ])
    ])
    error_message = "each rule must set exactly one of action (regular statements) or override_action (managed-rule-group / rule-group-reference statements only)."
  }

  validation {
    condition = alltrue([
      for a in var.web_acls : alltrue([
        for r in a.rules : r.action == null || contains(["allow", "block", "count", "captcha", "challenge"], r.action)
      ])
    ])
    error_message = "rules.action must be one of allow, block, count, captcha or challenge (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for a in var.web_acls : alltrue([
        for r in a.rules : r.override_action == null || contains(["none", "count"], r.override_action)
      ])
    ])
    error_message = "rules.override_action must be one of none (count as managed rules say) or count; it applies only to managed-rule-group / rule-group-reference statements."
  }

  validation {
    condition     = alltrue([for a in var.web_acls : length(a.rules) == length(distinct([for r in a.rules : r.priority]))])
    error_message = "rule priorities must be unique within each web ACL (AWS requires distinct priorities, 0+)."
  }

  validation {
    condition     = alltrue([for a in var.web_acls : length(concat([a.visibility_config.metric_name], [for r in a.rules : r.visibility_config.metric_name])) == length(distinct(concat([a.visibility_config.metric_name], [for r in a.rules : r.visibility_config.metric_name])))])
    error_message = "visibility_config.metric_name must be unique within each web ACL across the ACL-level and all rule-level metric names (they share a CloudWatch namespace)."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.web_acls : [
        for r in a.rules : r.statement.rate_based == null || r.statement.rate_based.limit > 0
      ]
    ]))
    error_message = "rate_based.limit must be positive (AWS applies its own per-API minimum, historically 100; the provider enforces the current floor at plan)."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.web_acls : [
        for r in a.rules : r.statement.rate_based == null || r.statement.rate_based.aggregate_key_type == null || contains(["IP", "FORWARDED_IP", "CONSTANT"], r.statement.rate_based.aggregate_key_type)
      ]
    ]))
    error_message = "rate_based.aggregate_key_type must be one of IP, FORWARDED_IP or CONSTANT (case-sensitive); CUSTOM_KEYS aggregate keys are out of scope."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.web_acls : [
        for r in a.rules : r.statement.rate_based == null || r.statement.rate_based.forwarded_ip_config == null || contains(["MATCH", "NO_MATCH"], r.statement.rate_based.forwarded_ip_config.fallback_behavior) && contains(["FIRST", "LAST", "ANY"], r.statement.rate_based.forwarded_ip_config.position)
      ]
    ]))
    error_message = "rate_based.forwarded_ip_config.fallback_behavior must be MATCH or NO_MATCH and position one of FIRST, LAST or ANY (case-sensitive); requires aggregate_key_type = \"FORWARDED_IP\" on the API side."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.web_acls : [
        for r in a.rules : r.statement.ip_set_forwarded_ip_config == null || (contains(["MATCH", "NO_MATCH"], r.statement.ip_set_forwarded_ip_config.fallback_behavior) && contains(["FIRST", "LAST", "ANY"], r.statement.ip_set_forwarded_ip_config.position))
      ]
    ]))
    error_message = "ip_set_forwarded_ip_config.fallback_behavior must be MATCH or NO_MATCH and position one of FIRST, LAST or ANY (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for a in var.web_acls : alltrue([
        for r in a.rules : r.statement.managed_rule_group == null || alltrue([
          for o in coalesce(r.statement.managed_rule_group.rule_action_overrides, []) : contains(["allow", "block", "count", "captcha", "challenge"], o.action)
        ])
      ])
    ])
    error_message = "managed_rule_group.rule_action_overrides.action must be one of allow, block, count, captcha or challenge (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for a in var.web_acls : a.logging == null || length(a.logging.log_destination_configs) > 0
    ])
    error_message = "logging.log_destination_configs must list at least one destination (CloudWatch log group, S3 bucket or Kinesis Firehose ARN)."
  }
}

variable "rule_groups" {
  description = "Map of WAFv2 rule groups keyed by an arbitrary identifier. `capacity` is a required consumer estimate — the WCU sum of the rules inside (decrease it if the apply fails with an insufficient-capacity error)."
  type = map(object({
    name        = string
    scope       = string
    capacity    = number
    description = optional(string)
    visibility_config = object({
      cloudwatch_metrics_enabled = bool
      metric_name                = string
      sampled_requests_enabled   = bool
    })
    rules = optional(map(object({
      name     = string
      priority = number
      action   = optional(string)
      statement = object({
        ip_set_key = optional(string)
        ip_set_arn = optional(string)
        ip_set_forwarded_ip_config = optional(object({
          header_name       = string
          fallback_behavior = string
          position          = string
        }))
        rate_based = optional(object({
          limit                 = number
          aggregate_key_type    = optional(string)
          evaluation_window_sec = optional(number)
          forwarded_ip_config = optional(object({
            header_name       = string
            fallback_behavior = string
          }))
        }))
      })
      visibility_config = object({
        cloudwatch_metrics_enabled = bool
        metric_name                = string
        sampled_requests_enabled   = bool
      })
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for g in var.rule_groups : contains(["CLOUDFRONT", "REGIONAL"], g.scope)])
    error_message = "scope must be one of CLOUDFRONT or REGIONAL (case-sensitive). CLOUDFRONT-scope objects must be created in us-east-1 (provider-side)."
  }

  validation {
    condition     = alltrue([for g in var.rule_groups : g.capacity >= 0 && g.capacity <= 2000])
    error_message = "capacity must be between 0 and 2000 (a rule group holds up to 2000 WCUs)."
  }

  validation {
    condition     = alltrue([for g in var.rule_groups : can(regex("^[a-zA-Z0-9_]{1,128}$", g.visibility_config.metric_name)) && can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,127}$", g.name))])
    error_message = "visibility_config.metric_name must be up to 128 characters of alphanumerics and underscores; name must be up to 128 characters starting with a letter/digit with alphanumerics, underscores and hyphens (WAFv2 naming rules)."
  }

  validation {
    condition     = alltrue([for g in var.rule_groups : length(g.rules) == length(distinct([for r in g.rules : r.priority]))])
    error_message = "rule priorities must be unique within each rule group (AWS requires distinct priorities, 0+)."
  }

  validation {
    condition     = alltrue([for g in var.rule_groups : length(concat([g.visibility_config.metric_name], [for r in g.rules : r.visibility_config.metric_name])) == length(distinct(concat([g.visibility_config.metric_name], [for r in g.rules : r.visibility_config.metric_name])))])
    error_message = "visibility_config.metric_name must be unique within each rule group across the group-level and all rule-level metric names (they share a CloudWatch namespace)."
  }

  validation {
    condition = alltrue([
      for g in var.rule_groups : alltrue([
        for r in g.rules : length([for v in [
          r.statement.ip_set_key != null || r.statement.ip_set_arn != null,
          r.statement.rate_based != null,
        ] : v if v]) == 1
      ])
    ])
    error_message = "rule group rule statements must declare exactly one variant: (ip_set_key or ip_set_arn) or rate_based (managed rule groups and rule-group references cannot nest inside rule groups)."
  }

  validation {
    condition = alltrue([
      for g in var.rule_groups : alltrue([
        for r in g.rules : !(r.statement.ip_set_key != null && r.statement.ip_set_arn != null)
      ])
    ])
    error_message = "rule statements referencing an IP set must set exactly one of ip_set_key (of the module-managed ip_sets with the same scope) or ip_set_arn (external IP set)."
  }

  validation {
    condition = alltrue([
      for g in var.rule_groups : alltrue([
        for r in g.rules : r.action != null
      ])
    ])
    error_message = "rule group rules require an action (allow, block, count, captcha or challenge; case-sensitive) — override_action only exists on web ACLs referencing a group."
  }

  validation {
    condition = alltrue([
      for g in var.rule_groups : alltrue([
        for r in g.rules : contains(["allow", "block", "count", "captcha", "challenge"], r.action)
      ])
    ])
    error_message = "rules.action must be one of allow, block, count, captcha or challenge (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.rule_groups : [
        for r in g.rules : r.statement.rate_based == null || r.statement.rate_based.limit > 0
      ]
    ]))
    error_message = "rate_based.limit must be positive (AWS applies its own per-API minimum, historically 100; the provider enforces the current floor at plan)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.rule_groups : [
        for r in g.rules : r.statement.rate_based == null || r.statement.rate_based.aggregate_key_type == null || contains(["IP", "FORWARDED_IP", "CONSTANT"], r.statement.rate_based.aggregate_key_type)
      ]
    ]))
    error_message = "rate_based.aggregate_key_type must be one of IP, FORWARDED_IP or CONSTANT (case-sensitive); CUSTOM_KEYS aggregate keys are out of scope."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.rule_groups : [
        for r in g.rules : r.statement.ip_set_forwarded_ip_config == null || (contains(["MATCH", "NO_MATCH"], r.statement.ip_set_forwarded_ip_config.fallback_behavior) && contains(["FIRST", "LAST", "ANY"], r.statement.ip_set_forwarded_ip_config.position))
      ]
    ]))
    error_message = "ip_set_forwarded_ip_config.fallback_behavior must be MATCH or NO_MATCH and position one of FIRST, LAST or ANY (case-sensitive)."
  }
}

variable "associations" {
  description = "Map of web ACL associations keyed by an arbitrary identifier, each pointing one REGIONAL web ACL (by key) at one resource ARN (ALB, API Gateway stage, App Runner, etc.)."
  type = map(object({
    web_acl_key  = string
    resource_arn = string
  }))
  default = {}
}
