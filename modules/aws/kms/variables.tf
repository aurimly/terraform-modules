variable "keys" {
  description = "Map of KMS keys keyed by an arbitrary identifier. Each entry creates one aws_kms_key plus optional aliases."
  type = map(object({
    description                        = optional(string)
    key_usage                          = optional(string, "ENCRYPT_DECRYPT")
    customer_master_key_spec           = optional(string, "SYMMETRIC_DEFAULT")
    is_enabled                         = optional(bool, true)
    enable_key_rotation                = optional(bool, false)
    rotation_period_in_days            = optional(number)
    deletion_window_in_days            = optional(number, 30)
    multi_region                       = optional(bool, false)
    policy                             = optional(string)
    bypass_policy_lockout_safety_check = optional(bool, false)
    aliases = optional(map(object({
      name = string
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.keys) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (alias resource addresses and composite output keys are composed from key and alias keys)."
  }

  validation {
    condition     = alltrue([for k in var.keys : contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY", "GENERATE_VERIFY_MAC", "KEY_AGREEMENT"], k.key_usage)])
    error_message = "key_usage must be one of ENCRYPT_DECRYPT, SIGN_VERIFY, GENERATE_VERIFY_MAC or KEY_AGREEMENT (case-sensitive). HMAC specs require GENERATE_VERIFY_MAC; KEY_AGREEMENT applies to NIST-curve ECC keys."
  }

  validation {
    condition     = alltrue([for k in var.keys : contains(["SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "ECC_NIST_EDWARDS25519", "ML_DSA_44", "ML_DSA_65", "ML_DSA_87"], k.customer_master_key_spec)])
    error_message = "customer_master_key_spec must be one of SYMMETRIC_DEFAULT, HMAC_224/256/384/512, RSA_2048/3072/4096, ECC_NIST_P256/P384/P521, ECC_SECG_P256K1, ECC_NIST_EDWARDS25519 or ML_DSA_44/65/87 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k in var.keys : !k.enable_key_rotation || k.customer_master_key_spec == "SYMMETRIC_DEFAULT"])
    error_message = "enable_key_rotation only applies to symmetric encryption keys (SYMMETRIC_DEFAULT) — AWS does not rotate asymmetric, HMAC or custom-store keys."
  }

  validation {
    condition     = alltrue([for k in var.keys : k.rotation_period_in_days == null || (k.enable_key_rotation && k.customer_master_key_spec == "SYMMETRIC_DEFAULT")])
    error_message = "rotation_period_in_days requires enable_key_rotation = true on a SYMMETRIC_DEFAULT key (rotation is symmetric-only; the API rejects a rotation period without rotation enabled)."
  }

  validation {
    condition     = alltrue([for k in var.keys : k.rotation_period_in_days == null || (k.rotation_period_in_days >= 90 && k.rotation_period_in_days <= 2560)])
    error_message = "rotation_period_in_days must be between 90 and 2560 days (KMS rotation period range)."
  }

  validation {
    condition     = alltrue([for k in var.keys : k.deletion_window_in_days >= 7 && k.deletion_window_in_days <= 30])
    error_message = "deletion_window_in_days must be between 7 and 30 days (AWS limits)."
  }

  validation {
    condition     = alltrue([for k in var.keys : k.policy == null || can(jsondecode(k.policy))])
    error_message = "policy must be a valid JSON policy document."
  }

  validation {
    condition     = alltrue([for k in var.keys : alltrue([for a in k.aliases : can(regex("^alias/[a-zA-Z0-9/_-]{1,250}$", a.name))])])
    error_message = "aliases.name must be alias/ followed by 1-250 characters of alphanumerics, forward slashes, underscores and hyphens (KMS alias naming rules)."
  }

  validation {
    condition     = alltrue([for k in var.keys : alltrue([for a in k.aliases : !can(regex("^alias/aws/", a.name))])])
    error_message = "aliases.name must not start with alias/aws/ (reserved for AWS-managed aliases)."
  }

  validation {
    condition     = alltrue([for k in var.keys : alltrue([for a in keys(k.aliases) : can(regex("^[^.]+$", a))])])
    error_message = "aliases map keys must not contain '.' (composite output keys are composed from key and alias keys)."
  }

  validation {
    condition     = length(distinct(flatten([for k in var.keys : [for a in k.aliases : a.name]]))) == length(flatten([for k in var.keys : [for a in k.aliases : a.name]]))
    error_message = "aliases.name must be unique across all key entries (KMS aliases are region-unique; the API rejects duplicates)."
  }
}
