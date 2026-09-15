variable "keys" {
  description = "Map of STACKIT KMS keys keyed by an arbitrary identifier. Each entry creates one key in the given keyring. Keys are scheduled for deletion on destroy (not instantly removed) — see the module README."
  type = map(object({
    project_id   = string
    keyring_id   = string
    display_name = string
    algorithm    = string
    protection   = string
    purpose      = string
    access_scope = optional(string)
    description  = optional(string)
    import_only  = optional(bool)
    region       = optional(string)
  }))

  validation {
    condition     = alltrue([for k in var.keys : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", k.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", k.keyring_id))])
    error_message = "project_id and keyring_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for k in var.keys : length(k.display_name) >= 1])
    error_message = "display_name must be at least 1 character."
  }

  validation {
    condition     = alltrue([for k in var.keys : contains(["aes_256_gcm", "rsa_2048_oaep_sha256", "rsa_3072_oaep_sha256", "rsa_4096_oaep_sha256", "rsa_4096_oaep_sha512", "hmac_sha256", "hmac_sha384", "hmac_sha512", "ecdsa_p256_sha256", "ecdsa_p384_sha384", "ecdsa_p521_sha512"], k.algorithm)])
    error_message = "algorithm must be one of aes_256_gcm, rsa_2048_oaep_sha256, rsa_3072_oaep_sha256, rsa_4096_oaep_sha256, rsa_4096_oaep_sha512, hmac_sha256, hmac_sha384, hmac_sha512, ecdsa_p256_sha256, ecdsa_p384_sha384, ecdsa_p521_sha512."
  }

  validation {
    condition     = alltrue([for k in var.keys : length(k.protection) >= 1])
    error_message = "protection must be at least 1 character (the value is not enumerated by the provider; e.g. software)."
  }

  validation {
    condition     = alltrue([for k in var.keys : contains(["symmetric_encrypt_decrypt", "asymmetric_encrypt_decrypt", "message_authentication_code", "asymmetric_sign_verify"], k.purpose)])
    error_message = "purpose must be one of symmetric_encrypt_decrypt, asymmetric_encrypt_decrypt, message_authentication_code, asymmetric_sign_verify."
  }

  validation {
    condition     = alltrue([for k in var.keys : k.access_scope == null || contains(["PUBLIC", "SNA"], k.access_scope)])
    error_message = "access_scope must be one of PUBLIC or SNA."
  }
}
