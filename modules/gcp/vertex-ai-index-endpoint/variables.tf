variable "index_endpoints" {
  description = "Map of Vertex AI Vector Search index endpoints keyed by an arbitrary identifier. Each entry creates one google_vertex_ai_index_endpoint."
  type = map(object({
    display_name            = string
    region                  = optional(string)
    project_id              = optional(string)
    description             = optional(string)
    labels                  = optional(map(string), {})
    network                 = optional(string)
    public_endpoint_enabled = optional(bool)
    deletion_policy         = optional(string)
    encryption_spec = optional(object({
      kms_key_name = string
    }))
    private_service_connect_config = optional(object({
      enable_private_service_connect = bool
      project_allowlist              = optional(list(string))
      psc_automation_configs = optional(list(object({
        project_id = string
        network    = string
      })), [])
    }))
  }))

  validation {
    condition     = alltrue([for k, e in var.index_endpoints : e.network == null || e.private_service_connect_config == null])
    error_message = "network and private_service_connect_config are mutually exclusive; set only one."
  }

  validation {
    condition     = alltrue([for k, e in var.index_endpoints : e.encryption_spec == null || can(regex("^projects/[a-z0-9-]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", e.encryption_spec.kms_key_name))])
    error_message = "encryption_spec.kms_key_name must have the form projects/{project}/locations/{region}/keyRings/{key-ring}/cryptoKeys/{key}; the key must be in the same region as the index endpoint."
  }

  validation {
    condition     = alltrue([for k, e in var.index_endpoints : e.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], e.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, e in var.index_endpoints : alltrue(flatten([
        for kk, v in e.labels : [
          length(kk) <= 64,
          length(v) <= 64,
          !can(regex("[A-Z ]", kk)),
          !can(regex("[A-Z ]", v)),
        ]
      ]))
    ])
    error_message = "labels keys and values must be at most 64 characters and contain no uppercase ASCII letters or spaces (international characters are allowed, matching the provider)."
  }
}

variable "deployed_indexes" {
  description = "Map of deployed indexes keyed by an arbitrary identifier. Each entry creates one google_vertex_ai_index_endpoint_deployed_index, deploying an index (typically from the vertex-ai-index module's index_ids output) onto an index endpoint from this module (index_endpoint_ids output)."
  type = map(object({
    deployed_index_id     = string
    index                 = string
    index_endpoint        = string
    region                = optional(string)
    display_name          = optional(string)
    enable_access_logging = optional(bool)
    reserved_ip_ranges    = optional(list(string))
    deployment_group      = optional(string)
    deletion_policy       = optional(string)
    automatic_resources = optional(object({
      min_replica_count = optional(number)
      max_replica_count = optional(number)
    }))
    dedicated_resources = optional(object({
      machine_spec = object({
        machine_type = optional(string)
      })
      min_replica_count = number
      max_replica_count = optional(number)
    }))
    deployed_index_auth_config = optional(object({
      auth_provider = optional(object({
        audiences       = optional(list(string))
        allowed_issuers = optional(list(string))
      }))
    }))
  }))

  validation {
    condition     = alltrue([for k, d in var.deployed_indexes : can(regex("^[A-Za-z][A-Za-z0-9_]{0,127}$", d.deployed_index_id))])
    error_message = "deployed_index_id must be up to 128 characters, start with a letter, and contain only letters, digits and underscores."
  }

  validation {
    condition     = alltrue([for k, d in var.deployed_indexes : (d.automatic_resources != null) != (d.dedicated_resources != null)])
    error_message = "set exactly one of automatic_resources or dedicated_resources."
  }

  validation {
    condition = alltrue([
      for k, d in var.deployed_indexes : d.dedicated_resources == null || (
        d.dedicated_resources.min_replica_count >= 1 &&
        (d.dedicated_resources.max_replica_count == null || d.dedicated_resources.max_replica_count >= d.dedicated_resources.min_replica_count)
      )
    ])
    error_message = "dedicated_resources.min_replica_count must be at least 1, and max_replica_count must be greater than or equal to min_replica_count when set."
  }

  validation {
    condition = alltrue([
      for k, d in var.deployed_indexes : d.automatic_resources == null || d.automatic_resources.min_replica_count == null || d.automatic_resources.max_replica_count == null || d.automatic_resources.max_replica_count >= d.automatic_resources.min_replica_count
    ])
    error_message = "automatic_resources.max_replica_count must be greater than or equal to min_replica_count when both are set."
  }

  validation {
    condition     = alltrue([for k, d in var.deployed_indexes : d.deployment_group == null || length(d.deployment_group) <= 64])
    error_message = "deployment_group must be at most 64 characters when set."
  }

  validation {
    condition     = alltrue([for k, d in var.deployed_indexes : d.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], d.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}
