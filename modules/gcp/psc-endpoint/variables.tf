variable "psc_endpoints" {
  description = "Map of Private Service Connect consumer endpoints keyed by an arbitrary identifier. Each entry creates one internal google_compute_address and one google_compute_forwarding_rule targeting a producer service attachment."
  type = map(object({
    name                      = string
    project_id                = optional(string)
    region                    = string
    network                   = string
    subnetwork                = string
    target_service_attachment = string
    address                   = optional(string)
    address_name              = optional(string)
    description               = optional(string)
    allow_psc_global_access   = optional(bool, false)
    recreate_closed_psc       = optional(bool)
    no_automate_dns_zone      = optional(bool)
    labels                    = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for k, ep in var.psc_endpoints : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", ep.name))])
    error_message = "name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, ep in var.psc_endpoints : ep.address_name != null || length(ep.name) <= 60])
    error_message = "name must be at most 60 characters when address_name is unset, because the reserved IP address is named \"<name>-ip\" and address names are capped at 63 characters."
  }

  validation {
    condition     = alltrue([for k, ep in var.psc_endpoints : ep.address_name == null || can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", ep.address_name))])
    error_message = "address_name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, ep in var.psc_endpoints : can(regex("^[a-z]+-[a-z]+[0-9]+$", ep.region))])
    error_message = "region must be a valid GCP region name (e.g. europe-west1)."
  }

  validation {
    condition     = alltrue([for k, ep in var.psc_endpoints : length(ep.target_service_attachment) > 0])
    error_message = "target_service_attachment must be set to the producer service attachment self link (e.g. projects/<p>/regions/<r>/serviceAttachments/<name>)."
  }
}
