variable "distributions" {
  description = "Map of CloudFront distributions keyed by an arbitrary identifier. Each entry creates one aws_cloudfront_distribution plus one aws_cloudfront_origin_access_control per S3 origin that sets oac."
  type = map(object({
    enabled             = optional(bool, true)
    comment             = optional(string)
    default_root_object = optional(string)
    http_version        = optional(string, "http2and3")
    is_ipv6_enabled     = optional(bool, true)
    wait_for_deployment = optional(bool, true)
    price_class         = optional(string)
    retain_on_delete    = optional(bool, false)
    web_acl_id          = optional(string)

    aliases = optional(list(string), [])

    viewer_certificate = optional(object({
      acm_certificate_arn            = optional(string)
      iam_certificate_id             = optional(string)
      cloudfront_default_certificate = optional(bool)
      minimum_protocol_version       = optional(string)
      ssl_support_method             = optional(string)
    }))

    logging = optional(object({
      bucket          = string
      prefix          = optional(string)
      include_cookies = optional(bool, false)
    }))

    restrictions = optional(object({
      geo_restriction = optional(object({
        restriction_type = string
        locations        = optional(list(string))
      }))
    }))

    custom_error_responses = optional(map(object({
      error_code            = number
      response_code         = optional(number)
      response_page_path    = optional(string)
      error_caching_min_ttl = optional(number)
    })), {})

    origins = map(object({
      domain_name = string
      origin_path = optional(string)

      connection_attempts         = optional(number)
      connection_timeout          = optional(number)
      response_completion_timeout = optional(number)

      origin_shield = optional(object({
        enabled              = optional(bool, false)
        origin_shield_region = optional(string)
      }))

      custom_headers = optional(map(object({
        name  = string
        value = string
      })), {})

      oac = optional(object({
        origin_type      = optional(string, "s3")
        signing_behavior = optional(string, "always")
        signing_protocol = optional(string, "sigv4")
        description      = optional(string)
      }))

      s3_origin_access_identity = optional(string)

      custom_origin_config = optional(object({
        http_port                = number
        https_port               = number
        origin_protocol_policy   = string
        origin_ssl_protocols     = list(string)
        ip_address_type          = optional(string)
        origin_keepalive_timeout = optional(number)
        origin_read_timeout      = optional(number)
      }))
    }))

    default_cache_behavior = object({
      target_origin_id           = string
      viewer_protocol_policy     = string
      allowed_methods            = optional(list(string), ["GET", "HEAD", "OPTIONS"])
      cached_methods             = optional(list(string), ["GET", "HEAD"])
      cache_policy_id            = string
      origin_request_policy_id   = optional(string)
      response_headers_policy_id = optional(string)
      compress                   = optional(bool)
      trusted_key_groups         = optional(list(string))
      smooth_streaming           = optional(bool)
      field_level_encryption_id  = optional(string)
      realtime_log_config_arn    = optional(string)
    })

    ordered_cache_behaviors = optional(map(object({
      path_pattern               = string
      target_origin_id           = string
      viewer_protocol_policy     = string
      allowed_methods            = optional(list(string), ["GET", "HEAD", "OPTIONS"])
      cached_methods             = optional(list(string), ["GET", "HEAD"])
      cache_policy_id            = string
      origin_request_policy_id   = optional(string)
      response_headers_policy_id = optional(string)
      compress                   = optional(bool)
      trusted_key_groups         = optional(list(string))
      smooth_streaming           = optional(bool)
      field_level_encryption_id  = optional(string)
      realtime_log_config_arn    = optional(string)
    })), {})

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.distributions) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (OAC resource addresses and composite output keys are composed from distribution and origin map keys)."
  }

  validation {
    condition = alltrue([
      for k in keys(var.distributions) : alltrue([for ok in keys(var.distributions[k].origins) : can(regex("^[^.]+$", ok))])
    ])
    error_message = "origins map keys must not contain '.' (they are used as origin_id and compose OAC addresses and output keys)."
  }

  validation {
    condition     = alltrue([for d in var.distributions : contains(["http1.1", "http2", "http2and3", "http3"], d.http_version)])
    error_message = "http_version must be one of http1.1, http2, http2and3 or http3 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for d in var.distributions : d.price_class == null || contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], d.price_class)])
    error_message = "price_class must be one of PriceClass_100, PriceClass_200 or PriceClass_All (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : d.viewer_certificate == null || length([
        for v in [
          d.viewer_certificate.acm_certificate_arn,
          d.viewer_certificate.iam_certificate_id,
          d.viewer_certificate.cloudfront_default_certificate
        ] : v if v != null
      ]) == 1
    ])
    error_message = "exactly one of acm_certificate_arn, iam_certificate_id or cloudfront_default_certificate must be set in viewer_certificate."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : d.viewer_certificate == null || !(d.viewer_certificate.cloudfront_default_certificate == true && d.viewer_certificate.minimum_protocol_version != null && d.viewer_certificate.minimum_protocol_version != "TLSv1")
    ])
    error_message = "cloudfront_default_certificate = true requires minimum_protocol_version null or \"TLSv1\" (the API rejects newer protocol versions with the CloudFront default certificate)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : d.viewer_certificate == null || !(d.viewer_certificate.cloudfront_default_certificate == true && d.viewer_certificate.ssl_support_method != null)
    ])
    error_message = "ssl_support_method cannot be set with cloudfront_default_certificate = true."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : d.viewer_certificate == null || d.viewer_certificate.ssl_support_method == null || contains(["sni-only", "vip", "static-ip"], d.viewer_certificate.ssl_support_method)
    ])
    error_message = "ssl_support_method must be one of sni-only, vip or static-ip (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : d.restrictions == null || d.restrictions.geo_restriction == null || contains(["none", "whitelist", "blacklist"], d.restrictions.geo_restriction.restriction_type)
    ])
    error_message = "restrictions.geo_restriction.restriction_type must be one of none, whitelist or blacklist (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : d.restrictions == null || d.restrictions.geo_restriction == null || d.restrictions.geo_restriction.restriction_type != "none" || length(lookup(d.restrictions.geo_restriction, "locations", [])) == 0
    ])
    error_message = "geo_restriction restriction_type = \"none\" cannot be combined with locations (the API rejects both)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : d.restrictions == null || d.restrictions.geo_restriction == null || d.restrictions.geo_restriction.restriction_type == "none" || length(lookup(d.restrictions.geo_restriction, "locations", [])) > 0
    ])
    error_message = "geo_restriction restriction_type whitelist or blacklist requires a non-empty locations list."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : alltrue([
        for e in values(d.custom_error_responses) : ((e.response_code != null) == (e.response_page_path != null)) && e.error_code >= 400 && e.error_code <= 599
      ])
    ])
    error_message = "custom_error_responses: error_code must be 400-599 and response_code and response_page_path must be set together (the API requires both or neither)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : alltrue([
        for e in values(d.custom_error_responses) : e.response_code == null || (e.response_code >= 200 && e.response_code <= 599)
      ])
    ])
    error_message = "custom_error_responses: response_code must be 200-599 (200 restores the origin content, otherwise a custom code)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : length(distinct([for k, e in d.custom_error_responses : e.error_code])) == length(d.custom_error_responses)
    ])
    error_message = "custom_error_responses: error_code must be unique per distribution (the API rejects duplicates)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : alltrue([
        for o in values(d.origins) : o.custom_origin_config == null || contains(["http-only", "https-only", "match-viewer"], o.custom_origin_config.origin_protocol_policy)
      ])
    ])
    error_message = "custom_origin_config.origin_protocol_policy must be one of http-only, https-only or match-viewer (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : alltrue([
        for o in values(d.origins) : o.custom_origin_config == null || alltrue([for p in o.custom_origin_config.origin_ssl_protocols : contains(["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"], p)])
      ])
    ])
    error_message = "custom_origin_config.origin_ssl_protocols entries must be SSLv3, TLSv1, TLSv1.1 or TLSv1.2 (case-sensitive; CloudFront supports only these for origin connections)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : alltrue([
        for o in values(d.origins) : length([
          for v in [o.oac, o.s3_origin_access_identity, o.custom_origin_config] : v if v != null
        ]) <= 1
      ])
    ])
    error_message = "each origin must set at most one of oac, s3_origin_access_identity (legacy OAI) or custom_origin_config — S3 auth paths and custom origins are mutually exclusive."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : alltrue([
        for b in concat([d.default_cache_behavior], values(d.ordered_cache_behaviors)) : b.viewer_protocol_policy == null || contains(["allow-all", "https-only", "redirect-to-https"], b.viewer_protocol_policy)
      ])
    ])
    error_message = "viewer_protocol_policy must be one of allow-all, https-only or redirect-to-https (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : alltrue([
        for b in concat([d.default_cache_behavior], values(d.ordered_cache_behaviors)) : alltrue([for m in b.allowed_methods : contains(["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"], m)]) && alltrue([for m in b.cached_methods : contains(["GET", "HEAD", "OPTIONS"], m)])
      ])
    ])
    error_message = "allowed_methods entries must be GET, HEAD, OPTIONS, PUT, POST, PATCH or DELETE; cached_methods entries GET, HEAD or OPTIONS (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : alltrue([
        for b in concat([d.default_cache_behavior], values(d.ordered_cache_behaviors)) : length(setintersection(b.cached_methods, b.allowed_methods)) == length(b.cached_methods)
      ])
    ])
    error_message = "cached_methods must be a subset of allowed_methods per behavior."
  }

  validation {
    condition = alltrue([
      for d in var.distributions : d.origins != null && length(d.origins) > 0
    ])
    error_message = "origins must contain at least one origin per distribution."
  }
}
