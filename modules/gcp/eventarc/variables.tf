variable "triggers" {
  description = "Map of standalone Eventarc triggers keyed by an arbitrary identifier. Each entry creates one google_eventarc_trigger. Exactly one destination per trigger."
  type = map(object({
    name                    = string
    location                = string
    project_id              = optional(string)
    service_account         = optional(string)
    pubsub_topic            = optional(string)
    channel                 = optional(string)
    event_data_content_type = optional(string)
    deletion_policy         = optional(string)
    labels                  = optional(map(string), {})
    cloud_run_service = optional(object({
      service = string
      region  = string
      path    = optional(string)
    }))
    gke = optional(object({
      cluster   = string
      location  = string
      namespace = string
      service   = string
      path      = optional(string)
    }))
    workflow = optional(string)
    http_endpoint = optional(object({
      uri = string
    }))
    network_attachment = optional(string)
    matching_criteria = list(object({
      attribute = string
      value     = string
      operator  = optional(string)
    }))
    retry_policy = optional(object({
      max_attempts = number
    }))
  }))

  validation {
    condition     = alltrue([for t in var.triggers : can(regex("^[a-z]([-a-z0-9]{0,62}[a-z0-9])?$", t.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for t in var.triggers : can(regex("^[a-z0-9-]+$", t.location))])
    error_message = "location must look like a GCP region (e.g. us-central1) or a multi region (us, eu); it is a shape check, not a list of valid locations."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", t.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : length(t.matching_criteria) > 0 && anytrue([for m in t.matching_criteria : m.attribute == "type"])
    ])
    error_message = "matching_criteria must contain at least one entry, including an event type filter (attribute = \"type\", e.g. value = \"google.cloud.storage.object.v1.finalized\")."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : length([
        for k in ["cloud_run_service", "gke", "workflow", "http_endpoint"] : k
        if try(t[k], null) != null
      ]) == 1
    ])
    error_message = "each trigger needs exactly one destination: cloud_run_service, gke, workflow or http_endpoint (cloud_run_service requires the pubsub transport or channel)."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : length([
        for k in ["cloud_run_service", "gke", "workflow", "http_endpoint"] : k
        if try(t[k], null) != null
      ]) > 0
    ])
    error_message = "each trigger needs at least one destination; destination.cloud_function is managed by gcp/cloud-functions event triggers and cannot be set."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.retry_policy == null || (t.cloud_run_service != null && t.retry_policy.max_attempts == 1)
    ])
    error_message = "retry_policy requires destination.cloud_run_service and max_attempts = 1 (the only value accepted by the API)."
  }

  validation {
    condition = alltrue([
      for t in var.triggers : t.pubsub_topic == null || anytrue([for m in t.matching_criteria : m.attribute == "type" && m.value == "google.cloud.pubsub.topic.v1.messagePublished"])
    ])
    error_message = "pubsub_topic can only be set on a trigger with a messagePublished event type (matching_criteria with attribute = \"type\" and value = \"google.cloud.pubsub.topic.v1.messagePublished\")."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.deletion_policy == null || contains(["DELETE", "ABANDON"], t.deletion_policy)])
    error_message = "deletion_policy must be DELETE or ABANDON (case-sensitive). Defaults to DELETE when unset."
  }

  validation {
    condition     = alltrue([for t in var.triggers : t.event_data_content_type == null || contains(["application/json", "application/protobuf"], t.event_data_content_type)])
    error_message = "event_data_content_type must be application/json or application/protobuf."
  }
}
