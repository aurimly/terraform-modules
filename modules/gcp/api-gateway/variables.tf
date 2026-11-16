variable "apis" {
  description = "Map of API Gateway APIs keyed by an arbitrary identifier. Each entry creates one google_api_gateway_api; api_configs reference these entries by key."
  type = map(object({
    api_id          = string
    project         = optional(string)
    display_name    = optional(string)
    managed_service = optional(string)
    labels          = optional(map(string), {})
    deletion_policy = optional(string, "DELETE")
  }))

  validation {
    condition     = alltrue([for a in var.apis : can(regex("^[a-z][a-z0-9-]{0,39}$", a.api_id))])
    error_message = "api_id must start with a lowercase letter and contain only lowercase letters, digits and hyphens (up to 40 characters); it is a shape check, not the full API rule."
  }

  validation {
    condition = alltrue([
      for a in var.apis : a.project == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", a.project))
    ])
    error_message = "project must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for a in var.apis : contains(["DELETE", "ABANDON", "PREVENT"], a.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }
}

variable "api_configs" {
  description = "Map of API Gateway API configs keyed by an arbitrary identifier. Each entry creates one google_api_gateway_api_config attached to the API named by api. Spec contents are base64 strings (supply with filebase64(...) or base64encode(...)); openapi configs exclude gRPC/managed-service documents. Configs are immutable upstream — a spec change replaces the config (create_before_destroy is set in-module so the gateway repoints)."
  type = map(object({
    api                  = string
    project              = optional(string)
    api_config_id        = optional(string)
    api_config_id_prefix = optional(string)
    display_name         = optional(string)
    labels               = optional(map(string), {})
    deletion_policy      = optional(string, "DELETE")
    openapi_documents = optional(list(object({
      document = object({
        path     = string
        contents = string
      })
    })))
    grpc_services = optional(list(object({
      file_descriptor_set = object({
        path     = string
        contents = string
      })
      source = optional(object({
        path     = string
        contents = string
      }))
    })))
    managed_service_configs = optional(list(object({
      path     = string
      contents = string
    })))
    gateway_config = optional(object({
      backend_config = object({
        google_service_account = string
      })
    }))
  }))

  validation {
    condition = alltrue([
      for c in var.api_configs : contains(keys(var.apis), c.api)
    ])
    error_message = "api must name an entry of var.apis — configs are attached to APIs managed by this module; a dangling key fails at plan with this message instead of an index error."
  }

  validation {
    condition     = alltrue([for c in var.api_configs : c.api_config_id == null || c.api_config_id_prefix == null])
    error_message = "api_config_id and api_config_id_prefix are mutually exclusive — the API assigns either a fixed id or a prefix-generated one."
  }

  validation {
    condition     = alltrue([for c in var.api_configs : c.api_config_id == null || can(regex("^[a-z][a-z0-9-]{0,39}$", c.api_config_id))])
    error_message = "api_config_id must start with a lowercase letter and contain only lowercase letters, digits and hyphens (up to 40 characters); it is a shape check, not the full API rule."
  }

  validation {
    condition = alltrue([
      for c in var.api_configs :
      anytrue([
        c.openapi_documents != null && length(c.openapi_documents) > 0,
        c.grpc_services != null && length(c.grpc_services) > 0,
        c.managed_service_configs != null && length(c.managed_service_configs) > 0,
      ])
    ])
    error_message = "api_configs entries require a spec source — a non-empty one of openapi_documents, grpc_services or managed_service_configs."
  }

  validation {
    condition = alltrue([
      for c in var.api_configs : c.openapi_documents == null || (c.grpc_services == null && c.managed_service_configs == null)
    ])
    error_message = "openapi_documents excludes grpc_services and managed_service_configs — the API rejects the combination."
  }

  validation {
    condition = alltrue([
      for c in var.api_configs : c.grpc_services == null || (c.managed_service_configs != null && length(c.managed_service_configs) > 0)
    ])
    error_message = "grpc_services requires at least one managed_service_configs entry — the API rejects gRPC service definitions without a service configuration."
  }

  validation {
    condition = alltrue(flatten([
      for c in var.api_configs : c.openapi_documents == null ? [true] : [
        for d in c.openapi_documents : can(base64decode(d.document.contents))
      ]
    ]))
    error_message = "openapi_documents.document.contents must be base64-decodable — the API expects base64-encoded file contents."
  }

  validation {
    condition = alltrue(flatten([
      for c in var.api_configs : c.grpc_services == null ? [true] : flatten([
        for g in c.grpc_services : concat(
          [can(base64decode(g.file_descriptor_set.contents))],
          g.source == null ? [] : [can(base64decode(g.source.contents))]
        )
      ])
    ]))
    error_message = "grpc_services file_descriptor_set and source contents must be base64-decodable — the API expects base64-encoded file contents."
  }

  validation {
    condition = alltrue(flatten([
      for c in var.api_configs : c.managed_service_configs == null ? [true] : [
        for m in c.managed_service_configs : can(base64decode(m.contents))
      ]
    ]))
    error_message = "managed_service_configs.contents must be base64-decodable — the API expects base64-encoded file contents."
  }

  validation {
    condition     = alltrue([for c in var.api_configs : contains(["DELETE", "ABANDON", "PREVENT"], c.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }
}

variable "gateways" {
  description = "Map of API Gateway gateways keyed by an arbitrary identifier. Each entry creates one google_api_gateway_gateway serving the config named by api_config_key. Region defaults to the provider's region when omitted."
  type = map(object({
    api_config_key  = string
    gateway_id      = string
    project         = optional(string)
    display_name    = optional(string)
    labels          = optional(map(string), {})
    region          = optional(string)
    deletion_policy = optional(string, "DELETE")
  }))

  validation {
    condition = alltrue([
      for g in var.gateways : contains(keys(var.api_configs), g.api_config_key)
    ])
    error_message = "api_config_key must name an entry of var.api_configs — gateways serve configs managed by this module; a dangling key fails at plan with this message instead of an index error."
  }

  validation {
    condition     = alltrue([for g in var.gateways : can(regex("^[a-z][a-z0-9-]{0,39}$", g.gateway_id))])
    error_message = "gateway_id must start with a lowercase letter and contain only lowercase letters, digits and hyphens (up to 40 characters); it is a shape check, not the full API rule."
  }

  validation {
    condition = alltrue([
      for g in var.gateways : g.project == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", g.project))
    ])
    error_message = "project must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition = alltrue([
      for g in var.gateways : g.region == null || can(regex("^[a-z]+-[a-z]+[0-9]+$", g.region))
    ])
    error_message = "region must look like a GCP region (e.g. us-central1, europe-west4 or europe-west12); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for g in var.gateways : contains(["DELETE", "ABANDON", "PREVENT"], g.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }
}
