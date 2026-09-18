variable "jobs" {
  description = "Map of Dataflow jobs launched from classic templates keyed by an arbitrary identifier. Each entry creates one google_dataflow_job."
  type = map(object({
    name                         = string
    template_gcs_path            = string
    temp_gcs_location            = string
    project_id                   = optional(string)
    parameters                   = optional(map(string), {})
    labels                       = optional(map(string), {})
    transform_name_mapping       = optional(map(string))
    max_workers                  = optional(number)
    on_delete                    = optional(string)
    skip_wait_on_job_termination = optional(bool)
    zone                         = optional(string)
    region                       = optional(string)
    service_account_email        = optional(string)
    network                      = optional(string)
    subnetwork                   = optional(string)
    machine_type                 = optional(string)
    kms_key_name                 = optional(string)
    ip_configuration             = optional(string)
    additional_experiments       = optional(list(string))
    enable_streaming_engine      = optional(bool)
    deletion_policy              = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, j in var.jobs : can(regex("^[a-z]([-a-z0-9]{0,38}[a-z0-9])?$", j.name))])
    error_message = "name must be 1-40 characters, start with a lowercase letter, and contain only lowercase letters, digits and hyphens (no underscores)."
  }

  validation {
    condition     = alltrue([for k, j in var.jobs : can(regex("^gs://", j.template_gcs_path))])
    error_message = "template_gcs_path must be a Cloud Storage URL beginning with gs://."
  }

  validation {
    condition     = alltrue([for k, j in var.jobs : can(regex("^gs://", j.temp_gcs_location))])
    error_message = "temp_gcs_location must be a writeable Cloud Storage URL beginning with gs://."
  }

  validation {
    condition     = alltrue([for k, j in var.jobs : j.on_delete == null || contains(["drain", "cancel"], j.on_delete)])
    error_message = "on_delete must be drain or cancel (lowercase; defaults to drain server-side)."
  }

  validation {
    condition     = alltrue([for k, j in var.jobs : j.ip_configuration == null || contains(["WORKER_IP_PUBLIC", "WORKER_IP_PRIVATE"], j.ip_configuration)])
    error_message = "ip_configuration must be WORKER_IP_PUBLIC or WORKER_IP_PRIVATE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, j in var.jobs : j.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], j.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }
}
