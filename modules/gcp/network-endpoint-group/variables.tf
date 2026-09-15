variable "negs" {
  description = "Map of zonal network endpoint groups keyed by an arbitrary identifier. Zonal NEG types cover GCE VM endpoints and hybrid non-GCP endpoints; serverless and internet NEGs are regional (see the regional_negs variable)."
  type = map(object({
    name                  = string
    zone                  = optional(string)
    project_id            = optional(string)
    network               = string
    subnetwork            = optional(string)
    default_port          = optional(number)
    network_endpoint_type = optional(string, "GCE_VM_IP_PORT")
    description           = optional(string)
    deletion_policy       = optional(string)
  }))

  validation {
    condition     = alltrue([for k, g in var.negs : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", g.name))])
    error_message = "negs.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, g in var.negs : g.zone == null || can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", g.zone))])
    error_message = "negs.zone must be a GCP zone (e.g. us-central1-a); omit it to use the provider-level zone (also inherited by referencing endpoints)."
  }

  validation {
    condition     = alltrue([for k, g in var.negs : g.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", g.project_id))])
    error_message = "negs.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, g in var.negs : contains(["GCE_VM_IP", "GCE_VM_IP_PORT", "NON_GCP_PRIVATE_IP_PORT", "INTERNET_IP_PORT", "INTERNET_FQDN_PORT", "SERVERLESS", "PRIVATE_SERVICE_CONNECT", "GCE_VM_IP_DEDICATED_BACKEND"], g.network_endpoint_type)])
    error_message = "negs.network_endpoint_type must be one of GCE_VM_IP, GCE_VM_IP_PORT, NON_GCP_PRIVATE_IP_PORT, INTERNET_IP_PORT, INTERNET_FQDN_PORT, SERVERLESS, PRIVATE_SERVICE_CONNECT or GCE_VM_IP_DEDICATED_BACKEND (case-sensitive); regional-only types (SERVERLESS, INTERNET_*) live on the regional_negs variable in practice."
  }

  validation {
    condition     = alltrue([for k, g in var.negs : (g.default_port == null || g.default_port >= 0) && (g.default_port == null || g.default_port <= 65535)])
    error_message = "negs.default_port must be between 0 and 65535; it is used for endpoints that omit port."
  }

  validation {
    condition     = alltrue([for k, g in var.negs : g.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], g.deletion_policy)])
    error_message = "negs.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}

variable "regional_negs" {
  description = "Map of regional network endpoint groups keyed by an arbitrary identifier: serverless (Cloud Run, App Engine, Cloud Functions), Private Service Connect and internet NEG types."
  type = map(object({
    name                  = string
    region                = string
    project_id            = optional(string)
    network               = optional(string)
    subnetwork            = optional(string)
    network_endpoint_type = optional(string, "SERVERLESS")
    psc_target_service    = optional(string)
    psc_data = optional(object({
      producer_port = optional(number)
    }))
    cloud_run = optional(object({
      service  = optional(string)
      tag      = optional(string)
      url_mask = optional(string)
    }))
    app_engine = optional(object({
      service  = optional(string)
      version  = optional(string)
      url_mask = optional(string)
    }))
    cloud_function = optional(object({
      function = optional(string)
      url_mask = optional(string)
    }))
    description     = optional(string)
    deletion_policy = optional(string)
  }))

  validation {
    condition     = alltrue([for k, g in var.regional_negs : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", g.name))])
    error_message = "regional_negs.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, g in var.regional_negs : can(regex("^[a-z]+-[a-z]+[0-9]+$", g.region))])
    error_message = "regional_negs.region must be a GCP region (e.g. us-central1)."
  }

  validation {
    condition     = alltrue([for k, g in var.regional_negs : g.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", g.project_id))])
    error_message = "regional_negs.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, g in var.regional_negs : contains(["SERVERLESS", "PRIVATE_SERVICE_CONNECT", "INTERNET_IP_PORT", "INTERNET_FQDN_PORT"], g.network_endpoint_type)])
    error_message = "regional_negs.network_endpoint_type must be one of SERVERLESS, PRIVATE_SERVICE_CONNECT, INTERNET_IP_PORT or INTERNET_FQDN_PORT (case-sensitive); GCE and hybrid types live on the zonal negs variable."
  }

  validation {
    condition = alltrue([
      for k, g in var.regional_negs : alltrue([
        length([for b in [g.cloud_run, g.app_engine, g.cloud_function] : b if b != null]) == 1,
      ]) if g.network_endpoint_type == "SERVERLESS"
    ])
    error_message = "regional SERVERLESS NEG must set exactly one of cloud_run, app_engine or cloud_function."
  }

  validation {
    condition = alltrue([
      for k, g in var.regional_negs : g.network_endpoint_type == "SERVERLESS" || alltrue([
        g.cloud_run == null,
        g.app_engine == null,
        g.cloud_function == null,
      ])
    ])
    error_message = "regional_negs cloud_run, app_engine and cloud_function are SERVERLESS-only blocks."
  }

  validation {
    condition = alltrue([
      for k, g in var.regional_negs : alltrue([
        contains(["PRIVATE_SERVICE_CONNECT", "INTERNET_IP_PORT", "INTERNET_FQDN_PORT"], g.network_endpoint_type) || g.psc_target_service == null,
        g.network_endpoint_type == "PRIVATE_SERVICE_CONNECT" || (g.psc_data == null && g.subnetwork == null),
      ])
    ])
    error_message = "regional_negs.psc_target_service is a PSC and INTERNET NEG field; psc_data and subnetwork are PRIVATE_SERVICE_CONNECT-only."
  }

  validation {
    condition     = alltrue([for k, g in var.regional_negs : g.network_endpoint_type != "PRIVATE_SERVICE_CONNECT" || g.psc_target_service != null])
    error_message = "regional_negs.psc_target_service is required for PRIVATE_SERVICE_CONNECT NEGs."
  }

  validation {
    condition     = alltrue([for k, g in var.regional_negs : !(can(regex("^INTERNET_", g.network_endpoint_type)) && g.network == null)])
    error_message = "regional_negs.network is required for INTERNET_IP_PORT and INTERNET_FQDN_PORT NEGs; an implicit-default-network internet NEG is almost always a misconfiguration."
  }

  validation {
    condition     = alltrue([for k, g in var.regional_negs : g.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], g.deletion_policy)])
    error_message = "regional_negs.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}

variable "endpoints" {
  description = "Map of endpoints inside the zonal negs created by this module, keyed by an arbitrary identifier; each entry resolves its neg key to the referenced NEG."
  type = map(object({
    neg             = string
    ip_address      = string
    port            = optional(number)
    instance        = optional(string)
    project_id      = optional(string)
    deletion_policy = optional(string)
  }))

  validation {
    condition     = alltrue([for k, e in var.endpoints : contains(keys(var.negs), e.neg)])
    error_message = "endpoints.neg must be a key present in the negs variable; endpoints are attached to the referenced zonal NEG."
  }

  validation {
    condition     = alltrue([for k, e in var.endpoints : e.port != null || var.negs[e.neg].network_endpoint_type == "GCE_VM_IP"])
    error_message = "endpoints.port is required for GCE_VM_IP_PORT NEGs (GCE_VM_IP is the only type that does not need it)."
  }

  validation {
    condition     = alltrue([for k, e in var.endpoints : var.negs[e.neg].network_endpoint_type != "GCE_VM_IP_PORT" || e.instance != null])
    error_message = "endpoints.instance is required for GCE_VM_IP_PORT endpoints; the instance must be in the NEG's zone."
  }

  validation {
    condition     = alltrue([for k, e in var.endpoints : e.port == null || (e.port >= 0 && e.port <= 65535)])
    error_message = "endpoints.port must be between 0 and 65535 (required for GCE_VM_IP_PORT endpoints)."
  }

  validation {
    condition     = alltrue([for k, e in var.endpoints : contains(["GCE_VM_IP", "GCE_VM_IP_PORT", "NON_GCP_PRIVATE_IP_PORT", "GCE_VM_IP_DEDICATED_BACKEND"], var.negs[e.neg].network_endpoint_type)])
    error_message = "endpoints are supported only on NEG types GCE_VM_IP, GCE_VM_IP_PORT, NON_GCP_PRIVATE_IP_PORT and GCE_VM_IP_DEDICATED_BACKEND; SERVERLESS, INTERNET and PRIVATE_SERVICE_CONNECT NEGs reject endpoint creation."
  }

  validation {
    condition     = alltrue([for k, e in var.endpoints : e.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", e.project_id))])
    error_message = "endpoints.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, e in var.endpoints : e.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], e.deletion_policy)])
    error_message = "endpoints.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}
