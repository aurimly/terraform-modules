variable "certificates" {
  description = "Map of Origin CA certificates keyed by an arbitrary unique identifier. Requires Origin CA key authentication — API tokens do not work for these endpoints (see README)."
  type = map(object({
    csr                = string
    hostnames          = list(string)
    request_type       = string
    requested_validity = optional(number)
  }))

  validation {
    condition = alltrue([
      for c in var.certificates : c.request_type == "origin-rsa" || c.request_type == "origin-ecc" || c.request_type == "keyless-certificate"
    ])
    error_message = "request_type must be one of: origin-rsa, origin-ecc, keyless-certificate. Changing it replaces the certificate."
  }

  validation {
    condition = alltrue([
      for c in var.certificates : c.requested_validity == null || contains([7, 30, 90, 365, 730, 1095, 5475], c.requested_validity)
    ])
    error_message = "requested_validity must be one of 7, 30, 90, 365, 730, 1095, 5475 days. Changing it replaces the certificate."
  }
}
