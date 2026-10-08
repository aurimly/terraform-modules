# cloudflare/access

Map-keyed module for Cloudflare Zero Trust Access at account level:
identity providers, reusable policies, and applications with policy and
identity-provider attachment done by module key.

Zone-level apps and identity providers are out of scope (the account_id
form covers the common case). Researched against provider 5.24.0; the
`required_providers` floor stays the repo-wide `>= 5.0.0`, but the
attach-by-ID drift handling for app policies is recent provider work —
consumers far below 5.24 may see diff noise on attachments.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | — | Cloudflare account ID. |
| `identity_providers` | `map(object)` | `—` | Identity providers, keyed by an arbitrary unique ID. |
| `policies` | `map(object)` | `—` | Reusable policies, keyed by an arbitrary unique ID. |
| `applications` | `map(object)` | `—` | Applications, keyed by an arbitrary unique ID. |

### `identity_providers` object

`config` is required; it is the provider's union across IdP types — set
only the fields the type needs (the API validates per type, following the
`dns-records` `data` posture). `redirect_url` is computed-only upstream
and not settable, so it is not in the input.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | IdP name. |
| `type` | `string` | — | `onetimepin`, `azureAD`, `saml`, `centrify`, `facebook`, `github`, `google-apps`, `google`, `linkedin`, `oidc`, `okta`, `onelogin`, `pingone`, `yandex`, or `cloudflare`. Changing type replaces the IdP. |
| `read_only` | `bool` | `null` | Also use this IdP for non-Access (WARP) auth. |
| `config` | `object` | — | Union: `apps_domain`, `attributes`, `auth_url`, `authorization_server_id`, `centrify_account`, `centrify_app_id`, `certs_url`, `claims`, `client_id`, `client_secret`, `conditional_access_enabled`, `directory_id`, `email_attribute_name`, `email_claim_name`, `enable_encryption`, `header_attributes`, `idp_public_certs`, `issuer_url`, `okta_account`, `onelogin_account`, `ping_env_id`, `pkce_enabled`, `prompt`, `restrict_to_account_members`, `scopes`, `sign_request`, `sso_target_url`, `support_groups`, `token_url`. |

### `policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy name. |
| `decision` | `string` | — | `allow`, `deny`, `non_identity`, or `bypass`. |
| `session_duration` | `string` | `null` | e.g. `24h`, `30m`. |
| `include` | `set(object)` | `null` | Condition set — see the condition table. |
| `exclude` | `set(object)` | `null` | Condition set. |
| `require` | `set(object)` | `null` | Condition set. |
| `approval_groups` | `list(object)` | `null` | Approval flow: `approvals_needed` (required), `email_addresses`, `email_list_uuid`. |
| `approval_required` | `bool` | `null` | — |
| `purpose_justification_prompt` | `string` | `null` | — |
| `purpose_justification_required` | `bool` | `null` | — |
| `isolation_required` | `bool` | `null` | — |
| `connection_rules` | `object` | `null` | `rdp` clipboard rules: `allowed_clipboard_local_to_remote_formats`, `allowed_clipboard_remote_to_local_formats`. |
| `mfa_config` | `object` | `null` | `allowed_authenticators`, `mfa_disabled`, `session_duration`. |

### Condition objects (`include` / `exclude` / `require`)

Each is a set, and at most one condition per set element (the provider
enforces this shape). Conditions are written as objects; the three
all-match ones are empty objects — `everyone = {}`. Inner fields marked
**required** are required by the provider.

| Condition | Fields |
|---|---|
| `everyone` | `{}` |
| `any_valid_service_token` | `{}` |
| `certificate` | `{}` |
| `email` | `email` (required) |
| `email_domain` | `domain` (required) |
| `email_list` | `id` (required) |
| `group` | `id` (required) |
| `ip` | `ip` (required) |
| `ip_list` | `id` (required) |
| `geo` | `country_code` (required) |
| `login_method` | `id` (required) |
| `service_token` | `token_id` (required) |
| `auth_method` | `auth_method` (required) |
| `common_name` | `common_name` (required) |
| `auth_context` | `ac_id`, `id`, `identity_provider_id` (all required) |
| `azure_ad` | `id`, `identity_provider_id` (both required) |
| `github_organization` | `identity_provider_id`, `name` (required), `team` |
| `okta` | `identity_provider_id` (required), `name` (required) |
| `gsuite` | `email`, `identity_provider_id` (both required) |
| `saml` | `attribute_name`, `attribute_value`, `identity_provider_id` (all required) |
| `oidc` | `claim_name`, `claim_value`, `identity_provider_id` (all required) |
| `device_posture` | `integration_uid` (required) |
| `linked_app_token` | `app_uid` (required) |
| `external_evaluation` | `evaluate_url`, `keys_url` (both required) |
| `cloudflare_account_member` | `account_id` (optional) |
| `user_risk_score` | `user_risk_score` (required, list of strings) |

The module passes these through without conversion — the type mirrors the
provider shape exactly.

### `applications` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | `null` | Derived from the domain when omitted. |
| `type` | `string` | `null` | API default `self_hosted`; 14 upstream values. |
| `domain` | `string` | `null` | Primary hostname and path. |
| `session_duration` | `string` | `null` | — |
| `policies` | `list(string)` | `null` | Ordered policy keys — ascending precedence. |
| `allowed_idps` | `list(string)` | `null` | Identity-provider keys. |
| `tags` | `set(string)` | `null` | Also visible via the Zero Trust tag table upstream. |
| `app_launcher_visible` | `bool` | `null` | — |
| `skip_interstitial` | `bool` | `null` | Auto-login for non-interstitial flows. |
| `skip_app_launcher_login_page` | `bool` | `null` | — |
| `auto_redirect_to_identity` | `bool` | `null` | — |
| `allow_authenticate_via_warp` | `bool` | `null` | — |
| `allow_iframe` | `bool` | `null` | — |
| `service_auth_401_redirect` | `bool` | `null` | — |
| `options_preflight_bypass` | `bool` | `null` | — |
| `enable_binding_cookie` | `bool` | `null` | — |
| `http_only_cookie_attribute` | `bool` | `null` | — |
| `path_cookie_attribute` | `bool` | `null` | — |
| `same_site_cookie_attribute` | `string` | `null` | — |
| `read_service_tokens_from_header` | `string` | `null` | Read single-header service tokens under this header name. |
| `custom_deny_message`, `custom_deny_url`, `custom_non_identity_deny_url` | `string` | `null` | — |
| `custom_pages` | `list(string)` | `null` | Custom-page resource identifiers. |
| `logo_url` | `string` | `null` | Logo image URL in the App Launcher dashboard. |
| `bg_color`, `header_bg_color`, `app_launcher_logo_url` | `string` | `null` | Launcher branding — app_launcher-type apps only (the provider plan-validator rejects incompatible types). |
| `cors_headers` | `object` | `null` | `allow_all_headers`, `allow_all_methods`, `allow_all_origins`, `allow_credentials`, `allowed_headers`, `allowed_methods`, `allowed_origins`, `max_age`. |
| `landing_page_design` | `object` | `null` | `title`, `button_color`, `button_text_color`, `image_url`, `message`. |
| `footer_links` | `list(object)` | `null` | `name` (required), `url` (required). |
| `self_hosted_domains` | `set(string)` | `null` | Deprecated upstream in favor of `destinations` (supported until Nov 21 2025) and ignored when `destinations` is set — prefer `destinations`. |
| `destinations` | `list(object)` | `null` | Infrastructure-style destinations: `type`, `cidr`, `hostname`, `l4_protocol`, `mcp_server_id`, `port_range`, `uri`, `vnet_id`, `worker_id`. |
| `target_criteria` | `list(object)` | `null` | Infrastructure apps: `port`, `protocol`, `target_attributes` (all required). |

Deliberate exclusions (raw-resource escape hatch, one owner per app):
`saas_app` (a deep SaaS/OIDC/SAML shape — 23 attrs and 25 nested blocks
upstream), app-level `oauth_configuration`, `scim_config`, `mfa_config`,
and inline app policies — attach reusable policies by key instead; special
SaaS and SCIM flows belong in their own modules before they land here.

## Outputs

- `identity_provider_ids`, `policy_ids`, `application_ids`, `application_auds` — keyed by input key.

## Notes

- **Attach by key, not raw ID.** `applications[].policies` and
  `allowed_idps` list keys into the sibling maps; the resolved resource
  references create destroy-ordering edges — Cloudflare refuses to delete
  an identity provider or policy still attached to an app. Adopting
  pre-existing apps into this module also imports their policies and IdPs.
- **Order means precedence.** `applications[].policies` is an ordered
  list; the first policy applying to a session wins.
- **Type-compatibility is provider-validated at plan time.** Setting an
  attribute without a matching `type` (or unset `type`) fails before any
  API call. The verified matrix:
  - `app_launcher` only: `bg_color`, `header_bg_color`,
    `app_launcher_logo_url`, `landing_page_design`, `footer_links`,
    `skip_app_launcher_login_page`.
  - `self_hosted`, `ssh`, `vnc`, `rdp`, `mcp_portal`: `skip_interstitial`,
    `allow_iframe`, `cors_headers`, `options_preflight_bypass`,
    `same_site_cookie_attribute`, `service_auth_401_redirect`,
    `read_service_tokens_from_header`, `enable_binding_cookie`,
    `http_only_cookie_attribute`, `path_cookie_attribute`,
    `self_hosted_domains` (and `destinations`, which also accepts `mcp`).
  - `app_launcher_visible`: `self_hosted`, `ssh`, `vnc`, `rdp`, `saas`,
    `bookmark`.
  - `session_duration`: `self_hosted`, `ssh`, `vnc`, `rdp`, `saas`,
    `dash_sso`, `app_launcher`, `warp`, `mcp_portal`, `mcp`,
    `proxy_endpoint`.
  - `allow_authenticate_via_warp`: `self_hosted`, `ssh`, `vnc`, `rdp`,
    `saas`, `dash_sso`.
  - `target_criteria`: `rdp`, `infrastructure`.
- **Service flows**: reading IdPs with `client_secret` does not echo
  secrets here — the module outputs IDs only; the secret stays in its
  own input, landable in state for whoever has that config in hand.

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

identity_providers = {
  "azure" = {
    name = "example-azure-domain"
    type = "azureAD"
    config = {
      client_id     = "00000000-0000-0000-0000-000000000000"
      client_secret = "example-client-secret"
      directory_id  = "00000000-0000-0000-0000-000000000001"
      apps_domain   = "example.com"
    }
  }
}

policies = {
  "corp-access" = {
    name             = "example corporate access"
    decision         = "allow"
    session_duration = "24h"
    include = [
      { everyone = {} },
    ]
    require = [
      { group = { id = "00000000-0000-0000-0000-000000000002" } },
    ]
  }
  "downtime-bypass" = {
    name     = "example maintenance bypass"
    decision = "bypass"
    include = [
      { email = { email = "ops@example.com" } },
    ]
  }
}

applications = {
  "grafana" = {
    type             = "self_hosted"
    domain           = "grafana.example.com"
    session_duration = "12h"
    policies         = ["downtime-bypass", "corp-access"]
    allowed_idps     = ["azure"]
    skip_interstitial = true
  }
}
```

## Import

| Resource | Import ID |
|---|---|
| `cloudflare_zero_trust_access_application` | `<accounts>/<account_id>/<app_id>` |
| `cloudflare_zero_trust_access_policy` | `<account_id>/<policy_id>` |
| `cloudflare_zero_trust_access_identity_provider` | `<accounts>/<account_id>/<idp_id>` |
