variable "service_account_keys" {
  description = "Map of service account keys keyed by an arbitrary identifier. Each entry creates one google_service_account_key for an existing service account — the module does not create accounts (pair with gcp/service-account)."
  type = map(object({
    service_account  = string
    key_algorithm    = optional(string)
    public_key_type  = optional(string)
    private_key_type = optional(string)
    public_key_data  = optional(string)
    keepers          = optional(map(string))
    deletion_policy  = optional(string, "DELETE")
  }))

  validation {
    condition = alltrue([
      for k in var.service_account_keys :
      can(regex("^[^@/]+@[^/]+\\.iam\\.gserviceaccount\\.com$", k.service_account)) || can(regex("^projects/[^/]+/serviceAccounts/[^/]+$", k.service_account))
    ])
    error_message = "service_account must be the account's email (name@project.iam.gserviceaccount.com) or its resource name (projects/{project}/serviceAccounts/{email-or-unique-id}); it is a shape check — the API also accepts a bare account id with the project inferred, and \"-\" as the project wildcard."
  }

  validation {
    condition     = alltrue([for k in var.service_account_keys : k.key_algorithm == null || contains(["KEY_ALG_RSA_1024", "KEY_ALG_RSA_2048"], k.key_algorithm)])
    error_message = "key_algorithm must be one of KEY_ALG_RSA_1024 or KEY_ALG_RSA_2048 (KEY_ALG_RSA_2048 is the upstream default)."
  }

  validation {
    condition     = alltrue([for k in var.service_account_keys : k.public_key_type == null || contains(["TYPE_X509_PEM_FILE", "TYPE_RAW_PUBLIC_KEY"], k.public_key_type)])
    error_message = "public_key_type must be one of TYPE_X509_PEM_FILE or TYPE_RAW_PUBLIC_KEY (TYPE_X509_PEM_FILE is the upstream default)."
  }

  validation {
    condition     = alltrue([for k in var.service_account_keys : k.private_key_type == null || contains(["TYPE_GOOGLE_CREDENTIALS_FILE", "TYPE_PKCS12_FILE"], k.private_key_type)])
    error_message = "private_key_type must be one of TYPE_GOOGLE_CREDENTIALS_FILE or TYPE_PKCS12_FILE (TYPE_GOOGLE_CREDENTIALS_FILE is the upstream default)."
  }

  validation {
    condition     = alltrue([for k in var.service_account_keys : k.public_key_data == null || (k.key_algorithm == null && k.private_key_type == null)])
    error_message = "public_key_data conflicts with key_algorithm and private_key_type — bring-your-own-key entries must leave both unset."
  }

  validation {
    condition     = alltrue([for k in var.service_account_keys : k.public_key_data == null || can(base64decode(k.public_key_data))])
    error_message = "public_key_data must be base64-decodable — the API expects a base64-encoded X509 PEM."
  }

  validation {
    condition     = alltrue([for k in var.service_account_keys : contains(["DELETE", "ABANDON", "PREVENT"], k.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }
}
