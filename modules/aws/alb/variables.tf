variable "load_balancers" {
  description = "Map of load balancers keyed by an arbitrary identifier. Each entry creates one aws_lb plus its target groups, listeners, rules and attachments."
  type = map(object({
    name                                        = optional(string)
    name_prefix                                 = optional(string)
    internal                                    = optional(bool, false)
    load_balancer_type                          = optional(string, "application")
    security_group_ids                          = optional(list(string), [])
    subnet_ids                                  = optional(list(string), [])
    ip_address_type                             = optional(string)
    customer_owned_ipv4_pool                    = optional(string)
    desync_mitigation_mode                      = optional(string)
    dns_record_client_routing_policy            = optional(string)
    drop_invalid_header_fields                  = optional(bool)
    deletion_protection                         = optional(bool, false)
    enable_http2                                = optional(bool)
    enable_tls_version_and_cipher_suite_headers = optional(bool)
    enable_xff_client_port                      = optional(bool)
    enable_waf_fail_open                        = optional(bool)
    idle_timeout                                = optional(number)
    preserve_host_header                        = optional(bool)
    xff_header_processing_mode                  = optional(string)
    access_logs = optional(object({
      bucket = string
      prefix = optional(string)
    }))
    target_groups = optional(map(object({
      vpc_id                            = string
      name                              = optional(string)
      name_prefix                       = optional(string)
      port                              = optional(number)
      protocol                          = optional(string)
      target_type                       = optional(string, "instance")
      deregistration_delay              = optional(number)
      load_balancing_algorithm_type     = optional(string)
      load_balancing_cross_zone_enabled = optional(bool)
      load_balancing_anomaly_mitigation = optional(string)
      slow_start                        = optional(number)
      connection_termination            = optional(bool)
      protocol_version                  = optional(string)
      preserve_client_ip                = optional(bool)
      proxy_protocol_v2                 = optional(bool)
      ip_address_type                   = optional(string)
      health_check = optional(object({
        enabled             = optional(bool)
        healthy_threshold   = optional(number)
        interval            = optional(number)
        matcher             = optional(string)
        path                = optional(string)
        port                = optional(string)
        protocol            = optional(string)
        timeout             = optional(number)
        unhealthy_threshold = optional(number)
      }))
      stickiness = optional(object({
        enabled         = optional(bool)
        type            = string
        cookie_duration = optional(number)
        cookie_name     = optional(string)
      }))
      attachments = optional(map(object({
        target_id         = string
        port              = optional(number)
        availability_zone = optional(string)
      })), {})
      tags = optional(map(string), {})
    })), {})
    listeners = optional(map(object({
      port                     = number
      protocol                 = string
      ssl_policy               = optional(string)
      certificate_arn          = optional(string)
      alpn_policy              = optional(string)
      tcp_idle_timeout_seconds = optional(number)
      default_action = object({
        type             = string
        order            = optional(number)
        target_group_arn = optional(string)
        target_group_key = optional(string)
        redirect = optional(object({
          host        = optional(string)
          path        = optional(string)
          port        = optional(string)
          protocol    = optional(string)
          query       = optional(string)
          status_code = string
        }))
        fixed_response = optional(object({
          content_type = string
          message_body = optional(string)
          status_code  = optional(number)
        }))
        authenticate_cognito = optional(object({
          user_pool_arn                       = string
          user_pool_client_id                 = string
          user_pool_domain                    = string
          authentication_request_extra_params = optional(map(string))
          on_unauthenticated_request          = optional(string)
          scope                               = optional(string)
          session_cookie_name                 = optional(string)
          session_timeout                     = optional(number)
        }))
        authenticate_oidc = optional(object({
          authorization_endpoint              = string
          client_id                           = string
          client_secret                       = string
          issuer                              = string
          token_endpoint                      = string
          user_info_endpoint                  = string
          authentication_request_extra_params = optional(map(string))
          on_unauthenticated_request          = optional(string)
          scope                               = optional(string)
          session_cookie_name                 = optional(string)
          session_timeout                     = optional(number)
        }))
      })
      rules = optional(map(object({
        priority = optional(number)
        actions = list(object({
          type             = string
          order            = optional(number)
          target_group_arn = optional(string)
          target_group_key = optional(string)
          redirect = optional(object({
            host        = optional(string)
            path        = optional(string)
            port        = optional(string)
            protocol    = optional(string)
            query       = optional(string)
            status_code = string
          }))
          fixed_response = optional(object({
            content_type = string
            message_body = optional(string)
            status_code  = optional(number)
          }))
        }))
        conditions = list(object({
          host_header = optional(object({
            values = list(string)
          }))
          http_header = optional(object({
            http_header_name = string
            values           = list(string)
          }))
          http_request_method = optional(object({
            values = list(string)
          }))
          path_pattern = optional(object({
            values = list(string)
          }))
          query_string = optional(list(object({
            key   = optional(string)
            value = string
          })), [])
          source_ip = optional(object({
            values = list(string)
          }))
        }))
      })), {})
      tags = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for lb in var.load_balancers : (lb.name != null) != (lb.name_prefix != null)])
    error_message = "each load balancer must set exactly one of name or name_prefix."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.name == null || length(lb.name) <= 32 && can(regex("^[a-zA-Z0-9-]+$", lb.name))])
    error_message = "name must be up to 32 characters of alphanumerics and hyphens, must not begin or end with a hyphen (ELB naming rules)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.name_prefix == null || length(lb.name_prefix) <= 6 && can(regex("^[a-zA-Z0-9]+$", lb.name_prefix))])
    error_message = "name_prefix must be up to 6 characters of alphanumerics (ELB name_prefix rules; the generated suffix fills the rest)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : contains(["application", "network", "gateway"], lb.load_balancer_type)])
    error_message = "load_balancer_type must be one of application, network or gateway (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.ip_address_type == null || contains(["ipv4", "dualstack", "dualstack-without-public-ipv4"], lb.ip_address_type)])
    error_message = "ip_address_type must be one of ipv4, dualstack or dualstack-without-public-ipv4 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.desync_mitigation_mode == null || contains(["monitor", "defensive", "strictest"], lb.desync_mitigation_mode)])
    error_message = "desync_mitigation_mode must be one of monitor, defensive or strictest (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.dns_record_client_routing_policy == null || contains(["availability_zone_affinity", "partial_availability_zone_affinity", "any_availability_zone"], lb.dns_record_client_routing_policy)])
    error_message = "dns_record_client_routing_policy must be one of availability_zone_affinity, partial_availability_zone_affinity or any_availability_zone (network LBs only)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.xff_header_processing_mode == null || contains(["append", "preserve", "remove"], lb.xff_header_processing_mode)])
    error_message = "xff_header_processing_mode must be one of append, preserve or remove (application LBs only)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.internal || lb.load_balancer_type != "gateway"])
    error_message = "gateway load balancers are inherently internal; set internal = true (the API rejects a public GWLB)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : (tg.name != null) != (tg.name_prefix != null)])])
    error_message = "each target group must set exactly one of name or name_prefix."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.name == null || length(tg.name) <= 32 && can(regex("^[a-zA-Z0-9-]+$", tg.name))])])
    error_message = "target group name must be up to 32 characters of alphanumerics and hyphens, must not begin or end with a hyphen (ELB naming rules)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.name_prefix == null || length(tg.name_prefix) <= 6 && can(regex("^[a-zA-Z0-9]+$", tg.name_prefix))])])
    error_message = "target group name_prefix must be up to 6 characters of alphanumerics (ELB name_prefix rules)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.target_type == null || contains(["instance", "ip", "lambda", "alb"], tg.target_type)])])
    error_message = "target_groups.target_type must be one of instance, ip, lambda or alb (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.protocol == null || contains(["HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP", "GENEVE"], tg.protocol)])])
    error_message = "target_groups.protocol must be one of HTTP, HTTPS, TCP, TLS, UDP, TCP_UDP or GENEVE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.load_balancing_algorithm_type == null || contains(["round_robin", "least_outstanding_requests", "flow_hash"], tg.load_balancing_algorithm_type)])])
    error_message = "target_groups.load_balancing_algorithm_type must be one of round_robin, least_outstanding_requests or flow_hash (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.load_balancing_anomaly_mitigation == null || contains(["on", "off"], tg.load_balancing_anomaly_mitigation)])])
    error_message = "target_groups.load_balancing_anomaly_mitigation must be one of on or off (case-sensitive; least_outstanding_requests algorithm only)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.protocol_version == null || contains(["GRPC", "HTTP1", "HTTP2"], tg.protocol_version)])])
    error_message = "target_groups.protocol_version must be one of GRPC, HTTP1 or HTTP2 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.slow_start == null || tg.slow_start == 0 || tg.slow_start >= 30 && tg.slow_start <= 900])])
    error_message = "target_groups.slow_start must be 0 (disabled) or between 30 and 900 seconds (ELB slow start mode)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.stickiness == null || contains(["lb_cookie", "app_cookie", "source_ip"], tg.stickiness.type)])])
    error_message = "target_groups.stickiness.type must be one of lb_cookie, app_cookie or source_ip (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.stickiness == null || tg.stickiness.cookie_name == null || tg.stickiness.type == "app_cookie"])])
    error_message = "target_groups.stickiness.cookie_name only applies to type app_cookie."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.target_type != "lambda" || (tg.port == null && tg.protocol == null)])])
    error_message = "target_groups: lambda target groups must not set port or protocol (the API rejects both)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : tg.target_type != "alb" || alltrue([for a in tg.attachments : a.port == null])])])
    error_message = "target_groups: alb target attachments must not set port (the API rejects it)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for tg in lb.target_groups : alltrue([for a in tg.attachments : a.availability_zone == null || tg.target_type == "ip"])])])
    error_message = "target_groups: availability_zone is only valid on ip-type target attachments (the API rejects it otherwise)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : contains(["HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP", "GENEVE"], l.protocol)])])
    error_message = "listeners.protocol must be one of HTTP, HTTPS, TCP, TLS, UDP, TCP_UDP or GENEVE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : l.protocol != "HTTPS" && l.protocol != "TLS" || l.ssl_policy != null])])
    error_message = "listeners: HTTPS and TLS listeners require ssl_policy."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : contains(["forward", "redirect", "fixed-response", "authenticate-cognito", "authenticate-oidc"], l.default_action.type)])])
    error_message = "listeners.default_action.type must be one of forward, redirect, fixed-response, authenticate-cognito or authenticate-oidc (case-sensitive)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : l.default_action.type != "forward" || (l.default_action.target_group_arn != null) != (l.default_action.target_group_key != null)])])
    error_message = "listeners.default_action: forward actions require exactly one of target_group_arn or target_group_key."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : l.default_action.type == "forward" || (l.default_action.target_group_arn == null && l.default_action.target_group_key == null)])])
    error_message = "listeners.default_action: target_group_arn and target_group_key are only valid on forward actions."
  }

  validation {
    condition     = alltrue([for lb_key, lb in var.load_balancers : alltrue([for l in lb.listeners : l.default_action.target_group_key == null || can(lb.target_groups[l.default_action.target_group_key])])])
    error_message = "listeners.default_action.target_group_key must reference a key in the same load balancer's target_groups map."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : (l.default_action.type == "redirect") == (l.default_action.redirect != null)])])
    error_message = "listeners.default_action: the redirect block is set exactly for redirect actions."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : (l.default_action.type == "fixed-response") == (l.default_action.fixed_response != null)])])
    error_message = "listeners.default_action: the fixed_response block is set exactly for fixed-response actions."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : l.default_action.redirect == null || contains(["301", "302"], l.default_action.redirect.status_code)])])
    error_message = "listeners.default_action.redirect.status_code must be one of 301 or 302 (HTTP redirect codes accepted by the API)."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for l in lb.listeners : [
          for r in l.rules : alltrue([for a in r.actions : contains(["forward", "redirect", "fixed-response"], a.type)])
        ]
      ]
    ]))
    error_message = "rules.actions.type must be one of forward, redirect or fixed-response (authenticate actions are only valid as a default action; use them on the listener default)."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for l in lb.listeners : [
          for r in l.rules : alltrue([for a in r.actions : a.type != "forward" || (a.target_group_arn != null) != (a.target_group_key != null)])
        ]
      ]
    ]))
    error_message = "rules.actions: forward actions require exactly one of target_group_arn or target_group_key."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for l in lb.listeners : [
          for r in l.rules : alltrue([for a in r.actions : a.type == "forward" || (a.target_group_arn == null && a.target_group_key == null)])
        ]
      ]
    ]))
    error_message = "rules.actions: target_group_arn and target_group_key are only valid on forward actions."
  }

  validation {
    condition = alltrue(flatten([
      for lb_key, lb in var.load_balancers : [
        for l in lb.listeners : [
          for r in l.rules : alltrue([for a in r.actions : a.target_group_key == null || can(lb.target_groups[a.target_group_key])])
        ]
      ]
    ]))
    error_message = "rules.actions.target_group_key must reference a key in the same load balancer's target_groups map."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for l in lb.listeners : [
          for r in l.rules : length(r.conditions) > 0
        ]
      ]
    ]))
    error_message = "rules: every rule requires at least one condition."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for l in lb.listeners : alltrue([for r in l.rules : r.priority == null || r.priority >= 1 && r.priority <= 50000])])])
    error_message = "rules.priority must be between 1 and 50000 (ELB rule priority range; omit for auto-assigned)."
  }
}
