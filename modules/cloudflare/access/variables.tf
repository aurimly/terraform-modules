variable "account_id" {
  description = "Cloudflare account ID that owns the Access resources."
  type        = string
}

variable "identity_providers" {
  description = "Map of Zero Trust identity providers keyed by an arbitrary unique identifier. Config is the provider's full union — set only the fields the IdP type needs; the API validates per type."
  type = map(object({
    name      = string
    type      = string
    read_only = optional(bool)
    config = object({
      apps_domain                = optional(string)
      attributes                 = optional(list(string))
      auth_url                   = optional(string)
      authorization_server_id    = optional(string)
      centrify_account           = optional(string)
      centrify_app_id            = optional(string)
      certs_url                  = optional(string)
      claims                     = optional(list(string))
      client_id                  = optional(string)
      client_secret              = optional(string)
      conditional_access_enabled = optional(bool)
      directory_id               = optional(string)
      email_attribute_name       = optional(string)
      email_claim_name           = optional(string)
      enable_encryption          = optional(bool)
      header_attributes = optional(list(object({
        attribute_name = optional(string)
        header_name    = optional(string)
      })))
      idp_public_certs            = optional(list(string))
      issuer_url                  = optional(string)
      okta_account                = optional(string)
      onelogin_account            = optional(string)
      ping_env_id                 = optional(string)
      pkce_enabled                = optional(bool)
      prompt                      = optional(string)
      restrict_to_account_members = optional(bool)
      scopes                      = optional(list(string))
      sign_request                = optional(bool)
      sso_target_url              = optional(string)
      support_groups              = optional(bool)
      token_url                   = optional(string)
    })
  }))
}

variable "policies" {
  description = "Map of reusable Access policies keyed by an arbitrary unique identifier. include/exclude/require are sets of condition objects, at most one condition per element; see the README condition table."
  type = map(object({
    name             = string
    decision         = string
    session_duration = optional(string)
    include = optional(set(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    })))
    exclude = optional(set(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    })))
    require = optional(set(object({
      any_valid_service_token = optional(object({}))
      auth_context = optional(object({
        ac_id                = string
        id                   = string
        identity_provider_id = string
      }))
      auth_method = optional(object({
        auth_method = string
      }))
      azure_ad = optional(object({
        id                   = string
        identity_provider_id = string
      }))
      certificate = optional(object({}))
      cloudflare_account_member = optional(object({
        account_id = optional(string)
      }))
      common_name = optional(object({
        common_name = string
      }))
      device_posture = optional(object({
        integration_uid = string
      }))
      email = optional(object({
        email = string
      }))
      email_domain = optional(object({
        domain = string
      }))
      email_list = optional(object({
        id = string
      }))
      everyone = optional(object({}))
      external_evaluation = optional(object({
        evaluate_url = string
        keys_url     = string
      }))
      geo = optional(object({
        country_code = string
      }))
      github_organization = optional(object({
        identity_provider_id = string
        name                 = string
        team                 = optional(string)
      }))
      group = optional(object({
        id = string
      }))
      gsuite = optional(object({
        email                = string
        identity_provider_id = string
      }))
      ip = optional(object({
        ip = string
      }))
      ip_list = optional(object({
        id = string
      }))
      linked_app_token = optional(object({
        app_uid = string
      }))
      login_method = optional(object({
        id = string
      }))
      oidc = optional(object({
        claim_name           = string
        claim_value          = string
        identity_provider_id = string
      }))
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      saml = optional(object({
        attribute_name       = string
        attribute_value      = string
        identity_provider_id = string
      }))
      service_token = optional(object({
        token_id = string
      }))
      user_risk_score = optional(object({
        user_risk_score = list(string)
      }))
    })))
    approval_groups = optional(list(object({
      approvals_needed = number
      email_addresses  = optional(list(string))
      email_list_uuid  = optional(string)
    })))
    approval_required              = optional(bool)
    purpose_justification_prompt   = optional(string)
    purpose_justification_required = optional(bool)
    isolation_required             = optional(bool)
    connection_rules = optional(object({
      rdp = optional(object({
        allowed_clipboard_local_to_remote_formats = optional(list(string))
        allowed_clipboard_remote_to_local_formats = optional(list(string))
      }))
    }))
    mfa_config = optional(object({
      allowed_authenticators = optional(list(string))
      mfa_disabled           = optional(bool)
      session_duration       = optional(string)
    }))
  }))
}

variable "applications" {
  description = "Map of Access applications keyed by an arbitrary unique identifier. policies is an ordered list of policy keys (ascending precedence); allowed_idps is a list of identity_providers keys. Inline policies are out of scope — attach reusable ones by key (see README)."
  type = map(object({
    name                            = optional(string)
    type                            = optional(string)
    domain                          = optional(string)
    session_duration                = optional(string)
    policies                        = optional(list(string))
    allowed_idps                    = optional(list(string))
    tags                            = optional(set(string))
    app_launcher_visible            = optional(bool)
    skip_interstitial               = optional(bool)
    skip_app_launcher_login_page    = optional(bool)
    auto_redirect_to_identity       = optional(bool)
    allow_authenticate_via_warp     = optional(bool)
    allow_iframe                    = optional(bool)
    service_auth_401_redirect       = optional(bool)
    options_preflight_bypass        = optional(bool)
    enable_binding_cookie           = optional(bool)
    http_only_cookie_attribute      = optional(bool)
    path_cookie_attribute           = optional(bool)
    same_site_cookie_attribute      = optional(string)
    read_service_tokens_from_header = optional(string)
    custom_deny_message             = optional(string)
    custom_deny_url                 = optional(string)
    custom_non_identity_deny_url    = optional(string)
    custom_pages                    = optional(list(string))
    bg_color                        = optional(string)
    header_bg_color                 = optional(string)
    logo_url                        = optional(string)
    app_launcher_logo_url           = optional(string)
    cors_headers = optional(object({
      allow_all_headers = optional(bool)
      allow_all_methods = optional(bool)
      allow_all_origins = optional(bool)
      allow_credentials = optional(bool)
      allowed_headers   = optional(set(string))
      allowed_methods   = optional(set(string))
      allowed_origins   = optional(set(string))
      max_age           = optional(number)
    }))
    landing_page_design = optional(object({
      title             = optional(string)
      button_color      = optional(string)
      button_text_color = optional(string)
      image_url         = optional(string)
      message           = optional(string)
    }))
    footer_links = optional(list(object({
      name = string
      url  = string
    })))
    self_hosted_domains = optional(set(string))
    destinations = optional(list(object({
      type          = optional(string)
      cidr          = optional(string)
      hostname      = optional(string)
      l4_protocol   = optional(string)
      mcp_server_id = optional(string)
      port_range    = optional(string)
      uri           = optional(string)
      vnet_id       = optional(string)
      worker_id     = optional(string)
    })))
    target_criteria = optional(list(object({
      port              = number
      protocol          = string
      target_attributes = map(list(string))
    })))
  }))

  validation {
    condition = alltrue([
      for app in var.applications : app.policies == null || alltrue([
        for k in app.policies : contains(keys(var.policies), k)
      ])
    ])
    error_message = "Every applications[].policies element must be a key in policies."
  }

  validation {
    condition = alltrue([
      for app in var.applications : app.allowed_idps == null || alltrue([
        for k in app.allowed_idps : contains(keys(var.identity_providers), k)
      ])
    ])
    error_message = "Every applications[].allowed_idps element must be a key in identity_providers."
  }
}
