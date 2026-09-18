variable "datasets" {
  description = "Map of Vertex AI datasets keyed by an arbitrary identifier. Each entry creates one google_vertex_ai_dataset. Data ingestion happens outside Terraform (Vertex AI SDK, console, or pipelines)."
  type = map(object({
    display_name        = string
    metadata_schema_uri = string
    region              = optional(string)
    project_id          = optional(string)
    labels              = optional(map(string), {})
    deletion_policy     = optional(string)
    encryption_spec = optional(object({
      kms_key_name = string
    }))
  }))

  validation {
    condition     = alltrue([for k, d in var.datasets : can(regex("^gs://", d.metadata_schema_uri))])
    error_message = "metadata_schema_uri must be a gs:// URI pointing to a dataset metadata schema YAML (schemas are published under gs://google-cloud-aiplatform/schema/dataset/metadata/)."
  }

  validation {
    condition     = alltrue([for k, d in var.datasets : d.encryption_spec == null || can(regex("^projects/[a-z0-9-]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", d.encryption_spec.kms_key_name))])
    error_message = "encryption_spec.kms_key_name must have the form projects/{project}/locations/{region}/keyRings/{key-ring}/cryptoKeys/{key}; the key must be in the same region as the dataset."
  }

  validation {
    condition     = alltrue([for k, d in var.datasets : d.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], d.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, d in var.datasets : alltrue(flatten([
        for kk, v in d.labels : [
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
