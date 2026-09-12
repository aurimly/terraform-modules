variable "redirects" {
  description = "Map of NS1 URL redirects keyed by an arbitrary unique identifier. The domain/path pair must be unique within the NS1 account."
  type = map(object({
    domain           = string
    target           = string
    path             = optional(string, "/")
    forwarding_type  = optional(string, "permanent")
    forwarding_mode  = optional(string, "all")
    https_forced     = optional(bool, false)
    query_forwarding = optional(bool, false)
    tags             = optional(set(string), [])
    certificate_id   = optional(string)
  }))

  validation {
    condition = alltrue([
      for r in var.redirects : contains(["permanent", "temporary", "masking"], r.forwarding_type)
    ])
    error_message = "forwarding_type must be one of permanent, temporary, masking."
  }
}
