variable "key_pairs" {
  description = "Map of STACKIT SSH key pairs keyed by an arbitrary identifier. Each entry uploads one public key."
  type = map(object({
    name       = string
    public_key = string
    labels     = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for kp in var.key_pairs : length(kp.name) >= 1 && !can(regex(",", kp.name))])
    error_message = "name must be non-empty and must not contain a comma (the key pair import ID is the bare name)."
  }

  validation {
    condition     = alltrue([for kp in var.key_pairs : can(regex("^(ssh-(rsa|dss|ed25519)|ecdsa-sha2-nistp(256|384|521))\\s", kp.public_key))])
    error_message = "public_key must start with a known SSH key type: ssh-rsa, ssh-dss, ssh-ed25519 or ecdsa-sha2-nistp256/384/521, followed by whitespace and the key material."
  }

  validation {
    condition     = alltrue([for kp in var.key_pairs : alltrue([for k, v in kp.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }
}
