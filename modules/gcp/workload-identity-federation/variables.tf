variable "pools" {
  description = "Map of Workload Identity Federation pools keyed by an arbitrary identifier. Each entry creates one google_iam_workload_identity_pool plus optional nested providers and service account token-creator grants."
  type = map(object({
    pool_id         = string
    project_id      = optional(string)
    display_name    = optional(string)
    description     = optional(string)
    disabled        = optional(bool, false)
    mode            = optional(string)
    deletion_policy = optional(string)

    providers = optional(map(object({
      provider_id     = string
      display_name    = optional(string)
      description     = optional(string)
      disabled        = optional(bool, false)
      deletion_policy = optional(string)

      attribute_condition = optional(string)
      attribute_mapping   = optional(map(string))

      oidc = optional(object({
        issuer_uri        = string
        allowed_audiences = optional(list(string))
        jwks_json         = optional(string)
      }))
      saml = optional(object({
        idp_metadata_xml = string
      }))
      aws = optional(object({
        account_id = string
      }))
      x509 = optional(object({
        trust_store = object({
          trust_anchors = list(object({
            pem_certificate = string
          }))
          intermediate_cas = optional(list(object({
            pem_certificate = string
          })))
        })
      }))

      token_creators = optional(map(object({
        service_account = string
        member          = string
      })), {})
    })), {})
  }))

  validation {
    condition     = alltrue([for p in var.pools : can(regex("^[a-z][a-z0-9-]{2,30}[a-z0-9]$", p.pool_id))])
    error_message = "pool_id must be 4 to 32 lowercase letters, digits or hyphens, starting and ending with a letter or digit (Workload Identity Pool naming rules)."
  }

  validation {
    condition     = alltrue([for p in var.pools : !startswith(p.pool_id, "gcp-")])
    error_message = "pool_id must not start with the reserved gcp- prefix; that prefix is reserved for Google."
  }

  validation {
    condition     = alltrue([for p in var.pools : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for p in var.pools : p.mode == null || contains(["FEDERATION_ONLY", "TRUST_DOMAIN", "SYSTEM_TRUST_DOMAIN"], p.mode)])
    error_message = "mode must be one of FEDERATION_ONLY, TRUST_DOMAIN or SYSTEM_TRUST_DOMAIN (case-sensitive); unset defaults to FEDERATION_ONLY. Immutable after creation."
  }

  validation {
    condition     = alltrue([for p in var.pools : p.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], p.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : can(regex("^[a-z][a-z0-9-]{2,30}[a-z0-9]$", q.provider_id))
      ])
    ])
    error_message = "providers.provider_id must be 4 to 32 lowercase letters, digits or hyphens, starting and ending with a letter or digit (Workload Identity Pool provider naming rules)."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : !startswith(q.provider_id, "gcp-")
      ])
    ])
    error_message = "providers.provider_id must not start with the reserved gcp- prefix; that prefix is reserved for Google."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : length([for v in [q.oidc != null, q.saml != null, q.aws != null, q.x509 != null] : v if v]) == 1
      ])
    ])
    error_message = "providers require exactly one of oidc, saml, aws or x509; each provider federates one protocol."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : q.oidc == null || (q.oidc.issuer_uri == null || q.oidc.issuer_uri == "" || can(regex("^https://[^\\s]+$", q.oidc.issuer_uri)))
      ])
    ])
    error_message = "providers.oidc.issuer_uri is required (the provider rejects jwks_json-only configs) and must be an HTTPS URL."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : q.saml == null || length(q.saml.idp_metadata_xml) > 0
      ])
    ])
    error_message = "providers.saml.idp_metadata_xml must be non-empty."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : q.aws == null || can(regex("^[0-9]{12}$", q.aws.account_id))
      ])
    ])
    error_message = "providers.aws.account_id must be a 12-digit AWS account ID."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : q.x509 == null || length(q.x509.trust_store.trust_anchors) > 0
      ])
    ])
    error_message = "providers.x509.trust_store.trust_anchors requires at least one trust anchor."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : q.attribute_condition == null || length(q.attribute_condition) > 0
      ])
    ])
    error_message = "providers.attribute_condition must be a non-empty CEL expression."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : q.oidc == null || q.attribute_mapping == null || contains(keys(q.attribute_mapping), "google.subject")
      ])
    ])
    error_message = "providers.attribute_mapping must include the local key google.subject for OIDC providers; the API rejects mappings without it."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : alltrue([
          for c in q.token_creators : can(regex("^(principalSet|principal)://iam\\.googleapis\\.com/", c.member))
        ])
      ])
    ])
    error_message = "token_creators.member must be a WIF principal URI (principal://iam.googleapis.com/... or principalSet://iam.googleapis.com/...)."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : alltrue([
          for c in q.token_creators : can(regex("^[^@\\s]+@[^@\\s]+\\.iam\\.gserviceaccount\\.com$", c.service_account)) || can(regex("^projects/[^/]+/serviceAccounts/[^@\\s]+@[^@\\s]+\\.iam\\.gserviceaccount\\.com$", c.service_account))
        ])
      ])
    ])
    error_message = "token_creators.service_account must be a service account email or a fully-qualified name (projects/{project}/serviceAccounts/{email})."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for k in keys(p.providers) : length(k) > 0
      ])
    ])
    error_message = "providers keys must be non-empty."
  }

  validation {
    condition = alltrue([
      for p in var.pools : alltrue([
        for q in p.providers : alltrue([
          for k in keys(q.token_creators) : length(k) > 0
        ])
      ])
    ])
    error_message = "token_creators keys must be non-empty."
  }
}
