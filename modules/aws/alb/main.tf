resource "aws_lb" "lb" {
  for_each = var.load_balancers

  name                                        = each.value.name
  name_prefix                                 = each.value.name_prefix
  internal                                    = each.value.internal
  load_balancer_type                          = each.value.load_balancer_type
  security_groups                             = each.value.security_group_ids
  subnets                                     = each.value.subnet_ids
  ip_address_type                             = each.value.ip_address_type
  customer_owned_ipv4_pool                    = each.value.customer_owned_ipv4_pool
  desync_mitigation_mode                      = each.value.desync_mitigation_mode
  dns_record_client_routing_policy            = each.value.dns_record_client_routing_policy
  drop_invalid_header_fields                  = each.value.drop_invalid_header_fields
  enable_deletion_protection                  = each.value.deletion_protection
  enable_http2                                = each.value.enable_http2
  enable_tls_version_and_cipher_suite_headers = each.value.enable_tls_version_and_cipher_suite_headers
  enable_xff_client_port                      = each.value.enable_xff_client_port
  enable_waf_fail_open                        = each.value.enable_waf_fail_open
  idle_timeout                                = each.value.idle_timeout
  preserve_host_header                        = each.value.preserve_host_header
  xff_header_processing_mode                  = each.value.xff_header_processing_mode

  dynamic "access_logs" {
    for_each = each.value.access_logs != null ? [each.value.access_logs] : []

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }

  tags = merge(each.value.tags, { Name = coalesce(each.value.name, each.value.name_prefix) })

  lifecycle {
    precondition {
      condition     = (each.value.name != null) != (each.value.name_prefix != null)
      error_message = "load_balancer \"${each.key}\" must set exactly one of name or name_prefix."
    }

    precondition {
      condition     = length(each.value.subnet_ids) > 0
      error_message = "load_balancer \"${each.key}\" requires at least one subnet_id."
    }
  }
}

resource "aws_lb_target_group" "target_group" {
  for_each = local.target_groups

  name                              = each.value.name
  name_prefix                       = each.value.name_prefix
  port                              = each.value.port
  protocol                          = each.value.protocol
  vpc_id                            = each.value.vpc_id
  deregistration_delay              = each.value.deregistration_delay
  load_balancing_algorithm_type     = each.value.load_balancing_algorithm_type
  load_balancing_cross_zone_enabled = each.value.load_balancing_cross_zone_enabled
  load_balancing_anomaly_mitigation = each.value.load_balancing_anomaly_mitigation
  slow_start                        = each.value.slow_start
  connection_termination            = each.value.connection_termination
  protocol_version                  = each.value.protocol_version
  preserve_client_ip                = each.value.preserve_client_ip
  proxy_protocol_v2                 = each.value.proxy_protocol_v2
  target_type                       = each.value.target_type
  ip_address_type                   = each.value.ip_address_type

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []

    content {
      enabled             = health_check.value.enabled
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []

    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
    }
  }

  tags = merge(each.value.tags, { Name = coalesce(each.value.name, each.value.name_prefix) })

  lifecycle {
    precondition {
      condition     = (each.value.name != null) != (each.value.name_prefix != null)
      error_message = "target_group \"${each.key}\" must set exactly one of name or name_prefix."
    }

    precondition {
      condition     = each.value.target_type != "lambda" || (each.value.port == null && each.value.protocol == null)
      error_message = "target_group \"${each.key}\": lambda target groups must not set port or protocol (the API rejects both)."
    }

    precondition {
      condition     = each.value.target_type != "lambda" || each.value.health_check == null || each.value.health_check.enabled
      error_message = "target_group \"${each.key}\": lambda target groups cannot disable health checks (the API requires them enabled)."
    }
  }
}

resource "aws_lb_target_group_attachment" "attachment" {
  for_each = local.attachments

  target_group_arn  = each.value.target_group_arn
  target_id         = each.value.target_id
  port              = each.value.port
  availability_zone = each.value.availability_zone
}

resource "aws_lb_listener" "listener" {
  for_each = local.listeners

  load_balancer_arn        = each.value.load_balancer_arn
  port                     = each.value.port
  protocol                 = each.value.protocol
  ssl_policy               = each.value.ssl_policy
  certificate_arn          = each.value.certificate_arn
  alpn_policy              = each.value.alpn_policy
  tcp_idle_timeout_seconds = each.value.tcp_idle_timeout_seconds

  dynamic "default_action" {
    for_each = [each.value.default_action]

    content {
      type             = default_action.value.type
      order            = default_action.value.order
      target_group_arn = default_action.value.target_group_arn

      dynamic "redirect" {
        for_each = default_action.value.redirect != null ? [default_action.value.redirect] : []

        content {
          host        = redirect.value.host
          path        = redirect.value.path
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }

      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response != null ? [default_action.value.fixed_response] : []

        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "authenticate_cognito" {
        for_each = default_action.value.authenticate_cognito != null ? [default_action.value.authenticate_cognito] : []

        content {
          user_pool_arn                       = authenticate_cognito.value.user_pool_arn
          user_pool_client_id                 = authenticate_cognito.value.user_pool_client_id
          user_pool_domain                    = authenticate_cognito.value.user_pool_domain
          authentication_request_extra_params = authenticate_cognito.value.authentication_request_extra_params
          on_unauthenticated_request          = authenticate_cognito.value.on_unauthenticated_request
          scope                               = authenticate_cognito.value.scope
          session_cookie_name                 = authenticate_cognito.value.session_cookie_name
          session_timeout                     = authenticate_cognito.value.session_timeout
        }
      }

      dynamic "authenticate_oidc" {
        for_each = default_action.value.authenticate_oidc != null ? [default_action.value.authenticate_oidc] : []

        content {
          authorization_endpoint              = authenticate_oidc.value.authorization_endpoint
          client_id                           = authenticate_oidc.value.client_id
          client_secret                       = authenticate_oidc.value.client_secret
          issuer                              = authenticate_oidc.value.issuer
          token_endpoint                      = authenticate_oidc.value.token_endpoint
          user_info_endpoint                  = authenticate_oidc.value.user_info_endpoint
          authentication_request_extra_params = authenticate_oidc.value.authentication_request_extra_params
          on_unauthenticated_request          = authenticate_oidc.value.on_unauthenticated_request
          scope                               = authenticate_oidc.value.scope
          session_cookie_name                 = authenticate_oidc.value.session_cookie_name
          session_timeout                     = authenticate_oidc.value.session_timeout
        }
      }
    }
  }

  tags = each.value.tags

  lifecycle {
    precondition {
      condition     = each.value.default_action.type != "forward" || each.value.default_action.target_group_arn != null
      error_message = "listener \"${each.key}\": forward default_action requires target_group_arn or target_group_key."
    }

    precondition {
      condition     = each.value.default_action.type != "redirect" || each.value.default_action.redirect != null
      error_message = "listener \"${each.key}\": redirect default_action requires the redirect block."
    }

    precondition {
      condition     = each.value.default_action.type != "fixed-response" || each.value.default_action.fixed_response != null
      error_message = "listener \"${each.key}\": fixed-response default_action requires the fixed_response block."
    }
  }
}

resource "aws_lb_listener_rule" "rule" {
  for_each = local.rules

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = each.value.actions

    content {
      type             = action.value.type
      order            = action.value.order
      target_group_arn = action.value.target_group_arn

      dynamic "redirect" {
        for_each = action.value.redirect != null ? [action.value.redirect] : []

        content {
          host        = redirect.value.host
          path        = redirect.value.path
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }

      dynamic "fixed_response" {
        for_each = action.value.fixed_response != null ? [action.value.fixed_response] : []

        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions

    content {
      dynamic "host_header" {
        for_each = condition.value.host_header != null ? [condition.value.host_header] : []

        content {
          values = host_header.value.values
        }
      }

      dynamic "http_header" {
        for_each = condition.value.http_header != null ? [condition.value.http_header] : []

        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }

      dynamic "http_request_method" {
        for_each = condition.value.http_request_method != null ? [condition.value.http_request_method] : []

        content {
          values = http_request_method.value.values
        }
      }

      dynamic "path_pattern" {
        for_each = condition.value.path_pattern != null ? [condition.value.path_pattern] : []

        content {
          values = path_pattern.value.values
        }
      }

      dynamic "query_string" {
        for_each = condition.value.query_string

        content {
          key   = query_string.value.key
          value = query_string.value.value
        }
      }

      dynamic "source_ip" {
        for_each = condition.value.source_ip != null ? [condition.value.source_ip] : []

        content {
          values = source_ip.value.values
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = alltrue([for a in each.value.actions : a.type != "forward" || a.target_group_arn != null])
      error_message = "rule \"${each.key}\": every forward action requires target_group_arn or target_group_key."
    }

    precondition {
      condition     = alltrue([for a in each.value.actions : a.type != "redirect" || a.redirect != null])
      error_message = "rule \"${each.key}\": every redirect action requires the redirect block."
    }

    precondition {
      condition     = alltrue([for a in each.value.actions : a.type != "fixed-response" || a.fixed_response != null])
      error_message = "rule \"${each.key}\": every fixed-response action requires the fixed_response block."
    }

    precondition {
      condition     = length(each.value.conditions) > 0
      error_message = "rule \"${each.key}\" requires at least one condition."
    }

    precondition {
      condition     = length([for c in each.value.conditions : c if length([for m in [c.host_header, c.http_header, c.http_request_method, c.path_pattern, c.source_ip] : m if m != null]) + length(c.query_string) > 1]) == 0
      error_message = "rule \"${each.key}\": each condition block may set only one matcher (host_header, http_header, http_request_method, path_pattern, query_string or source_ip)."
    }
  }
}

locals {
  target_groups = merge([
    for lb_key, lb in var.load_balancers : {
      for tg_key, tg in lb.target_groups : "${lb_key}.${tg_key}" => {
        vpc_id                            = tg.vpc_id
        name                              = tg.name
        name_prefix                       = tg.name_prefix
        port                              = tg.port
        protocol                          = tg.protocol
        deregistration_delay              = tg.deregistration_delay
        load_balancing_algorithm_type     = tg.load_balancing_algorithm_type
        load_balancing_cross_zone_enabled = tg.load_balancing_cross_zone_enabled
        load_balancing_anomaly_mitigation = tg.load_balancing_anomaly_mitigation
        slow_start                        = tg.slow_start
        connection_termination            = tg.connection_termination
        protocol_version                  = tg.protocol_version
        preserve_client_ip                = tg.preserve_client_ip
        proxy_protocol_v2                 = tg.proxy_protocol_v2
        target_type                       = tg.target_type
        ip_address_type                   = tg.ip_address_type
        health_check                      = tg.health_check
        stickiness                        = tg.stickiness
        tags                              = tg.tags
      }
    }
  ]...)

  attachments = merge([
    for lb_key, lb in var.load_balancers : merge([
      for tg_key, tg in lb.target_groups : {
        for att_key, att in tg.attachments : "${lb_key}.${tg_key}.${att_key}" => {
          target_group_arn  = aws_lb_target_group.target_group["${lb_key}.${tg_key}"].arn
          target_id         = att.target_id
          port              = att.port
          availability_zone = att.availability_zone
        }
      }
    ]...)
  ]...)

  listeners = merge([
    for lb_key, lb in var.load_balancers : {
      for l_key, l in lb.listeners : "${lb_key}.${l_key}" => {
        load_balancer_arn        = aws_lb.lb[lb_key].arn
        port                     = l.port
        protocol                 = l.protocol
        ssl_policy               = l.ssl_policy
        certificate_arn          = l.certificate_arn
        alpn_policy              = l.alpn_policy
        tcp_idle_timeout_seconds = l.tcp_idle_timeout_seconds
        default_action = merge(l.default_action, {
          target_group_arn = l.default_action.target_group_key != null ? aws_lb_target_group.target_group["${lb_key}.${l.default_action.target_group_key}"].arn : l.default_action.target_group_arn
        })
        tags = l.tags
      }
    }
  ]...)

  rules = merge([
    for lb_key, lb in var.load_balancers : merge([
      for l_key, l in lb.listeners : {
        for r_key, r in l.rules : "${lb_key}.${l_key}.${r_key}" => {
          listener_arn = aws_lb_listener.listener["${lb_key}.${l_key}"].arn
          priority     = r.priority
          actions = [for a in r.actions : merge(a, {
            target_group_arn = a.target_group_key != null ? aws_lb_target_group.target_group["${lb_key}.${a.target_group_key}"].arn : a.target_group_arn
          })]
          conditions = r.conditions
        }
      }
    ]...)
  ]...)
}
