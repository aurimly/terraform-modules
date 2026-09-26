locals {
  oacs = merge([
    for dist_key, dist in var.distributions : {
      for origin_key, origin in dist.origins : "${dist_key}.${origin_key}" => {
        dist_key         = dist_key
        origin_key       = origin_key
        origin_id        = origin_key
        description      = coalesce(try(origin.oac.description, null), "Origin access control for ${dist_key}.${origin_key}")
        origin_type      = origin.oac.origin_type
        signing_behavior = origin.oac.signing_behavior
        signing_protocol = origin.oac.signing_protocol
      }
      if origin.oac != null
    }
  ]...)
}

resource "aws_cloudfront_origin_access_control" "oac" {
  for_each = local.oacs

  name                              = replace(each.key, ".", "-")
  description                       = each.value.description
  origin_access_control_origin_type = each.value.origin_type
  signing_behavior                  = each.value.signing_behavior
  signing_protocol                  = each.value.signing_protocol
}

resource "aws_cloudfront_distribution" "distribution" {
  for_each = var.distributions

  comment             = each.value.comment
  enabled             = each.value.enabled
  default_root_object = each.value.default_root_object
  http_version        = each.value.http_version
  is_ipv6_enabled     = each.value.is_ipv6_enabled
  wait_for_deployment = each.value.wait_for_deployment
  price_class         = each.value.price_class
  retain_on_delete    = each.value.retain_on_delete
  web_acl_id          = each.value.web_acl_id
  aliases             = each.value.aliases

  logging_config {
    bucket          = try(each.value.logging.bucket, null)
    prefix          = try(each.value.logging.prefix, null)
    include_cookies = try(each.value.logging.include_cookies, null)
  }

  viewer_certificate {
    cloudfront_default_certificate = each.value.viewer_certificate == null ? true : coalesce(each.value.viewer_certificate.cloudfront_default_certificate, false)
    acm_certificate_arn            = try(each.value.viewer_certificate.acm_certificate_arn, null)
    iam_certificate_id             = try(each.value.viewer_certificate.iam_certificate_id, null)
    minimum_protocol_version = each.value.viewer_certificate == null ? null : (
      each.value.viewer_certificate.minimum_protocol_version != null ? each.value.viewer_certificate.minimum_protocol_version : (
        each.value.viewer_certificate.cloudfront_default_certificate == true ? null : "TLSv1.2_2021"
      )
    )
    ssl_support_method = try(each.value.viewer_certificate.ssl_support_method, null)
  }

  restrictions {
    geo_restriction {
      restriction_type = try(each.value.restrictions.geo_restriction.restriction_type, "none")
      locations        = try(each.value.restrictions.geo_restriction.locations, null)
    }
  }

  dynamic "origin" {
    for_each = each.value.origins

    content {
      origin_id                   = origin.key
      domain_name                 = origin.value.domain_name
      origin_path                 = origin.value.origin_path
      connection_attempts         = origin.value.connection_attempts
      connection_timeout          = origin.value.connection_timeout
      response_completion_timeout = origin.value.response_completion_timeout

      dynamic "origin_shield" {
        for_each = origin.value.origin_shield != null ? [1] : []

        content {
          enabled              = origin.value.origin_shield.enabled
          origin_shield_region = origin.value.origin_shield.origin_shield_region
        }
      }

      dynamic "custom_header" {
        for_each = origin.value.custom_headers

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "s3_origin_config" {
        for_each = origin.value.s3_origin_access_identity != null ? [1] : []

        content {
          origin_access_identity = origin.value.s3_origin_access_identity
        }
      }

      origin_access_control_id = origin.value.oac != null ? aws_cloudfront_origin_access_control.oac["${each.key}.${origin.key}"].id : null

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [1] : []

        content {
          http_port                = origin.value.custom_origin_config.http_port
          https_port               = origin.value.custom_origin_config.https_port
          origin_protocol_policy   = origin.value.custom_origin_config.origin_protocol_policy
          origin_ssl_protocols     = origin.value.custom_origin_config.origin_ssl_protocols
          ip_address_type          = origin.value.custom_origin_config.ip_address_type
          origin_keepalive_timeout = origin.value.custom_origin_config.origin_keepalive_timeout
          origin_read_timeout      = origin.value.custom_origin_config.origin_read_timeout
        }
      }
    }
  }

  default_cache_behavior {
    target_origin_id           = each.value.default_cache_behavior.target_origin_id
    viewer_protocol_policy     = each.value.default_cache_behavior.viewer_protocol_policy
    allowed_methods            = each.value.default_cache_behavior.allowed_methods
    cached_methods             = each.value.default_cache_behavior.cached_methods
    cache_policy_id            = each.value.default_cache_behavior.cache_policy_id
    origin_request_policy_id   = each.value.default_cache_behavior.origin_request_policy_id
    response_headers_policy_id = each.value.default_cache_behavior.response_headers_policy_id
    compress                   = each.value.default_cache_behavior.compress
    trusted_key_groups         = each.value.default_cache_behavior.trusted_key_groups
    smooth_streaming           = each.value.default_cache_behavior.smooth_streaming
    field_level_encryption_id  = each.value.default_cache_behavior.field_level_encryption_id
    realtime_log_config_arn    = each.value.default_cache_behavior.realtime_log_config_arn
  }

  dynamic "ordered_cache_behavior" {
    for_each = each.value.ordered_cache_behaviors

    content {
      path_pattern               = ordered_cache_behavior.value.path_pattern
      target_origin_id           = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy     = ordered_cache_behavior.value.viewer_protocol_policy
      allowed_methods            = ordered_cache_behavior.value.allowed_methods
      cached_methods             = ordered_cache_behavior.value.cached_methods
      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id
      compress                   = ordered_cache_behavior.value.compress
      trusted_key_groups         = ordered_cache_behavior.value.trusted_key_groups
      smooth_streaming           = ordered_cache_behavior.value.smooth_streaming
      field_level_encryption_id  = ordered_cache_behavior.value.field_level_encryption_id
      realtime_log_config_arn    = ordered_cache_behavior.value.realtime_log_config_arn
    }
  }

  dynamic "custom_error_response" {
    for_each = each.value.custom_error_responses

    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(each.value.origins), each.value.default_cache_behavior.target_origin_id)
      error_message = "distribution \"${each.key}\": default_cache_behavior.target_origin_id must be one of the origins map keys."
    }

    precondition {
      condition = alltrue([
        for b in each.value.ordered_cache_behaviors : contains(keys(each.value.origins), b.target_origin_id)
      ])
      error_message = "distribution \"${each.key}\": every ordered_cache_behavior.target_origin_id must be one of the origins map keys."
    }

    precondition {
      condition = alltrue([
        for o in values(each.value.origins) : o.origin_shield == null || o.origin_shield.enabled != true || o.origin_shield.origin_shield_region != null
      ])
      error_message = "distribution \"${each.key}\": origin_shield enabled requires origin_shield_region (the API rejects an enabled Origin Shield without a region)."
    }
  }

  tags = each.value.tags
}
