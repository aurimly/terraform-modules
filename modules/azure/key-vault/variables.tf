variable "key_vaults" {
  description = "Map of Azure key vaults keyed by an arbitrary identifier. Each entry creates one azurerm_key_vault in the named resource group; vault names are unique across all of Azure since they are the vault URI's host. Nested keys, secrets and certificates wire into the vault resources this module creates itself."
  type = map(object({
    name                            = string
    resource_group_name             = string
    location                        = string
    tenant_id                       = string
    sku_name                        = optional(string, "standard")
    soft_delete_retention_days      = optional(number, 90)
    purge_protection_enabled        = optional(bool, false)
    rbac_authorization_enabled      = optional(bool, true)
    public_network_access_enabled   = optional(bool, true)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)
    network_acls = optional(object({
      bypass                     = optional(string, "AzureServices")
      default_action             = string
      ip_rules                   = optional(set(string), [])
      virtual_network_subnet_ids = optional(set(string), [])
    }))
    access_policies = optional(list(object({
      tenant_id               = string
      object_id               = string
      application_id          = optional(string)
      certificate_permissions = optional(list(string), [])
      key_permissions         = optional(list(string), [])
      secret_permissions      = optional(list(string), [])
      storage_permissions     = optional(list(string), [])
    })), [])
    keys = optional(map(object({
      name            = string
      key_type        = string
      key_size        = optional(number)
      curve           = optional(string)
      key_opts        = list(string)
      not_before_date = optional(string)
      expiration_date = optional(string)
      tags            = optional(map(string), {})
      rotation_policy = optional(object({
        expire_after         = optional(string)
        notify_before_expiry = optional(string)
        automatic = optional(object({
          time_after_creation = optional(string)
          time_before_expiry  = optional(string)
        }))
      }))
    })), {})
    secrets = optional(map(object({
      name             = string
      value            = optional(string)
      value_wo         = optional(string)
      value_wo_version = optional(number)
      content_type     = optional(string)
      not_before_date  = optional(string)
      expiration_date  = optional(string)
      tags             = optional(map(string), {})
    })), {})
    certificates = optional(map(object({
      name = string
      certificate = optional(object({
        contents = string
        password = optional(string)
      }))
      certificate_policy = optional(object({
        issuer_parameters = object({
          name = string
        })
        key_properties = object({
          exportable = bool
          key_type   = string
          key_size   = optional(number)
          curve      = optional(string)
          reuse_key  = bool
        })
        lifetime_action = optional(list(object({
          action = object({
            action_type = string
          })
          trigger = object({
            days_before_expiry  = optional(number)
            lifetime_percentage = optional(number)
          })
        })), [])
        secret_properties = object({
          content_type = string
        })
        x509_certificate_properties = optional(object({
          subject            = string
          validity_in_months = number
          key_usage          = list(string)
          extended_key_usage = optional(list(string))
          subject_alternative_names = optional(object({
            dns_names = optional(list(string))
            emails    = optional(list(string))
            upns      = optional(list(string))
          }))
        }))
      }))
      tags = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for vault in var.key_vaults : can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", vault.name)) && !can(regex("--", vault.name))
    ])
    error_message = "name must be 3–24 characters, start with a letter and use alphanumerics with single hyphens only — no leading/trailing or consecutive hyphens; it is the host of the vault's URI (<name>.vault.azure.net) and must be unique across all of Azure, which the module cannot check: a claimed name fails at apply."
  }

  validation {
    condition = alltrue(flatten([
      for key, vault in var.key_vaults : [
        for other_key, other in var.key_vaults :
        key == other_key || lower(vault.name) != lower(other.name)
      ]
    ]))
    error_message = "vault names must be unique across entries, case-insensitively — the vault URI host is case-insensitive, so two entries with the same name collide at the Azure API."
  }

  validation {
    condition = alltrue([
      for vault in var.key_vaults : length(trimspace(vault.name)) > 0 && length(trimspace(vault.resource_group_name)) > 0 && length(trimspace(vault.location)) > 0 && length(trimspace(vault.tenant_id)) > 0
    ])
    error_message = "name, resource_group_name, location and tenant_id must not be empty — tenant_id is the Entra ID tenant the vault's data-plane authorisation runs against (typically `data.azurerm_client_config.current.tenant_id`)."
  }

  validation {
    condition = alltrue([
      for vault in var.key_vaults : contains(["standard", "premium"], vault.sku_name)
    ])
    error_message = "sku_name must be \"standard\" or \"premium\" (lowercase) — premium is the SKU that carries HSM-backed key types (RSA-HSM, EC-HSM)."
  }

  validation {
    condition = alltrue([
      for vault in var.key_vaults : vault.soft_delete_retention_days >= 7 && vault.soft_delete_retention_days <= 90
    ])
    error_message = "soft_delete_retention_days must be between 7 and 90 — the soft-delete window is fixed for a vault's lifetime."
  }

  validation {
    condition = alltrue([
      for vault in var.key_vaults : vault.network_acls == null || (
        contains(["Allow", "Deny"], vault.network_acls.default_action)
        && contains(["AzureServices", "None"], vault.network_acls.bypass)
        && alltrue([for rule in vault.network_acls.ip_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/([0-9]|[12]?[0-9]|3[0-2]))?$", rule))])
        && alltrue([for id in vault.network_acls.virtual_network_subnet_ids : can(regex("^/", id))])
      )
    ])
    error_message = "network_acls, when set: default_action must be \"Allow\" or \"Deny\", bypass one of \"AzureServices\" or \"None\" (case-sensitive), ip_rules IPv4 CIDRs or bare IPv4 addresses (prefix 0–32), and virtual_network_subnet_ids full ARM subnet resource IDs (starting with \"/\")."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for policy in vault.access_policies : length(trimspace(policy.tenant_id)) > 0 && length(trimspace(policy.object_id)) > 0
      ]
    ]))
    error_message = "access_policies entries need non-empty tenant_id and object_id values — application_id only fits a first-party application's service principal."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for policy in vault.access_policies : alltrue([
          for permission in policy.certificate_permissions : contains(["backup", "create", "delete", "deleteissuers", "get", "getissuers", "import", "list", "listissuers", "managecontacts", "manageissuers", "purge", "recover", "restore", "setissuers", "update"], lower(permission))
        ])
      ]
    ]))
    error_message = "certificate_permissions names must come from the documented certificate set (lowercase): backup, create, delete, deleteissuers, get, getissuers, import, list, listissuers, managecontacts, manageissuers, purge, recover, restore, setissuers, update."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for policy in vault.access_policies : alltrue([
          for permission in policy.key_permissions : contains(["backup", "create", "decrypt", "delete", "encrypt", "get", "getrotationpolicy", "import", "list", "purge", "recover", "release", "restore", "rotate", "setrotationpolicy", "sign", "unwrapkey", "update", "verify", "wrapkey"], lower(permission))
        ])
      ]
    ]))
    error_message = "key_permissions names must come from the documented key set (lowercase): backup, create, decrypt, delete, encrypt, get, getrotationpolicy, import, list, purge, recover, release, restore, rotate, setrotationpolicy, sign, unwrapkey, update, verify, wrapkey."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for policy in vault.access_policies : alltrue([
          for permission in policy.secret_permissions : contains(["backup", "delete", "get", "list", "purge", "recover", "restore", "set"], lower(permission))
        ])
      ]
    ]))
    error_message = "secret_permissions names must come from the documented secret set (lowercase): backup, delete, get, list, purge, recover, restore, set."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for policy in vault.access_policies : alltrue([
          for permission in policy.storage_permissions : contains(["backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas", "update"], lower(permission))
        ])
      ]
    ]))
    error_message = "storage_permissions names must come from the documented storage set (lowercase): backup, delete, deletesas, get, getsas, list, listsas, purge, recover, regeneratekey, restore, set, setsas, update."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for tags in concat([vault.tags], [for key in vault.keys : key.tags], [for secret in vault.secrets : secret.tags], [for certificate in vault.certificates : certificate.tags]) :
        length(tags) <= 50 && alltrue([for tag_key, tag_value in tags : length(tag_key) <= 512 && length(tag_value) <= 256])
      ]
    ]))
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits) — checked on the vault and each key, secret and certificate."
  }

  validation {
    condition = alltrue(concat(
      [for vault_key in keys(var.key_vaults) : !can(regex("\\.", vault_key))],
      flatten([
        for vault in var.key_vaults : [
          for child_key in concat(keys(vault.keys), keys(vault.secrets), keys(vault.certificates)) : !can(regex("\\.", child_key))
        ]
      ])
    ))
    error_message = "map keys of key_vaults and its nested keys, secrets and certificates maps must not contain \".\" — vault keys are composed into child identifiers of the form \"<vault_key>.<child_key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for child_name in concat([for key in vault.keys : key.name], [for secret in vault.secrets : secret.name], [for certificate in vault.certificates : certificate.name]) :
        can(regex("^[a-zA-Z0-9-]{1,127}$", child_name))
      ]
    ]))
    error_message = "key, secret and certificate names must be 1–127 alphanumerics or hyphens (case-sensitive) — Key Vault object identifiers follow that pattern and are unique per vault per object type."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        length(distinct([for key in vault.keys : lower(key.name)])) == length(vault.keys),
        length(distinct([for secret in vault.secrets : lower(secret.name)])) == length(vault.secrets),
        length(distinct([for certificate in vault.certificates : lower(certificate.name)])) == length(vault.certificates)
      ]
    ]))
    error_message = "key, secret and certificate names must be unique within their vault per object type, case-insensitively — Key Vault rejects a second object of the same type under the same name."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for key in vault.keys : contains(["EC", "EC-HSM", "RSA", "RSA-HSM"], key.key_type)
        && (startswith(key.key_type, "RSA")
          ? key.curve == null && key.key_size != null && contains([2048, 3072, 4096], key.key_size)
        : key.key_size == null && key.curve != null && contains(["P-256", "P-256K", "P-384", "P-521"], key.curve))
      ]
    ]))
    error_message = "keys must pick a valid key_type (EC, EC-HSM, RSA, RSA-HSM) with the matching parameters — RSA and RSA-HSM take key_size (2048, 3072 or 4096) and no curve; EC and EC-HSM take curve (P-256, P-256K, P-384 or P-521) and no key_size."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for key in vault.keys : alltrue([
          for option in key.key_opts : contains(
            startswith(key.key_type, "RSA") ? ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"] : ["sign", "verify"],
            option
          )
        ])
      ]
    ]))
    error_message = "key_opts entries must fit the key's type — RSA and RSA-HSM support decrypt, encrypt, sign, unwrapKey, verify and wrapKey; EC and EC-HSM support sign and verify only (Azure rejects the unsupported ones at key creation)."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for key in vault.keys : (key.not_before_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", key.not_before_date)))
        && (key.expiration_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", key.expiration_date)))
      ]
    ]))
    error_message = "keys' not_before_date and expiration_date must be Z-form UTC timestamps (\"2026-01-02T03:04:05Z\") — the provider accepts RFC 3339 with offsets too, but the module validates the Z-form only."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for key in vault.keys : key.rotation_policy == null || (
          (key.rotation_policy.expire_after != null) == (key.rotation_policy.notify_before_expiry != null)
          && (key.rotation_policy.automatic == null || key.rotation_policy.automatic != null && (key.rotation_policy.automatic.time_after_creation != null || key.rotation_policy.automatic.time_before_expiry != null))
        )
      ]
    ]))
    error_message = "rotation_policy pairs expire_after and notify_before_expiry (both set or both unset — the provider requires both together) and automatic, when set, needs at least one of time_after_creation or time_before_expiry."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for secret in vault.secrets : (secret.value != null) != (secret.value_wo != null)
        && (secret.value_wo == null || (secret.value_wo_version != null && secret.value_wo_version >= 1))
      ]
    ]))
    error_message = "each secret must set exactly one of value or value_wo; value_wo — the write-only, state-free variant — requires value_wo_version ≥ 1, and bumping value_wo_version rotates the secret value."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for secret in vault.secrets : (secret.not_before_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", secret.not_before_date)))
        && (secret.expiration_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", secret.expiration_date)))
      ]
    ]))
    error_message = "secrets' not_before_date and expiration_date must be Z-form UTC timestamps (\"2026-01-02T03:04:05Z\") — the provider accepts RFC 3339 with offsets too, but the module validates the Z-form only."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for certificate in vault.certificates : (certificate.certificate != null || certificate.certificate_policy != null)
        && (certificate.certificate == null || length(trimspace(certificate.certificate.contents)) > 0)
      ]
    ]))
    error_message = "each certificate needs at least one of certificate (import: a base64 PFX or a PEM/PKCS8 bundle in contents) or certificate_policy (generate) — the provider requires at least one and accepts both together (import with an applied policy), and a set contents must be non-empty."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for certificate in vault.certificates : certificate.certificate_policy == null || certificate.certificate_policy != null && certificate.certificate_policy.secret_properties.content_type != null && contains(["application/x-pkcs12", "application/x-pem-file"], certificate.certificate_policy.secret_properties.content_type)
      ]
    ]))
    error_message = "certificate_policy's secret_properties.content_type must be \"application/x-pkcs12\" or \"application/x-pem-file\" (case-sensitive) — those are the encodings the certificate generate path accepts."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for certificate in vault.certificates : certificate.certificate_policy == null || contains(["EC", "EC-HSM", "RSA", "RSA-HSM", "oct"], certificate.certificate_policy.key_properties.key_type)
      ]
    ]))
    error_message = "certificate_policy key_properties.key_type must be one of EC, EC-HSM, RSA, RSA-HSM or oct (per the provider docs)."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for certificate in vault.certificates : certificate.certificate_policy == null ? true : (
          startswith(certificate.certificate_policy.key_properties.key_type, "RSA")
          ? contains([2048, 3072, 4096], certificate.certificate_policy.key_properties.key_size) && certificate.certificate_policy.key_properties.curve == null
          : certificate.certificate_policy.key_properties.key_size == null && (startswith(certificate.certificate_policy.key_properties.key_type, "EC") ? contains(["P-256", "P-256K", "P-384", "P-521"], certificate.certificate_policy.key_properties.curve) : true)
        )
      ]
    ]))
    error_message = "certificate_policy key_properties must fit the key_type — RSA and RSA-HSM take key_size (2048, 3072 or 4096) and no curve; EC and EC-HSM take curve (P-256, P-256K, P-384 or P-521 — the provider errors when curve is missing) and no key_size; oct keys take neither (their size is fixed to 256 bits)."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for certificate in vault.certificates : certificate.certificate_policy == null || length(certificate.certificate_policy.lifetime_action) == 0 || alltrue([
          for entry in certificate.certificate_policy.lifetime_action :
          entry.action != null && entry.trigger != null
          && (entry.trigger.days_before_expiry != null) != (entry.trigger.lifetime_percentage != null)
          && contains(["AutoRenew", "EmailContacts"], entry.action.action_type)
        ])
      ]
    ]))
    error_message = "entries of certificate_policy.lifetime_action need an action (action_type \"AutoRenew\" or \"EmailContacts\") and a trigger object with exactly one of days_before_expiry or lifetime_percentage set."
  }

  validation {
    condition = alltrue(flatten([
      for vault in var.key_vaults : [
        for certificate in vault.certificates : certificate.certificate_policy == null || certificate.certificate_policy.x509_certificate_properties == null || (
          length(trimspace(certificate.certificate_policy.x509_certificate_properties.subject)) > 0
          && certificate.certificate_policy.x509_certificate_properties.validity_in_months > 0
          && alltrue([
            for usage in certificate.certificate_policy.x509_certificate_properties.key_usage : contains(["cRLSign", "dataEncipherment", "decipherOnly", "digitalSignature", "encipherOnly", "keyAgreement", "keyCertSign", "keyEncipherment", "nonRepudiation"], usage)
          ])
        )
      ]
    ]))
    error_message = "certificate_policy x509_certificate_properties, when set: subject must be non-empty, validity_in_months > 0, and key_usage a subset of the documented set — cRLSign, dataEncipherment, decipherOnly, digitalSignature, encipherOnly, keyAgreement, keyCertSign, keyEncipherment or nonRepudiation."
  }
}
