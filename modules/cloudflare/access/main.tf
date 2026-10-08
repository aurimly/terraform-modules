terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_zero_trust_access_identity_provider" "idp" {
  for_each = var.identity_providers

  account_id = var.account_id
  name       = each.value.name
  type       = each.value.type
  read_only  = each.value.read_only
  config     = each.value.config
}

resource "cloudflare_zero_trust_access_policy" "policy" {
  for_each = var.policies

  account_id                     = var.account_id
  name                           = each.value.name
  decision                       = each.value.decision
  session_duration               = each.value.session_duration
  include                        = each.value.include
  exclude                        = each.value.exclude
  require                        = each.value.require
  approval_groups                = each.value.approval_groups
  approval_required              = each.value.approval_required
  purpose_justification_prompt   = each.value.purpose_justification_prompt
  purpose_justification_required = each.value.purpose_justification_required
  isolation_required             = each.value.isolation_required
  connection_rules               = each.value.connection_rules
  mfa_config                     = each.value.mfa_config
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = var.applications

  account_id                      = var.account_id
  name                            = each.value.name
  type                            = each.value.type
  domain                          = each.value.domain
  session_duration                = each.value.session_duration
  allowed_idps                    = each.value.allowed_idps != null ? toset([for k in each.value.allowed_idps : cloudflare_zero_trust_access_identity_provider.idp[k].id]) : null
  policies                        = each.value.policies != null ? [for k in each.value.policies : { id = cloudflare_zero_trust_access_policy.policy[k].id }] : null
  tags                            = each.value.tags
  app_launcher_visible            = each.value.app_launcher_visible
  skip_interstitial               = each.value.skip_interstitial
  skip_app_launcher_login_page    = each.value.skip_app_launcher_login_page
  auto_redirect_to_identity       = each.value.auto_redirect_to_identity
  allow_authenticate_via_warp     = each.value.allow_authenticate_via_warp
  allow_iframe                    = each.value.allow_iframe
  service_auth_401_redirect       = each.value.service_auth_401_redirect
  options_preflight_bypass        = each.value.options_preflight_bypass
  enable_binding_cookie           = each.value.enable_binding_cookie
  http_only_cookie_attribute      = each.value.http_only_cookie_attribute
  path_cookie_attribute           = each.value.path_cookie_attribute
  same_site_cookie_attribute      = each.value.same_site_cookie_attribute
  read_service_tokens_from_header = each.value.read_service_tokens_from_header
  custom_deny_message             = each.value.custom_deny_message
  custom_deny_url                 = each.value.custom_deny_url
  custom_non_identity_deny_url    = each.value.custom_non_identity_deny_url
  custom_pages                    = each.value.custom_pages
  bg_color                        = each.value.bg_color
  header_bg_color                 = each.value.header_bg_color
  logo_url                        = each.value.logo_url
  app_launcher_logo_url           = each.value.app_launcher_logo_url
  cors_headers                    = each.value.cors_headers
  landing_page_design             = each.value.landing_page_design
  footer_links                    = each.value.footer_links
  self_hosted_domains             = each.value.self_hosted_domains
  destinations                    = each.value.destinations
  target_criteria                 = each.value.target_criteria
}
