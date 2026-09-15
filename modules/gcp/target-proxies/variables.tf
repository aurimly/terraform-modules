variable "tcp_proxies" {
  description = "Map of global target TCP proxies keyed by an arbitrary identifier."
  type = map(object({
    name            = string
    backend_service = string
    project_id      = optional(string)
    proxy_header    = optional(string)
    description     = optional(string)
    deletion_policy = optional(string)
  }))

  validation {
    condition     = alltrue([for k, p in var.tcp_proxies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "tcp_proxies.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.tcp_proxies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "tcp_proxies.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, p in var.tcp_proxies : p.backend_service != null && p.backend_service != ""])
    error_message = "tcp_proxies.backend_service is required: the backend service self link (e.g. from gcp/load-balancer backend_service_self_links)."
  }

  validation {
    condition     = alltrue([for k, p in var.tcp_proxies : p.proxy_header == null || contains(["NONE", "PROXY_V1"], p.proxy_header)])
    error_message = "tcp_proxies.proxy_header must be NONE or PROXY_V1 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.tcp_proxies : p.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], p.deletion_policy)])
    error_message = "tcp_proxies.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}

variable "regional_tcp_proxies" {
  description = "Map of regional target TCP proxies keyed by an arbitrary identifier."
  type = map(object({
    name            = string
    backend_service = string
    region          = string
    project_id      = optional(string)
    proxy_header    = optional(string)
    description     = optional(string)
    deletion_policy = optional(string)
  }))

  validation {
    condition     = alltrue([for k, p in var.regional_tcp_proxies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "regional_tcp_proxies.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_tcp_proxies : can(regex("^[a-z]+-[a-z]+[0-9]+$", p.region))])
    error_message = "regional_tcp_proxies.region must be a GCP region (e.g. us-central1)."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_tcp_proxies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "regional_tcp_proxies.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_tcp_proxies : p.backend_service != ""])
    error_message = "regional_tcp_proxies.backend_service is required: the regional backend service self link (e.g. from gcp/load-balancer regional_backend_service_self_links)."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_tcp_proxies : p.proxy_header == null || contains(["NONE", "PROXY_V1"], p.proxy_header)])
    error_message = "regional_tcp_proxies.proxy_header must be NONE or PROXY_V1 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.regional_tcp_proxies : p.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], p.deletion_policy)])
    error_message = "regional_tcp_proxies.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}

variable "ssl_proxies" {
  description = "Map of global target SSL proxies keyed by an arbitrary identifier (SSL proxies are global-only)."
  type = map(object({
    name             = string
    backend_service  = string
    ssl_certificates = optional(list(string))
    certificate_map  = optional(string)
    ssl_policy       = optional(string)
    description      = optional(string)
    project_id       = optional(string)
    proxy_header     = optional(string)
    deletion_policy  = optional(string)
  }))

  validation {
    condition     = alltrue([for k, p in var.ssl_proxies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "ssl_proxies.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.ssl_proxies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "ssl_proxies.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, p in var.ssl_proxies : (p.ssl_certificates != null && length(p.ssl_certificates) > 0) || p.certificate_map != null])
    error_message = "ssl_proxies must set at least one of ssl_certificates (non-empty list) or certificate_map; the API rejects a target SSL proxy without any certificate."
  }

  validation {
    condition     = alltrue([for k, p in var.ssl_proxies : p.certificate_map == null || can(regex("^//certificatemanager\\.googleapis\\.com/", p.certificate_map))])
    error_message = "ssl_proxies.certificate_map must be a Certificate Manager certificate map URI (//certificatemanager.googleapis.com/...)."
  }

  validation {
    condition     = alltrue([for k, p in var.ssl_proxies : p.proxy_header == null || contains(["NONE", "PROXY_V1"], p.proxy_header)])
    error_message = "ssl_proxies.proxy_header must be NONE or PROXY_V1 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, p in var.ssl_proxies : p.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], p.deletion_policy)])
    error_message = "ssl_proxies.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}

variable "grpc_proxies" {
  description = "Map of global target gRPC proxies keyed by an arbitrary identifier (gRPC proxies are global-only)."
  type = map(object({
    name                   = string
    url_map                = string
    validate_for_proxyless = optional(bool)
    description            = optional(string)
    project_id             = optional(string)
    deletion_policy        = optional(string)
  }))

  validation {
    condition     = alltrue([for k, p in var.grpc_proxies : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", p.name))])
    error_message = "grpc_proxies.name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, p in var.grpc_proxies : p.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "grpc_proxies.project_id must be a valid GCP project ID: 6-30 lowercase letters, digits or dashes, starting with a letter."
  }

  validation {
    condition     = alltrue([for k, p in var.grpc_proxies : p.url_map != null && p.url_map != ""])
    error_message = "grpc_proxies.url_map is required: the URL map self link (e.g. from gcp/load-balancer url_map_self_links); a gRPC proxy without a URL map has no routing target."
  }

  validation {
    condition     = alltrue([for k, p in var.grpc_proxies : p.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], p.deletion_policy)])
    error_message = "grpc_proxies.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}
